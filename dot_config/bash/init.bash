# Native Bash integrations. This file is sourced by interactive Bash only.
case $- in *i*) ;; *) return ;; esac
[[ ${_DOTFILES_BASH_INIT_LOADED:-} != 1 ]] || return
_DOTFILES_BASH_INIT_LOADED=1

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
export EDITOR="${EDITOR:-nano}"
# shellcheck disable=SC1091
source "$HOME/.config/bash/common.bash"
if [[ -f "$HOME/.bashrc.local" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.bashrc.local"
fi
if command -v fzf >/dev/null; then eval "$(fzf --bash)"; fi
if command -v zoxide >/dev/null; then eval "$(zoxide init bash)"; fi
if command -v starship >/dev/null; then eval "$(starship init bash)"; fi
