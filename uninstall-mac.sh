#!/usr/bin/env bash
# Remove what setup-mac.sh installed, group by group. Safe to preview with --dry-run.
# This removes only packages named in ./groups. It never touches MacPorts itself,
# your dotfiles, or packages you installed on your own.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GROUPS_DIR="$ROOT/groups"
export PATH="/opt/local/bin:/opt/local/sbin:$HOME/.local/bin:$PATH"

DRY=0
SELECTED=()
ALL_GROUPS="base c containers db ios runtimes js ml"

usage() {
  cat <<EOF
Usage: $0 [--dry-run] <group ...>

Groups: $ALL_GROUPS   ('all' for every group). You must name at least one.
  --dry-run   print what would be removed; change nothing
EOF
}

run()   { if [ "$DRY" -eq 1 ]; then printf '[dry-run] %s\n' "$*"; else "$@"; fi; }
items() { grep -vE '^[[:space:]]*(#|$)' "$GROUPS_DIR/$1"; }
step()  { printf '\n==> %s\n' "$*"; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    all)       for g in $ALL_GROUPS; do SELECTED+=("$g"); done ;;
    -*)        echo "Unknown option: $arg" >&2; usage; exit 1 ;;
    *)         SELECTED+=("$arg") ;;
  esac
done
if [ "${#SELECTED[@]}" -eq 0 ]; then usage; exit 1; fi

remove_port_group() {
  step "Removing MacPorts group: $1"
  local pkgs=()
  while IFS= read -r line; do pkgs+=("$line"); done < <(items "$1.port")
  # Only remove packages that are actually installed; leave dependencies for 'port reclaim'.
  for p in "${pkgs[@]}"; do
    if [ "$DRY" -eq 1 ] || port installed "$p" 2>/dev/null | grep -q 'active'; then
      run sudo port uninstall "$p"
    else
      echo "skip $p (not installed)"
    fi
  done
}

remove_mise_group() {
  step "Removing mise group: $1"
  command -v mise >/dev/null 2>&1 || { echo "mise not installed; nothing to do"; return 0; }
  while IFS= read -r spec; do
    local tool="${spec%%@*}"
    run mise unuse -g "$tool" || true
    run mise uninstall --all "$tool" || true
  done < <(items "$1.mise")
}

remove_uv_group() {
  step "Removing uv tools: ml"
  command -v uv >/dev/null 2>&1 || { echo "uv not installed; nothing to do"; return 0; }
  while IFS= read -r tool; do run uv tool uninstall "$tool" || true; done < <(items ml.uv)
}

[ "$DRY" -eq 1 ] && echo "DRY RUN: nothing will be removed."
for g in "${SELECTED[@]}"; do
  case "$g" in
    base|c|containers|db|ios) remove_port_group "$g" ;;
    runtimes)                 remove_mise_group runtimes ;;
    js)                       remove_mise_group js ;;
    ml)                       remove_uv_group ;;
    *) echo "Unknown group: $g" >&2; usage; exit 1 ;;
  esac
done

cat <<'EOF'

Next steps (manual, optional):
  sudo port reclaim            # remove orphaned dependencies
  Remove the MacPorts block from ~/.zprofile and the mise line from ~/.zshrc
  Global npm packages (typescript, tsx, biome) go away with the Node install.
EOF
