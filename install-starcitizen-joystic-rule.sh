#!/bin/bash

# Copy the udev rules file if it doesn't already exist
echo "Copying the udev rules file..."
#sudo mkdir -p /etc/udev/rules.d
#if [ ! -f /etc/udev/rules.d/40-starcitizen-joystick-uaccess.rules ]; then
    sudo cp ./etc/udev/rules.d/40-starcitizen-joystick-uaccess.rules /etc/udev/rules.d/
#else
    #echo "The udev rules file already exists."
    #echo "Do you want to overwrite it? (y/n)"
    #read overwrite
    #if [ "$overwrite" == "y" ]; then
    #    sudo cp ./etc/udev/rules.d/40-starcitizen-joystick-uaccess.rules /etc/udev/rules.d/
#fi

# Reload the udev rules
echo "Reloading the udev rules..."
sudo udevadm control --reload-rules
