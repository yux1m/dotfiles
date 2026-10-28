#!/usr/bin/env bash
set -euo pipefail
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
echo 'PASS: render/syntax, safe backups, preserved unmanaged files, repeat apply.'
