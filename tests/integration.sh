#!/usr/bin/env bash
set -euo pipefail
[[ $(id -un) == dotfiles-test ]] || { echo 'Run only as the disposable dotfiles-test account.' >&2; exit 1; }
# Hosted runners may keep their owner's XDG paths across sudo -i.
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME
export PATH="$HOME/.local/bin:$PATH"
test_source=$(cd "$(dirname "$0")/.." && pwd)
source_dir="$HOME/.local/share/chezmoi"
mkdir -p "$HOME/.local/share" "$HOME/.config"
git clone --quiet "$test_source" "$source_dir"
printf 'preexisting-zshrc\n' > "$HOME/.zshrc"
printf 'preexisting-prompt\n' > "$HOME/.config/starship.toml"
printf '# local-only sentinel\n' > "$HOME/.zshrc.local"
bash "$source_dir/install.sh" --source "$source_dir"
chezmoi verify --exclude=scripts
[[ $(getent passwd "$(id -un)" | cut -d: -f7) == "$(command -v zsh)" ]]
for tool in starship fzf zoxide; do "$tool" --version; done
cat > "$HOME/assert-shell.zsh" <<'ZSH'
  [[ "$ZSH_THEME" == "" ]] || exit 1
  (( ${plugins[(Ie)zsh-autosuggestions]} )) || exit 1
  [[ "${plugins[-1]}" == zsh-syntax-highlighting ]] || exit 1
  (( ! ${plugins[(Ie)macos]} && ! ${plugins[(Ie)brew]} )) || exit 1
  (( $+functions[z] && $+functions[zi] && $+functions[_zsh_autosuggest_start] )) || exit 1
  (( $+widgets[fzf-history-widget] )) || exit 1
  starship prompt >/dev/null
  dotfiles doctor
ZSH
TERM=xterm-256color script -q -e -c 'zsh -lic "source ~/assert-shell.zsh"' /dev/null > "$HOME/first-shell.log" 2>&1
cat "$HOME/first-shell.log"
if grep -Ei 'not found|parse error|permission denied|error.*config' "$HOME/first-shell.log"; then
  echo 'FAIL: shell startup emitted an error.' >&2; exit 1
fi
fc-match 'JetBrainsMono Nerd Font Mono' | grep -q 'JetBrainsMonoNerdFontMono'
snapshots=("$HOME/.local/state/dotfiles/backups/"20*)
grep -qx 'preexisting-zshrc' "${snapshots[0]}/.zshrc"
grep -qx 'preexisting-prompt' "${snapshots[0]}/.config/starship.toml"
grep -q 'local-only sentinel' "$HOME/.zshrc.local"
bash "$source_dir/install.sh" --source "$source_dir"
chezmoi verify --exclude=scripts

# Direct target edits must stop pull, and explicit capture must preserve them.
printf '\nalias integration_marker=true\n' >> "$HOME/.config/zsh/common.zsh"
if dotfiles pull > "$HOME/expected-refusal.log" 2>&1; then
  echo 'FAIL: pull accepted uncaptured target changes.' >&2; exit 1
fi
grep -q 'Source and installed files differ' "$HOME/expected-refusal.log"
dotfiles capture common
grep -q integration_marker "$source_dir/dot_config/zsh/common.zsh"
chezmoi verify --exclude=scripts
git -C "$source_dir" checkout -- dot_config/zsh/common.zsh
chezmoi apply --force

# A bad download checksum must not replace the existing binary or config.
cp "$HOME/.local/bin/fzf" "$HOME/fzf.saved"
cp "$source_dir/.chezmoidata.toml" "$HOME/manifest.saved"
cp "$HOME/.zshrc" "$HOME/zshrc.saved"
printf '#!/bin/sh\necho 0.0.0\n' > "$HOME/.local/bin/fzf"
chmod +x "$HOME/.local/bin/fzf"
python3 - "$source_dir/.chezmoidata.toml" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
s = p.read_text()
for digest in ('d47d7f882972c7d674dbbba998ffa4116e68379616ffac7695d0671e9a722c5f',
               'cf058001da21724a469b714a29cf4aab9cbe860d218a0d6c1b5b661efad7784c'):
    s = s.replace(digest, '0' * 64)
p.write_text(s)
PY
if chezmoi apply --force > "$HOME/expected-checksum-error.log" 2>&1; then
  echo 'FAIL: accepted an invalid checksum.' >&2; exit 1
fi
grep -q 'Checksum mismatch' "$HOME/expected-checksum-error.log"
[[ $(fzf --version) == 0.0.0 ]]
cmp "$HOME/.zshrc" "$HOME/zshrc.saved"
cp "$HOME/manifest.saved" "$source_dir/.chezmoidata.toml"
chezmoi apply --force
fzf --version | grep -q '^0.74.5'
chezmoi verify --exclude=scripts
echo 'PASS: fresh install, actual Zsh session, font, shell, repeat install, capture, checksum failure and repair.'

# Publish in both directions through a local bare remote (no account credentials).
remote="$HOME/sync-test.git"
git clone --quiet --bare "$source_dir" "$remote"
git -C "$source_dir" remote set-url origin "$remote"
git -C "$source_dir" config user.name 'Dotfiles Test'
git -C "$source_dir" config user.email 'test@example.invalid'
second_source="$HOME/second-source"
second_target="$HOME/second-target"
git clone --quiet "$remote" "$second_source"
git -C "$second_source" config user.name 'Second Machine'
git -C "$second_source" config user.email 'test@example.invalid'
mkdir -p "$second_target"
other_cm=(chezmoi --source "$second_source" --destination "$second_target"
          --config "$HOME/second-config.toml" --cache "$HOME/second-cache"
          --persistent-state "$HOME/second-state.boltdb")
DOTFILES_SKIP_INSTALL=1 "${other_cm[@]}" apply --force
printf '\n# roundtrip-from-first\n' >> "$HOME/.config/zsh/common.zsh"
dotfiles capture common
dotfiles push
DOTFILES_SKIP_INSTALL=1 "${other_cm[@]}" update
grep -q roundtrip-from-first "$second_target/.config/zsh/common.zsh"
printf '\n# roundtrip-from-second\n' >> "$second_source/dot_config/zsh/linux.zsh"
DOTFILES_SKIP_INSTALL=1 "${other_cm[@]}" apply
"${other_cm[@]}" push
dotfiles pull
grep -q roundtrip-from-second "$HOME/.config/zsh/linux.zsh"
chezmoi verify --exclude=scripts
echo 'PASS: two-way publishing and updating through Git.'
