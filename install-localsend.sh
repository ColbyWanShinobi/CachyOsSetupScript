#!/usr/bin/env bash

set -e

echo "Installing LocalSend..."

# Check if flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo "Flatpak is not installed. Installing flatpak..."
    sudo pacman -Syu --noconfirm flatpak
fi

# Add flathub repository if not already added
if ! flatpak remotes | grep -q flathub; then
    echo "Adding Flathub repository..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install LocalSend if not already installed
if ! flatpak list | grep -q org.localsend.localsend_app; then
    echo "Installing LocalSend from Flathub..."
    sudo flatpak install -y flathub org.localsend.localsend_app
else
    echo "LocalSend is already installed."
fi

# Open firewall ports for LocalSend (port 53317 TCP and UDP)
echo "Configuring firewall for LocalSend..."
sudo ufw allow 53317/tcp comment 'LocalSend'
sudo ufw allow 53317/udp comment 'LocalSend'

echo "LocalSend installation complete!"
echo "You can launch LocalSend with: flatpak run org.localsend.localsend_app"
