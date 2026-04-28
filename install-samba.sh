#! /bin/bash


sudo pacman -S gvfs gvfs-smb gvfs-wsdd wsdd avahi nss-mdns samba smbclient

sudo systemctl enable --now avahi-daemon
sudo systemctl enable --now wsdd

sudo ufw allow 3702/udp
sudo ufw allow 5357/tcp
sudo ufw allow 5358/tcp

nautilus -q
