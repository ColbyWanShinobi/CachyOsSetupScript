#!/bin/bash

# Install ddcutil
sudo pacman -Syu ddcutil

# Copy the udev rules file
sudo cp ./etc/udev/rules.d/60-ddcutil-i2c.rules /etc/udev/rules.d/

# Load the i2c-dev module
sudo modprobe i2c-dev

# Create the i2c group if it doesn't exist
sudo groupadd --system i2c || true

# Add the current user to the i2c group
sudo usermod -aG i2c $USER || true

# Ensure the i2c-dev module is loaded on boot
MODULE_CONF="/etc/modules-load.d/i2c.conf"
sudo touch $MODULE_CONF
if ! grep -q "^i2c-dev$" "$MODULE_CONF"; then
  echo "i2c-dev" | sudo tee -a "$MODULE_CONF"
fi

# Reboot the system
#echo "Rebooting the system to apply changes..."
#sudo reboot
