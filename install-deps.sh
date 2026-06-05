#!/bin/bash

sudo pacman -Syu yay cabextract unzip zenity libappindicator-gtk3 tcpdump nethogs


# Install open-any-terminal in Nautilus
yay -S nautilus-open-any-terminal
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ptyxis
nautilus -q

