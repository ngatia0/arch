#!/usr/bin/env bash

# 0. Clone configuration
git clone https://github.com/ngatia0/temp.git ~/.config

# 1. Setup CachyOS Repos
curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh
cd ..

# 2. Clean and Update
sudo pacman -Rns $(pacman -Qtdq) --noconfirm || echo "No orphans to remove."
sudo pacman -Scc --noconfirm

sudo pacman -S --needed --noconfirm paru
paru -Syy --aur paru

sudo pacman -S --needed --noconfirm base-devel

echo ":: Installing Hyprland core libraries..."
paru -S --needed --noconfirm \
    hyprutils-git \
    hyprwayland-scanner-git \
    hyprwayland-protocols-git \
    aquamarine-git \
    hyprgraphics-git \
    hyprlang-git \
    hyprcursor-git \
    xdg-desktop-portal-hyprland-git \
    hyprqt6engine-git \
    hyprpolkitagent-git \
    hyprland-qt-support-git \
    hyprland-guiutils-git

# 3. The Main Compositor
echo ":: Installing Hyprland compositor..."
paru -S --needed --noconfirm hyprland-git

# 4. Desktop Integration & UI
echo ":: Installing desktop layer..."
paru -S --needed --noconfirm \
    hyprpaper-git \
    hyprlock-git \
    hypridle-git \
    clipvault \
    waybar-git \
    wallust-git \
    dunst-git \
    telegram-desktop \
    foot \
    thunar

# 5. Audio Plugins
git clone https://aur.archlinux.org/lsp-plugins.git
cd lsp-plugins
makepkg -si
cd ..

git clone https://aur.archlinux.org/easyeffects-git.git
cd easyeffects-git
makepkg -si
cd ..

echo "== Installation Complete =="
echo ""
echo "--- Audio Setup Note ---"
echo "To use the Bass and Exciter modules:"
echo "1. Open EasyEffects."
echo "2. Click 'Effects' -> 'Add Effect'."
echo "3. Look for 'LSP Bass Enhancer' and 'LSP Exciter' (or Calf equivalents)."
echo ""
echo "--- Launching Hyprland ---"
echo "Recommended: exec uwsm start hyprland.desktop"
