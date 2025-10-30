#!/usr/bin/env bash

# Ekranlar uyandıktan sonra ayarları yeniden yükle
sleep 2

# DPMS yeniden aktif et
hyprctl dispatch dpms on

# Hyprland ekran konfigürasyonunu yeniden uygula
if [ -f "$HOME/.config/hypr/display_config.txt" ]; then
    while read -r line; do
        [ -z "$line" ] && continue
        hyprctl keyword monitor "$line"
    done < "$HOME/.config/hypr/display_config.txt"
fi