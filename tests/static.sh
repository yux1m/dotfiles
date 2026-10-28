#!/usr/bin/env bash
set -euo pipefail
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME
source_dir=$(cd "$(dirname "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/target/.config"
cm=(chezmoi --source "$source_dir" --destination "$test_root/target"
    --config "$test_root/config.toml" --cache "$test_root/cache"
    --persistent-state "$test_root/state.boltdb")
for input in "$source_dir"/.chezmoiscripts/*.tmpl; do
  output="$test_root/$(basename "${input%.tmpl}")"
  "${cm[@]}" execute-template < "$input" > "$output"
  bash -n "$output"
  shellcheck "$output"
done
shellcheck "$source_dir/install.sh" "$source_dir/dot_local/bin/executable_dotfiles" "$source_dir"/tests/*.sh
for file in .zshrc .zprofile .config/zsh/plugins.zsh .config/zsh/common.zsh .config/zsh/options.zsh .config/zsh/macos.zsh .config/zsh/linux.zsh; do
  "${cm[@]}" cat "$test_root/target/$file" > "$test_root/rendered.zsh"
  zsh -n "$test_root/rendered.zsh"
done
printf 'old-zshrc\n' > "$test_root/target/.zshrc"
printf 'old-prompt\n' > "$test_root/target/.config/starship.toml"
printf 'local-only\n' > "$test_root/target/.zshrc.local"
printf 'unmanaged\n' > "$test_root/target/.bashrc"
DOTFILES_SKIP_INSTALL=1 "${cm[@]}" apply --force
"${cm[@]}" verify --exclude=scripts
backups=("$test_root/target/.local/state/dotfiles/backups/"20*)
grep -qx 'old-zshrc' "${backups[0]}/.zshrc"
grep -qx 'old-prompt' "${backups[0]}/.config/starship.toml"
grep -qx 'local-only' "$test_root/target/.zshrc.local"
grep -qx 'unmanaged' "$test_root/target/.bashrc"
DOTFILES_SKIP_INSTALL=1 "${cm[@]}" apply --force
snapshots=("$test_root/target/.local/state/dotfiles/backups/"20*)
before=${#snapshots[@]}
DOTFILES_SKIP_INSTALL=1 "${cm[@]}" apply --force
snapshots=("$test_root/target/.local/state/dotfiles/backups/"20*)
after=${#snapshots[@]}
[[ "$before" == "$after" ]]
"${cm[@]}" verify --exclude=scripts
# Exercise both OS branches, all Bash login entry points and repeat application.
for os in darwin linux; do
  for login in .profile .bash_login .bash_profile; do
    dest="$test_root/$os-${login#.}"
    mkdir -p "$dest"
    printf '# original bashrc\n' > "$dest/.bashrc"
    printf '# original login\n' > "$dest/$login"
    cross=(chezmoi --source "$source_dir" --destination "$dest"
           --config "$test_root/config.toml" --cache "$test_root/cache"
           --persistent-state "$test_root/state.boltdb"
           --override-data "{\"chezmoi\":{\"os\":\"$os\"}}")
    DOTFILES_SKIP_INSTALL=1 "${cross[@]}" apply --force
    cp "$dest/.bashrc" "$test_root/bashrc.once"
    cp "$dest/$login" "$test_root/login.once"
    DOTFILES_SKIP_INSTALL=1 "${cross[@]}" apply --force
    "${cross[@]}" verify --exclude=scripts
    cmp "$dest/.bashrc" "$test_root/bashrc.once"
    cmp "$dest/$login" "$test_root/login.once"
    grep -qx '# original bashrc' "$dest/.bashrc"
    grep -qx '# original login' "$dest/$login"
    if [[ "$os" == linux ]]; then
      [[ $(grep -c '^# >>> dotfiles Bash integration >>>$' "$dest/.bashrc") == 1 ]]
      [[ $(grep -c '^# >>> dotfiles Bash integration >>>$' "$dest/$login") == 1 ]]
    else
      [[ $(wc -l < "$dest/.bashrc" | tr -d ' ') == 1 ]]
      [[ $(wc -l < "$dest/$login" | tr -d ' ') == 1 ]]
    fi
    bash -n "$dest/.bashrc" "$dest/$login"
  done
done
for file in "$source_dir"/dot_config/bash/*.bash; do bash -n "$file"; shellcheck -s bash "$file"; done
for input in "$source_dir"/modify_*.tmpl; do
  "${cm[@]}" execute-template < "$input" > "$test_root/modifier.sh"
  bash -n "$test_root/modifier.sh"
  shellcheck "$test_root/modifier.sh"
  if printf '# >>> dotfiles Bash integration >>>\nunterminated\n' | bash "$test_root/modifier.sh" >/dev/null; then
    echo 'FAIL: accepted a damaged managed block.' >&2; exit 1
  fi
done
echo 'PASS: both OSes, all login entries, preserved local files, idempotence, syntax and backups.'
