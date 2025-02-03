#! /bin//bash

sudo pacman -Syu openssh
sudo systemctl status sshd
sudo systemctl enable sshd
sudo systemctl start sshd
sudo systemctl status sshd
sudo ufw allow ssh
