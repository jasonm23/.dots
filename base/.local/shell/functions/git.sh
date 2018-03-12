# Custom git commands
__mk5_git() {
  local prog="$1"
  shift
  local cmd="$1"
  shift

  case "$cmd" in
    cd)
      cd "$(git rev-parse --show-toplevel)" "$@"
      ;;
    open)
      git-open "$@"
      ;;
    *)
      command "$prog" "$cmd" "$@"
      ;;
  esac
}
git() {
  __mk5_git git "$@"
}
hub() {
  __mk5_git hub "$@"
}

# Publish to github-pages
ghp-publish() {
  local cur_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  git checkout master && \
    git pull && \
    git checkout gh-pages && \
    git pull && \
    git merge master --no-edit && \
    git push && \
    git checkout $cur_branch
}

# Get rid of .orig files from merge conflicts
git-clean-orig() {
    git status -su | grep -e"\.orig$" | cut -f2 -d" " | xargs rm -r
}

# Update the .gitignore with all currently untracked files
git-update-gitignore() {
  touch .gitignore
  git status --porcelain | grep '^??' | cut -c4- >> .gitignore
}
