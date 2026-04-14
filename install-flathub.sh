#!/usr/bin/env bash

set -e -x

sudo pacman -S flatpak --noconfirm
#flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
#flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
