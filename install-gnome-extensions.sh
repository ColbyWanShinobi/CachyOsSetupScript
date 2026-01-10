#!/usr/bin/env bash

set -e
################
APP_NAME=gnome-extensions
PACKAGE_TYPE=zip
################
# Space delimited list of required command-line utilities to run this script
prereq_list=(curl jq)

# Check to see if the prereq utilities are installed
for util in "${prereq_list[@]}";do
  if [ ! -x "$(command -v ${util})" ];then
    echo "Missing utility! Please install [${util}] and try again..."
    exit 1
  fi
done

SETUP_PATH=${HOME}/Downloads/${APP_NAME}

# Create setup directory
#echo "Creating Setup Directory: ${SETUP_PATH}"
#mkdir -p ${SETUP_PATH}

if [[ ${XDG_CURRENT_DESKTOP} != "ubuntu:GNOME" && ${XDG_CURRENT_DESKTOP} != "Unity" && ${XDG_CURRENT_DESKTOP} != "GNOME" ]];then
  echo "This script is only for GNOME Desktop Environment. Exiting..."
  exit 1
fi

extlist=(
"https://extensions.gnome.org/extension/6868/screenshort-cut/"
"https://extensions.gnome.org/extension/1386/notification-counter/"
"https://extensions.gnome.org/extension/1460/vitals/"
"https://extensions.gnome.org/extension/1484/do-not-disturb-time/"
"https://extensions.gnome.org/extension/1674/topiconsfix/"
"https://extensions.gnome.org/extension/19/user-themes/"
"https://extensions.gnome.org/extension/258/notifications-alert-on-user-menu/"
"https://extensions.gnome.org/extension/2929/battery-time-percentage-compact/"
"https://extensions.gnome.org/extension/307/dash-to-dock"
"https://extensions.gnome.org/extension/3795/notification-timeout/"
"https://extensions.gnome.org/extension/4099/no-overview/"
"https://extensions.gnome.org/extension/4105/notification-banner-position/"
"https://extensions.gnome.org/extension/4228/wireless-hid/"
"https://extensions.gnome.org/extension/4548/tactile/"
"https://extensions.gnome.org/extension/615/appindicator-support/"
"https://extensions.gnome.org/extension/6242/emoji-copy/"
"https://extensions.gnome.org/extension/6278/battery-usage-wattmeter/"
"https://extensions.gnome.org/extension/6325/control-monitor-brightness-and-volume-with-ddcutil/"
#"https://extensions.gnome.org/extension/6655/openweather/"
#"https://extensions.gnome.org/extension/2/move-clock/"
"https://extensions.gnome.org/extension/744/hide-activities-button/"
"https://extensions.gnome.org/extension/988/harddisk-led/"
"https://extensions.gnome.org/extension/6000/quick-settings-audio-devices-renamer/"
"https://extensions.gnome.org/extension/6898/dual-monitor-toggle/"
"https://extensions.gnome.org/extension/1262/bing-wallpaper-changer/"
"https://extensions.gnome.org/extension/6679/power-profile-indicator/"
"https://extensions.gnome.org/extension/6583/auto-power-profile/"
"https://extensions.gnome.org/extension/5362/wireguard-vpn-extension/"
"https://extensions.gnome.org/extension/5964/quick-settings-audio-devices-hider/"
"https://extensions.gnome.org/extension/1183/utcclock/"
"https://extensions.gnome.org/extension/3733/tiling-assistant/"
#"https://extensions.gnome.org/extension/7603/advanced-weather-companion/"
#"https://extensions.gnome.org/extension/7215/restart-to/"
"https://extensions.gnome.org/extension/3928/auto-select-headset/"
"https://extensions.gnome.org/extension/8261/simpleweather/"
)

CURRENT_GNOME_VERSION=$(gnome-shell --version | grep -oP '\d+\.\d+' | head -1 | cut -f1 -d.)

# Function to install and enable a GNOME Shell extension
install_and_enable_extension() {
  local uuid="$1"

  # Check if the extension is already installed
  if gnome-extensions list | grep -q "$uuid"; then
      echo "Extension [$uuid] is already installed."
      echo
  else
      # Install the extension
      echo "Installing extension [$uuid]..."
      busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s "$uuid"
      echo "Extension [$uuid] installed."
      echo
  fi

  # Enable the extension
  gnome-extensions enable "$uuid"
}

