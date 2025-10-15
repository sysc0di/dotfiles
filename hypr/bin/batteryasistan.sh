#!/usr/bin/env bash
# battery_status.sh
# Çıktı örneği: "⚡  86%" veya " 12% (Discharging)"
# Öncelikli olarak /sys/class/power_supply kullanır, yoksa upower'a döner.

set -euo pipefail

# Kullanıcı tercihi: renkli çıktı istersen true yap
USE_COLOR=false

# ANSI renkler (kullanmak istersen USE_COLOR=true)
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Icon map (Font Awesome style icons as birincil, emoji fallback açıklamada)
icon_for_level() {
  local pct=$1
  if (( pct >= 95 )); then
    echo ""    # full vertical
  elif (( pct >= 75 )); then
    echo ""    # 3/4
  elif (( pct >= 50 )); then
    echo ""    # half
  elif (( pct >= 25 )); then
    echo ""    # 1/4
  else
    echo ""    # empty
  fi
}

# Try /sys/class/power_supply first
get_from_sys() {
  # Find battery directories named BAT* or with type "Battery"
  local bat_dirs=()
  while IFS= read -r -d $'\0' d; do bat_dirs+=("$d"); done < <(find /sys/class/power_supply -maxdepth 1 -type d -name "BAT*" -print0 2>/dev/null || true)

  if [[ ${#bat_dirs[@]} -eq 0 ]]; then
    # fallback: check for type file == "Battery"
    while IFS= read -r -d $'\0' d; do
      if [[ -f "$d/type" && "$(cat "$d/type")" == "Battery" ]]; then
        bat_dirs+=("$d")
      fi
    done < <(find /sys/class/power_supply -maxdepth 1 -type d -print0 2>/dev/null || true)
  fi

  if [[ ${#bat_dirs[@]} -eq 0 ]]; then
    return 1
  fi

  # If birden fazla batarya varsa ortalama al (veya ilkini kullan)
  local total=0
  local count=0
  local status_any_charging=0
  for d in "${bat_dirs[@]}"; do
    if [[ -f "$d/capacity" ]]; then
      pct=$(tr -d ' \n' < "$d/capacity")
    else
      # bazı kernel sürümlerinde enerji_full vs energy_now hesaplanabilir, fallback:
      if [[ -f "$d/energy_now" && -f "$d/energy_full" ]]; then
        now=$(cat "$d/energy_now")
        full=$(cat "$d/energy_full")
        if (( full > 0 )); then
          pct=$(( now * 100 / full ))
        else
          pct=0
        fi
      else
        continue
      fi
    fi

    # status (Charging/Discharging/Full)
    status="Unknown"
    if [[ -f "$d/status" ]]; then
      status=$(tr -d ' \n' < "$d/status")
    fi
    if [[ "$status" == "Charging" || "$status" == "Full" ]]; then
      status_any_charging=1
    fi

    total=$(( total + pct ))
    count=$(( count + 1 ))
  done

  if (( count == 0 )); then
    return 1
  fi

  pct_avg=$(( total / count ))
  if (( status_any_charging == 1 )); then
    status="Charging"
  else
    status=${status:-"Discharging"}
  fi

  echo "$pct_avg" "$status"
  return 0
}

# Fallback: upower (if yüklü)
get_from_upower() {
  if ! command -v upower >/dev/null 2>&1; then
    return 1
  fi

  # first battery device
  dev=$(upower -e | grep -E "battery|BAT" | head -n1 || true)
  if [[ -z "$dev" ]]; then
    return 1
  fi

  info=$(upower -i "$dev")
  pct=$(echo "$info" | awk '/percentage/ {gsub("%","",$2); print int($2); exit}')
  state=$(echo "$info" | awk '/state/ {print $2; exit}')
  [[ -z "$pct" ]] && return 1
  echo "$pct" "$state"
  return 0
}

main() {
  local pct status
  if out=$(get_from_sys 2>/dev/null) ; then
    read -r pct status <<<"$out"
  elif out=$(get_from_upower 2>/dev/null) ; then
    read -r pct status <<<"$out"
  else
    echo "No battery info"
    exit 1
  fi

  icon=$(icon_for_level "$pct")

  # charging marker
  charging_marker=""
  if [[ "$status" =~ [Cc]harging ]]; then
    charging_marker="⚡"
  elif [[ "$status" =~ [Ff]ull ]]; then
    charging_marker="🔌"
  fi

  # renk (isteğe bağlı)
  if [[ "$USE_COLOR" == "true" ]]; then
    if (( pct <= 10 )); then
      printf "${RED}%s %s%%%s\n" "$icon" "$pct" "$RESET"
    elif (( pct <= 30 )); then
      printf "${YELLOW}%s %s%%%s\n" "$icon" "$pct" "$RESET"
    else
      printf "${GREEN}%s %s%%%s\n" "$icon" "$pct" "$RESET"
    fi
  else
    # Örnek çıktı: "⚡  54% (Charging)"
    if [[ -n "$charging_marker" ]]; then
      printf "%s %s %s%% (%s)\n" "$charging_marker" "$icon" "$pct" "$status"
    else
      printf "%s %s%% (%s)\n" "$icon" "$pct" "$status"
    fi
  fi
}

main
