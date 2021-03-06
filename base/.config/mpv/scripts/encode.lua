local start_timestamp = nil
local utils = require "mp.utils"

function append_table(lhs, rhs)
    for i = 1,#rhs do
        lhs[#lhs+1] = rhs[i]
    end
    return lhs
end

function get_unused_filename(prefix, suffix)
    local function file_exists(name)
        local f = io.open(name,"r")
        if f ~= nil then
            io.close(f)
            return true
        else
            return false
        end
    end
    local i = 1
    while true do
        local potential_name = prefix .. "_" .. i .. suffix
        if not file_exists(potential_name) then
            return potential_name
        end
        i = i + 1
    end
end

function get_video_filters_string()
    local filters = {}
    local vf_table = mp.get_property_native("vf")
    for _, vf in ipairs(vf_table) do
        local name = vf["name"]
        local filter
        if name == "crop" then
            local p = vf["params"]
            filter = string.format("crop=%d:%d:%d:%d", p["w"], p["h"], p["x"], p["y"])
        elseif name == "mirror" then
            filter = "hflip"
        elseif name == "flip" then
            filter = "vflip"
        elseif name == "rotate" then
            local rotation = tonumber(vf["params"]["angle"])
            -- rotate is NOT the filter we want here
            if rotation == 90 then
                filter = string.format("transpose=clock")
            elseif rotation == 180 then
                filter = string.format("transpose=clock,transpose=clock")
            elseif rotation == 270 then
                filter = string.format("transpose=cclock")
            end
        end
        filters[#filters + 1] = filter
    end
    return table.concat(filters, ",")
end

function get_active_tracks()
    local tracks = mp.get_property_native("track-list")
    local accepted = {
        video = true,
        audio = not mp.get_property_bool("mute"),
        sub = mp.get_property_bool("sub-visibility")
    }
    local active_tracks = {}
    for _, track in ipairs(tracks) do
        if track["selected"] and accepted[track["type"]] then
            active_tracks[#active_tracks + 1] = string.format("0:%d", track["ff-index"])
        end
    end
    return active_tracks
end

function start_ffmpeg(args)
    local res = utils.subprocess({ args = args, max_size = 0, cancellable = false })
    if res.status == 0 then
        mp.osd_message("Finished encoding succesfully")
    else
        mp.osd_message("Failed to encode")
        print("Check the command:")
        print(table.concat(args, " "))
    end
end

function start_encoding(from, to, settings)
    local input = mp.get_property("path")
    local filename = mp.get_property("filename/no-ext")
    local args = {
        "ffmpeg",
        "-loglevel", "panic", "-hide_banner", --stfu ffmpeg
        "-i", input,
        "-ss", from,
        "-to", to
    }
    
    -- map currently playing channels
    if settings.only_active_tracks == "true" then
        local tracks = get_active_tracks()
        args = append_table(args, { "-map", tracks[i] })
    end

    -- apply some of the video filters currently in the chain
    if settings.preserve_filters == "true" then
        local video_filters = get_video_filters_string()
        if video_filters ~= "" then
            args = append_table(args, {
                "-filter:v", video_filters,
            })
        end
    end

    for token in string.gmatch(settings.codec, "[^%s]+") do
        args[#args + 1] = token
    end

    args[#args + 1] = get_unused_filename(filename, "." .. settings.container)
    mp.add_timeout(0, function() start_ffmpeg(args) end)
end

function set_timestamp(container, only_active_tracks, preserve_filters, codec)
    if start_timestamp == nil then
        mp.osd_message("Start timestamp set")
        start_timestamp = mp.get_property_number("time-pos")
    else
        local current_timestamp = mp.get_property_number("time-pos")
        if current_timestamp <= start_timestamp then
            mp.osd_message("Second timestamp can't be before the first")
            return
        end
        mp.osd_message("End timestamp set, encoding...")
        local settings = {
            container = container,
            only_active_tracks = only_active_tracks,
            preserve_filters = preserve_filters,
            codec = codec
        }
        start_encoding(start_timestamp, current_timestamp, settings)
        start_timestamp = nil
    end
end

mp.add_key_binding(nil, "set_timestamp", set_timestamp)
mp.add_key_binding(nil, "clear_timestamp", function() start_timestamp = nil end)
