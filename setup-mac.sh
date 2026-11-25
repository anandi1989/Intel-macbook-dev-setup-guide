#!/usr/bin/env bash
# IntelMacControl: dev setup for Intel Macs (MacPorts + mise). Safe to re-run.
# Package lists live in ./groups. Edit those, not this file.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GROUPS_DIR="$ROOT/groups"
LOG_DIR="$HOME/.intelmaccontrol"
export PATH="/opt/local/bin:/opt/local/sbin:$HOME/.local/bin:$PATH"

DRY=0
SELECTED=()
DEFAULT_GROUPS="base c runtimes js"
ALL_GROUPS="base c containers db ios runtimes js ml"

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [group ...]

Groups : $ALL_GROUPS
Default: $DEFAULT_GROUPS   (use 'all' for every group)

  --dry-run   print what would happen; change nothing, ask for no password
  -h, --help  show this help
EOF
}

step() { printf '\n==> %s\n' "$*"; }
run()  { if [ "$DRY" -eq 1 ]; then printf '[dry-run] %s\n' "$*"; else "$@"; fi; }

# Print a list file without comments and blank lines.
items() { grep -vE '^[[:space:]]*(#|$)' "$GROUPS_DIR/$1"; }

need() { command -v "$1" >/dev/null 2>&1; }

require_tool() {
  if need "$1"; then return 0; fi
  if [ "$DRY" -eq 1 ]; then echo "[dry-run] note: '$1' not found yet ($2)"; return 0; fi
  echo "Error: '$1' not found. $2" >&2
  exit 1
}

record() {
  [ "$DRY" -eq 1 ] && return 0
  mkdir -p "$LOG_DIR"
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_DIR/installed.log"
}

pre() {
  step "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then echo "present"; else run xcode-select --install; fi

  step "MacPorts PATH in ~/.zprofile"
  if grep -q '/opt/local/bin' "$HOME/.zprofile" 2>/dev/null; then
    echo "already configured"
  elif [ "$DRY" -eq 1 ]; then
    echo "[dry-run] would append MacPorts PATH to ~/.zprofile"
  else
    cat >> "$HOME/.zprofile" <<'EOF'

# MacPorts
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
export MANPATH="/opt/local/share/man:$MANPATH"
EOF
  fi

  require_tool port "Install the .pkg from https://www.macports.org/install.php first."
  step "Updating MacPorts"
  run sudo port selfupdate
}

port_group() {
  step "MacPorts group: $1"
  local pkgs=()
  while IFS= read -r line; do pkgs+=("$line"); done < <(items "$1.port")
  run sudo port install -N "${pkgs[@]}"
  record "port:$1"
}

mise_group() {
  step "mise group: $1"
  require_tool mise "Run the 'base' group first (it installs mise)."
  local tools=()
  while IFS= read -r line; do tools+=("$line"); done < <(items "$1.mise")
  run mise use -g "${tools[@]}"
  record "mise:$1"
}

js_extras() {
  step "Global npm packages"
  local pkgs=()
  while IFS= read -r line; do pkgs+=("$line"); done < <(items js.npm)
  run mise exec -- npm install -g "${pkgs[@]}"
}

ml_group() {
  step "uv tools: ml"
  require_tool uv "Run the 'runtimes' group first (it installs uv)."
  while IFS= read -r tool; do run mise exec -- uv tool install "$tool"; done < <(items ml.uv)
  record "uv:ml"
}

post() {
  if [ "$DRY" -eq 1 ]; then
    step "Shell config (~/.zshrc)"
    echo '[dry-run] would add MacPorts PATH and mise activation to ~/.zshrc (if missing)'
    echo; echo "Dry run complete. Nothing was changed."; return 0
  fi
  step "Shell config (~/.zshrc)"
  if grep -q 'IntelMacControl' "$HOME/.zshrc" 2>/dev/null; then
    echo "already configured"
  else
    # Shims let scripts, IDEs and GUI-launched shells find mise tools (non-interactive).
    if ! grep -q 'mise/shims' "$HOME/.zprofile" 2>/dev/null; then
      cat >> "$HOME/.zprofile" <<'RC'

# mise shims for non-interactive shells (interactive ones use `mise activate`)
case ":$PATH:" in *":$HOME/.local/share/mise/shims:"*) ;; *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;; esac
RC
    fi
    cat >> "$HOME/.zshrc" <<'RC'

# >>> IntelMacControl >>>
case ":$PATH:" in *":/opt/local/bin:"*) ;; *) export PATH="/opt/local/bin:/opt/local/sbin:$PATH" ;; esac
case ":$MANPATH:" in *":/opt/local/share/man:"*) ;; *) export MANPATH="/opt/local/share/man:$MANPATH" ;; esac
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
# <<< IntelMacControl <<<
RC
  fi
  cat <<'EOF'

Done. Open a NEW terminal tab so PATH changes load, then run ./health-check.sh
Xcode (iOS) is manual: install it from the App Store, then
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept
EOF
}

run_group() {
  case "$1" in
    base|c|containers|db|ios) port_group "$1" ;;
    runtimes)                 mise_group runtimes ;;
    js)                       mise_group js; js_extras ;;
    ml)                       ml_group ;;
    *) echo "Unknown group: $1" >&2; usage; exit 1 ;;
  esac
}

# --- argument parsing ---
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY=1 ;;
    -h|--help)  usage; exit 0 ;;
    all)        for g in $ALL_GROUPS; do SELECTED+=("$g"); done ;;
    -*)         echo "Unknown option: $arg" >&2; usage; exit 1 ;;
    *)          SELECTED+=("$arg") ;;
  esac
done
if [ "${#SELECTED[@]}" -eq 0 ]; then
  for g in $DEFAULT_GROUPS; do SELECTED+=("$g"); done
fi

[ "$DRY" -eq 1 ] && echo "DRY RUN: nothing will be installed or modified."

# Groups that need MacPorts first run the shared prelude once.
for g in "${SELECTED[@]}"; do
  case "$g" in base|c|containers|db|ios) pre; break ;; esac
done

for g in "${SELECTED[@]}"; do run_group "$g"; done
post
