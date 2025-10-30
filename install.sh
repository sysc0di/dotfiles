#!/usr/bin/env bash

# Check if Paru is installed
if ! command -v paru >/dev/null 2>&1; then
    echo "→ Paru is not installed, installing..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru || exit 1
    makepkg -si --noconfirm
    cd - >/dev/null || exit 1
else
    echo "→ Paru is already installed."
fi

sleep 1

# Packages to install
PACKAGES=(
    cava fastfetch cpufetch fish hyprland hypridle hyprlock hyprsunset swww
    kitty rofi nwg-drawer nwg-look swaync waybar wlogout starship
    network-manager-applet blueman ttf-iosevka-nerd indicator-sound-switcher
)

echo "→ Installing packages..."
paru -S --needed --noconfirm "${PACKAGES[@]}"

sleep 2

# Copy configuration files
echo "→ Copying configuration files..."
cp -r config/* "$HOME/.config/"
cp -r wallps "$HOME/"


echo "✅ Installation complete!"
