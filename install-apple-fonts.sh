#!/usr/bin/env bash

set -e

# Apple Fonts
# https://invent.kde.org/plasma/plasma-desktop/-/issues/5

################
APP_NAME=apple-fonts
EMOJI_URL='https://github.com/samuelngs/apple-emoji-linux/releases/download/v17.4/AppleColorEmoji.ttf'
################
# Space delimited list of required command-line utilities to run this script
prereq_list=(curl fc-cache git)

# Check to see if the prereq utilities are installed
for util in "${prereq_list[@]}";do
  if [ ! -x "$(command -v ${util})" ];then
    echo "Missing utility! Please install [${util}] and try again..."
    exit 1
  fi
done

SETUP_PATH=${HOME}/Downloads/${APP_NAME}

# Create setup directory if not present
if [ ! -d "${SETUP_PATH}" ]; then
  echo "Creating Directory: ${SETUP_PATH}"
  mkdir -p ${SETUP_PATH}
fi

# Check to see if the AppleColorEmoji.ttf is already installed
if [ -f "$HOME/.local/share/fonts/truetype/apple-emoji-linux/AppleColorEmoji.ttf" ];then
  echo "AppleColorEmoji.ttf is already present. Skipping install."
else
  # Download the file
  echo "Downloading file ${EMOJI_URL} to ${SETUP_PATH}/AppleColorEmoji.ttf"
  curl --location --silent --fail --show-error --output ${SETUP_PATH}/AppleColorEmoji.ttf ${EMOJI_URL}
  # Install the package
  echo "Installing ${SETUP_PATH}/AppleColorEmoji.ttf"
  mkdir -p $HOME/.local/share/fonts/truetype/apple-emoji-linux/
  cp ${SETUP_PATH}/AppleColorEmoji.ttf $HOME/.local/share/fonts/truetype/apple-emoji-linux/
  fc-cache -f -v
fi

# SF Fonts
if [ -d "${SETUP_PATH}/sfwin" ]; then
  echo "SF Fonts are already present. Skipping install."
else
  git clone https://github.com/aishalih/sfwin.git ${SETUP_PATH}/sfwin
  mkdir -p $HOME/.local/share/fonts/opentype/sfwin/
  find ${SETUP_PATH}/sfwin -name \*.otf -exec sudo cp -v {} $HOME/.local/share/fonts/opentype/sfwin/ \;
  fc-cache -f -v
fi

gsettings set org.gnome.desktop.interface font-name "SF Pro Display 11"
gsettings set org.gnome.desktop.interface monospace-font-name "SF Mono 13"
gsettings set org.gnome.desktop.interface  document-font-name "SF Pro Display 11"
gsettings set org.gnome.desktop.wm.preferences titlebar-font "SF Pro Display, Bold 11"

#To reset back to default
#gsettings reset org.gnome.desktop.interface font-name
#gsettings reset org.gnome.desktop.interface monospace-font-name
#gsettings reset org.gnome.desktop.interface document-font-name
#gsettings reset org.gnome.desktop.wm.preferences titlebar-font
