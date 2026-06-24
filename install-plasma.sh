#! /bin/bash

sudo pacman -Syu plasma-meta kde-applications-meta cachyos-kde-settings sddm
sudo systemctl disable gdm.service
sudo systemctl enable sddm.service
