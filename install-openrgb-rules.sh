#!/bin/bash

# Determine the full path of the script and the directory it's located in
SCRIPTLINK=$(readlink -f "$0")
SCRIPTDIR=$(dirname "${SCRIPTLINK}")

# Install ddcutil
yay -Syu miniconda3
echo -e "\n[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh" >> ~/.bashrc
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
#conda create --name mysticlight python=3.9 hid
conda create --name mysticlight python=3.9 -y
conda run -n mysticlight pip install hid

sudo cp ${SCRIPTDIR}/bin/msi-mystic-light-1564.py /usr/local/bin/
sudo chmod +x /usr/local/bin/msi-mystic-light-1564.py

#conda activate mysticlight
#pip install hid

# Copy the udev rules file
sudo cp ./etc/udev/rules.d/60-openrgb.rules /etc/udev/rules.d/

sudo udevadm control --reload-rules
sudo udevadm trigger

sudo udevadm test /devices/pci0000:00/0000:00:08.1/0000:07:00.3/usb1/1-4

conda run -n base /usr/local/bin/msi-mystic-light-1564.py -c FF00FF

# Load the i2c-dev module
#sudo modprobe i2c-dev

# Create the i2c group if it doesn't exist
#sudo groupadd --system i2c || true

# Add the current user to the i2c group
#sudo usermod -aG i2c $USER || true

# Ensure the i2c-dev module is loaded on boot
#MODULE_CONF="/etc/modules-load.d/i2c.conf"
#sudo touch $MODULE_CONF
#if ! grep -q "^i2c-dev$" "$MODULE_CONF"; then
#  echo "i2c-dev" | sudo tee -a "$MODULE_CONF"
#fi

# Reboot the system
#echo "Rebooting the system to apply changes..."
#sudo reboot

#cat /etc/udev/rules.d/60-rename-usb-audio-devices.rules
