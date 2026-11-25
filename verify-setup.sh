#!/usr/bin/env bash
# Final checks after setup-mac.sh: are ~/.zprofile and ~/.zshrc sane, and do your tools
# resolve in every kind of zsh shell? Read-only. Exit code 0 = pass, 1 = failures found.
# Usage: ./verify-setup.sh [tool ...]    (default tools below)
set -uo pipefail

TOOLS=("$@")
[ "${#TOOLS[@]}" -eq 0 ] && TOOLS=(port mise node tsc uv go bun deno)

if [ -t 1 ]; then G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; B=$'\033[1m'; N=$'\033[0m'; else G=; Y=; R=; B=; N=; fi
FAILS=0; WARNS=0
ok()   { printf '  %s[PASS]%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s[WARN]%s %s\n' "$Y" "$N" "$*"; WARNS=$((WARNS + 1)); }
fail() { printf '  %s[FAIL]%s %s\n' "$R" "$N" "$*"; FAILS=$((FAILS + 1)); }
head_() { printf '\n%s%s%s\n' "$B" "$*" "$N"; }

if ! command -v zsh >/dev/null 2>&1; then echo "zsh not found; this check targets zsh (the macOS default)."; exit 1; fi

head_ "1. Config files"
for f in "$HOME/.zprofile" "$HOME/.zshrc"; do
  if [ ! -f "$f" ]; then
    [ "$f" = "$HOME/.zprofile" ] && fail "$f is missing" || warn "$f is missing"
    continue
  fi
  if zsh -n "$f" 2>/dev/null; then ok "$(basename "$f") parses cleanly"; else fail "$(basename "$f") has a syntax error (run: zsh -n $f)"; fi
done
grep -q '/opt/local/bin' "$HOME/.zprofile" 2>/dev/null && ok "MacPorts PATH in ~/.zprofile" || fail "MacPorts PATH missing from ~/.zprofile"
grep -q 'mise/shims' "$HOME/.zprofile" 2>/dev/null && ok "mise shims in ~/.zprofile (non-interactive shells)" || warn "mise shims not in ~/.zprofile; scripts and IDEs may not see mise tools"
grep -q 'IntelMacControl' "$HOME/.zshrc" 2>/dev/null && ok "IntelMacControl block in ~/.zshrc" || fail "IntelMacControl block missing from ~/.zshrc (run ./setup-mac.sh)"
grep -q 'mise activate' "$HOME/.zshrc" 2>/dev/null && ok "mise activate in ~/.zshrc" || fail "mise activate missing from ~/.zshrc"
n=$(grep -c '>>> IntelMacControl >>>' "$HOME/.zshrc" 2>/dev/null || true)
[ "${n:-0}" -gt 1 ] && warn "IntelMacControl block appears $n times in ~/.zshrc (safe, but you can remove extras)"

head_ "2. Tools in each kind of shell"
echo "  login+interactive = new Terminal tab; interactive = VS Code terminal; login = scripts, IDE tasks"
for spec in "login+interactive:-lic" "interactive:-ic" "login:-lc"; do
  name=${spec%%:*}; flag=${spec##*:}
  missing=""
  for t in "${TOOLS[@]}"; do
    zsh "$flag" "command -v $t" >/dev/null 2>&1 || missing="$missing $t"
  done
  if [ -z "$missing" ]; then ok "$name: all ${#TOOLS[@]} tools found"; else fail "$name: missing:$missing"; fi
done

head_ "3. PATH hygiene"
for spec in "login+interactive:-lic" "interactive:-ic" "login:-lc"; do
  name=${spec%%:*}; flag=${spec##*:}
  dupes=$(zsh "$flag" 'print -l ${(s.:.)PATH} | sort | uniq -d' 2>/dev/null | tr '\n' ' ')
  if [ -z "$dupes" ]; then ok "$name: no duplicate PATH entries"; else warn "$name: duplicate PATH entries: $dupes"; fi
done
# Only user-managed locations: macOS lists some system paths that are normally absent.
bad=$(zsh -lic 'print -l ${(s.:.)PATH}' 2>/dev/null | while read -r d; do
  case "$d" in ("$HOME"/*|/opt/*) [ -d "$d" ] || echo "$d" ;; esac
done | tr '\n' ' ')
[ -z "$bad" ] && ok "every PATH entry under \$HOME and /opt exists" || warn "PATH entries that don't exist (harmless, but can be cleaned up): $bad"

head_ "4. mise"
if zsh -lic 'command -v mise' >/dev/null 2>&1; then
  if zsh -lic 'mise doctor' >/dev/null 2>&1; then ok "mise doctor reports no problems"; else warn "mise doctor reported issues (run: mise doctor)"; fi
  [ -d "$HOME/.local/share/mise/shims" ] && ok "shims directory exists ($(ls "$HOME/.local/share/mise/shims" | wc -l | tr -d ' ') shims)" || warn "no mise shims directory"
else
  fail "mise not found"
fi

head_ "Result"
if [ "$FAILS" -eq 0 ]; then
  printf '  %sAll required checks passed%s (%d warning%s).\n' "$G" "$N" "$WARNS" "$([ "$WARNS" -eq 1 ] || echo s)"
  exit 0
fi
printf '  %s%d check(s) failed%s, %d warning(s). Open a NEW terminal tab and re-run; if it persists, run ./setup-mac.sh.\n' "$R" "$FAILS" "$N" "$WARNS"
exit 1
