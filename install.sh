#!/usr/bin/env bash
set -euo pipefail
repo_url='https://github.com/yux1m/dotfiles.git'
local_source=''
skip_shell=0
while (( $# )); do
  case "$1" in
    --source) [[ $# -ge 2 ]] || exit 2; local_source=$2; shift 2 ;;
    --skip-shell) skip_shell=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done
[[ $(id -u) -ne 0 ]] || { echo 'Run this command as your normal user, without sudo before bash.' >&2; exit 1; }
export PATH="$HOME/.local/bin:$PATH"
case "$(uname -s)" in
  Linux)
    # shellcheck disable=SC1091
    . /etc/os-release
    case "$ID" in ubuntu|debian) ;; *) echo 'Supported Linux distributions: Ubuntu and Debian.' >&2; exit 1 ;; esac
    if ! command -v git >/dev/null || ! command -v curl >/dev/null; then
      sudo apt-get update
      sudo apt-get install -y git curl ca-certificates
    fi
    ;;
  Darwin)
    if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)";
    elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
    ;;
  *) echo 'Supported systems: macOS, Ubuntu, Debian.' >&2; exit 1 ;;
esac
if ! command -v chezmoi >/dev/null; then
  installer=$(mktemp)
  trap 'rm -f "$installer"' EXIT
  curl --fail --location --silent --show-error --retry 3 https://get.chezmoi.io -o "$installer"
  sh "$installer" -b "$HOME/.local/bin" -t v2.73.3
fi

if [[ -n "$local_source" ]]; then
  # CI/development: apply the exact checkout being tested, without a remote pull.
  [[ -f "$local_source/.chezmoidata.toml" ]] || { echo 'Invalid local source.' >&2; exit 1; }
  cm=(chezmoi --source "$local_source")
else
  source_dir=$(chezmoi source-path)
  if [[ -d "$source_dir/.git" ]]; then
    origin=$(git -C "$source_dir" remote get-url origin)
    [[ "${origin%.git}" == "${repo_url%.git}" || "$origin" == 'git@github.com:yux1m/dotfiles.git' ]] || {
      echo "A different chezmoi repository already exists at $source_dir" >&2; exit 1;
    }
    [[ -z $(git -C "$source_dir" status --porcelain) ]] || {
      echo 'Save and publish your local source changes before running the installer again.' >&2; exit 1;
    }
    git -C "$source_dir" pull --ff-only
  else
    chezmoi init "$repo_url"
  fi
  cm=(chezmoi)
fi
# The first before-script backs up existing files before any replacement.
"${cm[@]}" apply --force
"${cm[@]}" verify --exclude=scripts

if [[ $(uname -s) == Linux && "$skip_shell" == 0 ]]; then
  zsh_path=$(command -v zsh)
  current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
  if [[ "$current_shell" != "$zsh_path" ]]; then
    sudo chsh -s "$zsh_path" "$(id -un)"
  fi
fi
cat <<'EOF'

Terminal setup completed.
Start now: exec zsh -l
Log out and back in to use the new default shell everywhere.
In the Ubuntu terminal preferences, select: JetBrainsMono Nerd Font Mono
Update later: dotfiles pull
Help: dotfiles help
EOF
