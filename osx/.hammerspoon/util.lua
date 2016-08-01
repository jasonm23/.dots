local consts = require('consts')

-- Tables+
function T(t)
  return setmetatable(t or {}, { __index = table })
end
setmetatable(table, {
  __index = {
    -- Shallow copy
    copy = function(...)
      return (function(self)
        local copied = T{}
        for k, v in ipairs(self) do
          copied[k] = v
        end
        return copied
      end):curry(...)
    end,

    -- Apply a function over each element
    -- function signature is (value, key) since values are more useful
    map = function(...)
      return (function(self, func)
        local mapped = self:copy()
        for k, v in ipairs(self) do
          mapped[k] = func(v, k)
        end
        return mapped
      end):curry(...)
    end,

    -- Return the x in self s.t. func(x) is truthy
    -- function signature is (value, key) since values are more useful
    filter = function(...)
      return (function(self, func)
        local filtered = T{}
        for k, v in ipairs(self) do
          if func(v, k) then
            filtered[#filtered + 1] = v
          end
        end
        return filtered
      end):curry(...)
    end,

    -- Combine tables
    merge = function(...)
      return (function(self, arr, ...)
        local merged = self:copy()
        for _, t in ipairs({arr, ...}) do
          for k, v in pairs(t) do
            merged[k] = v
          end
        end
        return merged
      end):curry(...)
    end,

    -- Concatenate arrays
    extend = function(...)
      return (function(self, arr, ...)
        local extended = self:copy()
        for _, t in ipairs({arr, ...}) do
          for _, v in ipairs(t) do
            extended[#extended + 1] = v
          end
        end
        return extended
      end):curry(...)
    end,
  },
})

-- Functions+
debug.setmetatable(function() end, {
    -- Arity (http://stackoverflow.com/a/20177245)
    __len = function(self)
        return debug.getinfo(self, 'u').nparams
    end,

    __index = {
      -- Single-time partial application
      later = function(self, ...)
        local args = T{...}
        return function()
          return self(args:unpack())
        end
      end,

      -- Arity-based partial application
      curry = function(self, ...)
        local args = T{...}

        -- If arity reached, call
        if #args >= #self then
          return self(...)
        end

        -- Else, defer to next call
        return function(...)
          return self:curry(args:extend({...}):unpack())
        end
      end,

      -- Call with packed arguments
      withPacked = function(...)
        return (function(self, args)
          return self(T(args):unpack())
        end):curry(...)
      end,

      -- Call over each element in each array in ..., position-wise
      map = function(...)
        return (function(self, arr, ...)
          local args = T{arr, ...}

          -- Get # of items to map
          local nargs = math.max(args:map(function(list)
            return #list
          end):unpack())

          local mapped = T{}
          for i = 1, nargs do
            -- Call on with ith arg of each arg list
            mapped[i] = self(args:map(function(list)
              return list[i]
            end):unpack(1, #args))
          end
          return mapped
        end):curry(...)
      end,

      -- Return the x in arr s.t. self(x) is truthy
      filter = function(...)
        return (function(self, arr)
          return table.filter(arr, self)
        end):curry(...)
      end,
    },
})

-- Scala-style switch(case) {...}
local switch = (function(case, caseTable)
  return caseTable[case] or caseTable[consts.DEFAULT]
end):curry()

return {
  T = T,
  switch = switch,
}
