#!/usr/bin/env bash

# Harici monitör ayarı
hyprctl keyword monitor "HDMI-A-1,1920x1080@165,1920x0,1"

# Mevcut Waybar'ı güvenli şekilde kapat
if pgrep -x "waybar" >/dev/null; then
    killall waybar
    while pgrep -x "waybar" >/dev/null; do
        sleep 0.1
    done
fi

# Dış monitör için özel konfig ile başlat
waybar -c ~/.config/waybar/extenalconf.jsonc >/dev/null 2>&1 &
waybar 2>&1 &

# Bildirim gönder
notify-send "External monitor connected" "Waybar external config loaded"
