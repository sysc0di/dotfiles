#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/hypr/gamemode.txt"
NORMAL_WALLPAPER="/home/yucel/wallps/1367165.jpeg"
GAME_WALLPAPER="/home/yucel/wallps/codghostfire.jpg"

mkdir -p "$(dirname "$CONFIG_FILE")"

# Create default config if missing
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "gamemode=off" > "$CONFIG_FILE"
fi

source "$CONFIG_FILE"

# Start swww daemon if not running
if ! pgrep -x swww-daemon >/dev/null; then
    swww init
    sleep 0.3
fi

if [[ "$gamemode" == "on" ]]; then
    gamemode="off"

    # Stop NVIDIA power service
    systemctl stop nvidia-powerd

    notify-send -a "Game Mode" "🛑 Disabling Game Mode..."

    # Close gaming apps
    pkill -f heroic


    # Change wallpaper
    swww img "$NORMAL_WALLPAPER" --transition-type random --transition-duration 1

    # Restart Waybar
    sleep 1
    nohup waybar >/dev/null 2>&1 & disown

    notify-send -a "Game Mode" "✅ Game Mode Disabled"
else
    gamemode="on"
    
    # Start NVIDIA power service
    systemctl start nvidia-powerd

    notify-send -a "Game Mode" "🚀 Enabling Game Mode..."

    # Close Waybar
    pkill -x waybar


    # Change wallpaper
    swww img "$GAME_WALLPAPER" --transition-type random --transition-duration 1

    # Launch Heroic
    sleep 1
    nohup heroic >/dev/null 2>&1 & disown

    notify-send -a "Game Mode" "🎮 Game Mode Enabled"
fi

# Save new state
echo "gamemode=$gamemode" > "$CONFIG_FILE"
