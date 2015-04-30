__mk5_normal="\[\e[0m\]"

# Line colors
__mk5_red="\[\e[0;31m\]"
__mk5_green="\[\e[0;32m\]"
__mk5_yellow="\[\e[0;33m\]"
__mk5_blue="\[\e[0;34m\]"
__mk5_purple="\[\e[0;35m\]"
__mk5_cyan="\[\e[0;36m\]"
__mk5_white="\[\e[0;37m\]"
__mk5_b_red="\[\e[1;31m\]"
__mk5_b_green="\[\e[1;32m\]"
__mk5_b_yellow="\[\e[1;33m\]"
__mk5_b_blue="\[\e[1;34m\]"
__mk5_b_purple="\[\e[1;35m\]"
__mk5_b_cyan="\[\e[1;36m\]"
__mk5_b_white="\[\e[1;37m\]"

# Special characters
__mk5_usr_pchar='$'
__mk5_root_pchar='#'
__mk5_sepchar='+'
__mk5_dirty_char='*'
__mk5_incoming_char='v'
__mk5_outgoing_char='^'

__mk5_hostname=$(hostname|cut -d . -f 1)

function __mk5_git_pwd {
  # Get git path
  local gitpath="$(git rev-parse --show-toplevel 2>/dev/null)"

  if [[ "$gitpath" ]]; then
    # Strip git path
    echo "$(basename $gitpath)${PWD##$gitpath}"
  else
    # Replace home with ~
    echo "$PWD" | sed "s|^$HOME|~|"
  fi
}

function __mk5_git_branch {
  echo $(git symbolic-ref HEAD 2>/dev/null || \
         git rev-parse --short HEAD 2>/dev/null) \
       | sed "s|^refs/heads/||"
}

function __mk5_git_dirty {
  echo "$(git status -s --ignore-submodules=dirty 2>/dev/null | wc -l)"
}

function __mk5_git_outgoing {
  echo "$(git log origin/$(__mk5_git_branch).. 2>/dev/null \
    | grep '^commit' | wc -l)"
}

function __mk5_git_incoming {
  echo "$(git log ..origin/$(__mk5_git_branch) 2>/dev/null \
    | grep '^commit' | wc -l)"
}

function __mk5_set_prompt {
  # Grab status code first
  local last_status=$?

  # Status color
  local pcharcolor
  if [[ $last_status == 0 ]]; then
    pcharcolor="$__mk5_b_green"
  else
    pcharcolor="$__mk5_b_red"
  fi

  # Use $ or # for prompt
  local pchar
  if [[ $EUID -eq 0 ]]; then
    pchar="$__mk5_root_pchar"
  else
    pchar="$__mk5_usr_pchar"
  fi

  # Git stuff
  local git_info
  if [[ "$(__mk5_git_branch)" ]]; then
    git_info=$(__mk5_git_branch)

    if [[ "$(__mk5_git_dirty)" != 0 ]]; then
      git_info="$git_info \
$__mk5_b_yellow$__mk5_dirty_char$(__mk5_git_dirty)"
    fi

    if [[ "$(__mk5_git_incoming)" != 0 ]]; then
      git_info="$git_info \
$__mk5_b_red$__mk5_incoming_char$(__mk5_git_incoming)"
    fi

    if [[ "$(__mk5_git_outgoing)" != 0 ]]; then
      git_info="$git_info \
$__mk5_b_blue$__mk5_outgoing_char$(__mk5_git_outgoing)"
    fi

    git_info="$__mk5_purple$git_info \
$__mk5_b_purple$__mk5_sepchar "
  fi

  # Virtualenv stuff
  local colorpwd="$__mk5_green$(__mk5_git_pwd) "
  local virtualenv_info
  if [[ "$VIRTUAL_ENV" ]]; then
    local gitpath="$(git rev-parse --show-toplevel 2>/dev/null)"
    local envpath="$(cat $VIRTUAL_ENV/.project 2>/dev/null)"

    # If we're in a git repo and the directory matches the current env
    # project path, make it blue
    if [[ "$envpath" && "$gitpath" == "$envpath" ]]; then
      colorpwd="$__mk5_blue$(basename $gitpath)$__mk5_green${PWD##$gitpath} "

    # Otherwise, just print out the virtualenv info separately
    else
      virtualenv_info="$__mk5_blue$(basename $VIRTUAL_ENV) \
$__mk5_b_blue$__mk5_sepchar "
    fi
  fi

  PS1="\
$__mk5_cyan$USER@$__mk5_hostname $__mk5_b_cyan$__mk5_sepchar \
$virtualenv_info\
$git_info\
$colorpwd\
\n\
$pcharcolor$pchar \
$__mk5_normal"
}

PROMPT_COMMAND=__mk5_set_prompt
