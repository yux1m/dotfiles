# Preserve the existing Miniforge integration when it is installed locally.
if [[ -x "$HOME/miniforge3/bin/conda" ]]; then
  __conda_setup="$("$HOME/miniforge3/bin/conda" shell.zsh hook 2>/dev/null)"
  if [[ $? -eq 0 ]]; then
    eval "$__conda_setup"
  elif [[ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/miniforge3/etc/profile.d/conda.sh"
  else
    path=("$HOME/miniforge3/bin" $path)
  fi
  unset __conda_setup
fi

[[ -f "$HOME/.iterm2_shell_integration.zsh" ]] && source "$HOME/.iterm2_shell_integration.zsh"
true
