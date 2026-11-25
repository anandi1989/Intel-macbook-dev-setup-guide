#!/usr/bin/env bash
# One-screen health report for an Intel Mac. Read-only, needs no sudo, sends nothing anywhere.
# Output contains no serial numbers, so it is safe to paste into a GitHub issue.
set -uo pipefail

export PATH="/opt/local/bin:/opt/local/sbin:$HOME/.local/bin:$PATH"

if [ -t 1 ]; then G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; B=$'\033[1m'; N=$'\033[0m'; else G=; Y=; R=; B=; N=; fi
ok()   { printf '  %s[ OK ]%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s[WARN]%s %s\n' "$Y" "$N" "$*"; }
bad()  { printf '  %s[ BAD]%s %s\n' "$R" "$N" "$*"; }
info() { printf '  [ .. ] %s\n' "$*"; }
head_() { printf '\n%s%s%s\n' "$B" "$*" "$N"; }

if [ "$(uname -m)" != "x86_64" ]; then
  echo "Note: this Mac reports $(uname -m), not Intel. Some checks may not apply."
fi

head_ "System"
info "Model   : $(sysctl -n hw.model)"
info "CPU     : $(sysctl -n machdep.cpu.brand_string) ($(sysctl -n hw.physicalcpu) cores / $(sysctl -n hw.logicalcpu) threads)"
info "RAM     : $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
info "macOS   : $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
boot=$(sysctl -n kern.boottime | sed -E 's/^\{ sec = ([0-9]+),.*/\1/')
days=$(( ( $(date +%s) - boot ) / 86400 ))
if [ "$days" -ge 14 ]; then warn "Uptime  : $days days. A reboot clears leaked memory and stuck helpers."
else ok "Uptime  : $days days"; fi

head_ "Battery"
batt=$(ioreg -rn AppleSmartBattery 2>/dev/null)
if [ -z "$batt" ]; then
  info "No battery found (desktop Mac)"
else
  get() { printf '%s\n' "$batt" | grep -m1 "\"$1\" =" | sed -E 's/.*= ([0-9]+).*/\1/'; }
  design=$(get DesignCapacity); maxcap=$(get MaxCapacity); cycles=$(get CycleCount); temp=$(get Temperature)
  if [ -n "${design:-}" ] && [ -n "${maxcap:-}" ] && [ "$design" -gt 0 ]; then
    pct=$(( maxcap * 100 / design ))
    if   [ "$pct" -ge 85 ]; then ok   "Health  : $pct% of design capacity ($maxcap / $design mAh)"
    elif [ "$pct" -ge 75 ]; then warn "Health  : $pct% of design capacity ($maxcap / $design mAh), consider a replacement soon"
    else                         bad  "Health  : $pct% of design capacity ($maxcap / $design mAh), replace the battery"; fi
  fi
  [ -n "${cycles:-}" ] && { if [ "$cycles" -ge 1000 ]; then warn "Cycles  : $cycles (rated life is about 1000)"; else ok "Cycles  : $cycles"; fi; }
  [ -n "${temp:-}" ]   && info "Temp    : $(( temp / 100 )) C"
fi

head_ "Thermals"
therm=$(pmset -g therm 2>/dev/null)
limit=$(printf '%s\n' "$therm" | grep -m1 CPU_Speed_Limit | sed -E 's/.*= *([0-9]+).*/\1/')
if [ -z "${limit:-}" ]; then info "No CPU speed limit reported"
elif [ "$limit" -lt 100 ]; then bad "CPU speed limited to $limit% (thermal throttling right now; heavy build or hot room?)"
else ok "No throttling (CPU speed limit 100%)"; fi
info "For temperatures and fan data run: sudo powermetrics --samplers smc -i 2000 -n 1"

head_ "Memory"
free_pct=$(memory_pressure 2>/dev/null | grep -i 'free percentage' | sed -E 's/.*: *([0-9]+)%.*/\1/')
if [ -n "${free_pct:-}" ]; then
  if   [ "$free_pct" -ge 30 ]; then ok   "Free memory : $free_pct%"
  elif [ "$free_pct" -ge 15 ]; then warn "Free memory : $free_pct%, getting tight"
  else                              bad  "Free memory : $free_pct%, under memory pressure"; fi
fi
swap=$(sysctl -n vm.swapusage 2>/dev/null | sed -E 's/.*used = ([0-9.]+)M.*/\1/')
if [ -n "${swap:-}" ]; then
  if awk "BEGIN{exit !($swap > 2048)}"; then warn "Swap used   : ${swap} MB, heavy swapping slows everything"
  else ok "Swap used   : ${swap} MB"; fi
fi

head_ "Disk"
read -r total_kb avail_kb <<<"$(df -k / | awk 'NR==2{print $2, $4}')"
avail_gb=$(( avail_kb / 1048576 )); total_gb=$(( total_kb / 1048576 ))
if   [ "$avail_gb" -ge 30 ]; then ok   "Free space : ${avail_gb} GB of ${total_gb} GB"
elif [ "$avail_gb" -ge 15 ]; then warn "Free space : ${avail_gb} GB of ${total_gb} GB, keep 20-30 GB free"
else                              bad  "Free space : ${avail_gb} GB of ${total_gb} GB, low"; fi
caches=$(du -sk "$HOME/Library/Caches" 2>/dev/null | awk '{printf "%d", $1/1024}')
[ -n "${caches:-}" ] && info "User caches: ${caches} MB"

head_ "Busiest processes (CPU)"
ps -Ao pcpu,pmem,comm -r | sed -n '2,6p' | while read -r cpu mem cmd; do
  name=$(basename "$cmd")
  info "$(printf '%5s%% CPU %5s%% MEM  %s' "$cpu" "$mem" "$name")"
done
head_ "Biggest processes (memory)"
ps -Ao rss,comm -m | sed -n '2,6p' | while read -r rss cmd; do
  info "$(printf '%6d MB  %s' $(( rss / 1024 )) "$(basename "$cmd")")"
done
mtl=$(pgrep -x MTLCompilerService 2>/dev/null | wc -l | tr -d ' ')
[ "${mtl:-0}" -ge 3 ] && warn "$mtl MTLCompilerService processes running (shader compilers can hold GBs). Fix: sudo pkill MTLCompilerService"

head_ "Toolchain"
chk() { if command -v "$1" >/dev/null 2>&1; then ok "$1 ($("$1" "${2:---version}" 2>&1 | head -1 | cut -c1-50))"; else warn "$1 not found${3:+ ($3)}"; fi; }
xcode-select -p >/dev/null 2>&1 && ok "Command Line Tools" || bad "Command Line Tools missing: xcode-select --install"
chk port version "install MacPorts"
chk mise --version "run ./setup-mac.sh base"
chk node --version
chk python3 --version
chk uv --version
chk go version
chk rustc --version
if grep -q '/opt/local/bin' "$HOME/.zprofile" 2>/dev/null; then ok "MacPorts PATH configured in ~/.zprofile"; else warn "MacPorts PATH not in ~/.zprofile"; fi

echo
