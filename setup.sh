#!/usr/bin/env bash
# Bootstrap this host: install Nix (if missing), enable flakes, apply the
# home-manager configuration. Idempotent. Use --dry-run to preview.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

log()  { printf '\033[34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m %s\n' "$*"
    return 0
  fi
  "$@"
}

source_nix() {
  local f
  for f in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
           "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    # shellcheck disable=SC1090
    [[ -r "$f" ]] && { . "$f"; return 0; }
  done
  return 1
}

install_nix() {
  log "Nix"
  source_nix || true
  if command -v nix >/dev/null 2>&1; then
    ok "nix present: $(nix --version)"
    return
  fi
  if [[ "$(uname -s)" != "Linux" ]]; then
    warn "this repo targets Linux hosts; use mac-setup on macOS"
    exit 1
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m install nix (multi-user, needs sudo)\n'
    return
  fi
  curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes
  source_nix || { warn "nix installed but profile script not found; open a new shell and re-run"; exit 1; }
  ok "nix installed"
}

enable_flakes() {
  log "Nix flakes"
  local conf="$HOME/.config/nix/nix.conf"
  if grep -qs 'experimental-features.*flakes' "$conf" /etc/nix/nix.conf 2>/dev/null; then
    ok "flakes already enabled"
    return
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[33mdry-run:\033[0m write experimental-features to %s\n' "$conf"
    return
  fi
  mkdir -p "$(dirname "$conf")"
  echo 'experimental-features = nix-command flakes' >> "$conf"
  ok "flakes enabled in $conf"
}

switch_home() {
  log "home-manager switch"
  # -b: keep any pre-existing dotfile as <name>.bak instead of failing
  run_cmd nix run github:nix-community/home-manager -- \
    switch --flake "$REPO#coder" -b bak
}

post_notes() {
  cat <<'NOTES'

Done. Open a new shell (bash hands off to zsh) or run: exec zsh
  - zellij is installed but does NOT auto-start; set setup.zellijAutostart = true to change that
  - NO_AUTO_ZSH=1 bash   keeps a single shell in bash
  - hms                  re-applies this repo after edits
NOTES
}

main() {
  install_nix
  enable_flakes
  switch_home
  [[ "$DRY_RUN" -eq 1 ]] || post_notes
}

main