for i in "${extlist[@]}"
do
  echo URL: $i
  PACKAGE_DATA=$(curl --silent --location $i | grep -oP 'data-svm="\K[^"]+' | sed 's/&quot;/"/g' | jq '. | tojson | fromjson')
  #echo $PACKAGE_DATA
  UUID=$(curl --silent --location --fail --show-error $i | grep -oP 'data-uuid="\K[^"]+')
  #echo "UUID: $UUID"
  URL_ENCODED_UUID=$(jq -nr --arg str "$UUID" '$str|@uri')
  #echo "URL Encoded UUID: $URL_ENCODED_UUID"
  EPK=$(curl --silent --location --fail --show-error $i | grep -oP 'data-epk="\K[^"]+')
  #echo "EPK: $EPK"

  # Check if CURRENT_GNOME_VERSION exists
  SHELL_VERSION_EXISTS=$(echo $PACKAGE_DATA | jq --arg version "$CURRENT_GNOME_VERSION" '. | has($version)')
  #echo $SHELL_VERSION_EXISTS
  if [ "$SHELL_VERSION_EXISTS" = "true" ]; then
    echo "Extension [$UUID] supports GNOME Shell version $CURRENT_GNOME_VERSION."
    EXT_PK=$(echo $PACKAGE_DATA | jq --arg version "$CURRENT_GNOME_VERSION" '.[$version].pk')
    EXT_VER=$(echo $PACKAGE_DATA | jq --arg version "$CURRENT_GNOME_VERSION" '.[$version].version')
    #echo "Version: $EXT_VER, PK: $EXT_PK"
    #EXT_URL="https://extensions.gnome.org/download-extension/${URL_ENCODED_UUID}.shell-extension.${PACKAGE_TYPE}?version_tag=$EXT_PK"
    #PACKAGE_PATH=${SETUP_PATH}/${UUID}.${PACKAGE_TYPE}

    #echo "Downloading $UUID... $EXT_URL"
    #curl --location --silent --fail --show-error --output ${PACKAGE_PATH} ${EXT_URL}

    #echo "Installing $UUID..."
    #gnome-extensions install --force ${PACKAGE_PATH}
    #if ! gnome-extensions list | grep --quiet ${UUID}; then
    #  busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s ${UUID}
    #  gnome-extensions enable ${UUID}
    #else
    #  echo "Extension $UUID is already installed."
    #fi
    install_and_enable_extension $UUID
  else
    echo "!!!Extension $UUID does not support GNOME Shell version $CURRENT_GNOME_VERSION. Skipping..."
    echo
  fi





  #EXTENSION_ID=$(curl -s $i | grep -oP 'data-uuid="\K[^"]+')
  #EXTENSION_DATA=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=$EXTENSION_ID" | jq '.extensions[0]')
  #UUID=$(echo $EXTENSION_DATA | jq -r '.uuid')

  #echo $UUID
  #echo $EXTENSION_DATA | jq '.shell_version_map | length'
  #echo .
  #echo $EXTENSION_DATA | jq '. | tojson | fromjson' # Pretty print the JSON

  # Check if CURRENT_GNOME_VERSION exists in shell_version_map
  #SHELL_VERSION_EXISTS=$(echo $EXTENSION_DATA | jq --arg version "$CURRENT_GNOME_VERSION" '.shell_version_map | has($version)')

  #if [ "$SHELL_VERSION_EXISTS" = "true" ]; then
  #  echo "Extension $UUID supports GNOME Shell version $CURRENT_GNOME_VERSION."
  #  EXT_PK=$(echo $EXTENSION_DATA | jq --arg version "$CURRENT_GNOME_VERSION" '.shell_version_map[$version].pk')
  #  EXT_VER=$(echo $EXTENSION_DATA | jq --arg version "$CURRENT_GNOME_VERSION" '.shell_version_map[$version].version')
  #  echo "Version: $EXT_VER, PK: $EXT_PK"
  #else
  #  echo "!!!Extension $UUID does not support GNOME Shell version $CURRENT_GNOME_VERSION."
  #fi


  #VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=$EXTENSION_ID" | jq '.extensions[0] | .shell_version_map | map(.pk) | max')
  #echo "Installing $EXTENSION_ID - $i"
  #wget -q -O "${EXTENSION_ID}.zip" "https://extensions.gnome.org/download-extension/${EXTENSION_ID}.shell-extension.zip?version_tag=$VERSION_TAG"
  #gnome-extensions install --force ${EXTENSION_ID}.zip
  #if ! gnome-extensions list | grep --quiet ${EXTENSION_ID}; then
  #  busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s ${EXTENSION_ID}
  #fi
  #gnome-extensions enable ${EXTENSION_ID}
  #rm ${EXTENSION_ID}.zip
done
#sudo apt update
#sudo apt install -y gnome-tweaks gnome-shell-extension-manager chrome-gnome-shell
