#!/usr/bin/env bash
hyprctl keyword monitor "HDMI-A-1,1920x1080@165,1920x0,1" 
killall waybar 
sleep 0.5
 waybar &
 waybar -c .config/waybar/extenalconf.jsonc 
 notify-send "External monitor connected"