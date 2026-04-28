#!/usr/bin/env bash

set -e

echo "Installing LocalSend..."

ufw_rules_changed=0

allow_ufw_rule() {
    local rule="$1"
    local comment="$2"

    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -Fq "$rule"; then
            echo "ufw rule for $rule already exists."
        else
            sudo ufw allow "$rule" comment "$comment"
            ufw_rules_changed=1
        fi
    else
        echo "ufw is not installed; skipping firewall rule for $rule."
    fi
}

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

# Open firewall ports for LocalSend discovery and transfer
echo "Configuring firewall for LocalSend..."
allow_ufw_rule 53317/tcp LocalSend
allow_ufw_rule 53317/udp LocalSend

if command -v ufw &> /dev/null && [[ "$ufw_rules_changed" -eq 1 ]]; then
    sudo ufw reload
fi

echo "LocalSend installation complete!"
echo "You can launch LocalSend with: flatpak run org.localsend.localsend_app"
echo "If devices still do not appear, verify both clients are on the same LAN, not using guest isolation, and can exchange UDP/TCP traffic on port 53317."
