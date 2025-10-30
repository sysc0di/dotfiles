#!/usr/bin/env bash

# Harici monitor bağlı mı kontrol et
EXTERNAL_MON=$(hyprctl monitors -j | jq -r '.[] | select(.name | test("^(HDMI|DP|USB-C)")).name')

if [[ -n "$EXTERNAL_MON" ]]; then
    echo "Harici monitör ($EXTERNAL_MON) bağlı, işlem yapılmayacak."
    exit 0
fi

hyprctl keyword monitor "eDP-2,enable"
hyprctl keyword monitor "eDP-1,enable"

