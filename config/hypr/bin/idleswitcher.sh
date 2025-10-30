#!/usr/bin/env bash

# Hypridle auto-sleep toggle via Rofi
# Codi (c) 2025 💻

# Paths
ENABLED_CONF="$HOME/.config/hypr/hypridle.conf"
DISABLED_CONF="$HOME/.config/hypr/hypridle_no_sleep.conf"

# Detect current hypridle status
if pgrep -x "hypridle" >/dev/null; then
    PID=$(pgrep -x hypridle | head -n1)
    CMD=$(ps -o args= -p "$PID")

    if echo "$CMD" | grep -q "hypridle.conf"; then
        STATUS="🟢 Auto Sleep ENABLED"
        CURRENT="enabled"
    elif echo "$CMD" | grep -q "hypridle_no_sleep.conf"; then
        STATUS="🔴 Auto Sleep DISABLED"
        CURRENT="disabled"
    else
        STATUS="⚪ Running (Unknown Config)"
        CURRENT="unknown"
    fi
else
    STATUS="⚫ Not Running"
    CURRENT="none"
fi

# Determine menu options based on current mode
if [[ "$CURRENT" == "enabled" ]]; then
    MENU="🔴 Disable Auto Sleep"
elif [[ "$CURRENT" == "disabled" ]]; then
    MENU="🟢 Enable Auto Sleep"
else
    MENU="🟢 Enable Auto Sleep\n🔴 Disable Auto Sleep"
fi

# Show rofi menu
choice=$(printf "%b" "$MENU" | rofi -dmenu -p "Hypridle: $STATUS")

# Process choice
case "$choice" in
    "🟢 Enable Auto Sleep")
        killall hypridle >/dev/null 2>&1
        sleep 0.3
        nohup hypridle -c "$ENABLED_CONF" >/dev/null 2>&1 &
        notify-send "Hypridle" "Auto sleep ENABLED 💤"
        ;;
    "🔴 Disable Auto Sleep")
        killall hypridle >/dev/null 2>&1
        sleep 0.3
        nohup hypridle -c "$DISABLED_CONF" >/dev/null 2>&1 &
        notify-send "Hypridle" "Auto sleep DISABLED 🚫"
        ;;
    *)
        # ESC or no choice → do nothing
        exit 0
        ;;
esac
