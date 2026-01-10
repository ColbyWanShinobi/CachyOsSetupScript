#! /bin/bash

# dconf watch /
# gnome-shell --replace &

# Get the default profile ID
#PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# Set the terminal width and height
#gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ default-size-columns 185
#gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ default-size-rows 35

gnome-extensions disable background-logo@fedorahosted.org
gnome-extensions disable hotedge@jonathan.jdoda.ca
gnome-extensions disable logomenu@aryan_k
gnome-extensions disable Move_Clock@rmy.pobox.com
gnome-extensions disable tilingshell@ferrarodomenico.com
gnome-extensions disable restartto@tiagoporsch.github.io

dconf write /org/cinnamon/desktop/wm/preferences/button-layout '"close,minimize,maximize:"'
dconf write /org/gnome/desktop/interface/clock-show-weekday true
dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"'
dconf write /org/gnome/desktop/interface/enable-hot-corners false
dconf write /org/gnome/desktop/peripherals/touchpad/click-method '"fingers"'
dconf write /org/gnome/desktop/peripherals/touchpad/edge-scrolling-enabled false
dconf write /org/gnome/desktop/peripherals/touchpad/natural-scroll false
dconf write /org/gnome/desktop/peripherals/touchpad/tap-to-click true
dconf write /org/gnome/desktop/peripherals/touchpad/two-finger-scrolling-enabled true
dconf write /org/gnome/desktop/wm/preferences/button-layout '"close,minimize,maximize:"'
dconf write /org/gnome/desktop/wm/preferences/num-workspaces 1
dconf write /org/gnome/mutter/check-alive-timeout "uint32 20000"
dconf write /org/gnome/mutter/dynamic-workspaces false
dconf write /org/gnome/mutter/edge-tiling true
dconf write /org/gnome/mutter/experimental-features '["scale-monitor-framebuffer", "variable-refresh-rate"]'
dconf write /org/gnome/nautilus/preferences/show-create-link true
dconf write /org/gnome/nautilus/preferences/show-image-thumbnails '"always"'
dconf write /org/gnome/Ptyxis/default-columns "uint32 120"
dconf write /org/gnome/Ptyxis/default-rows "uint32 35"
dconf write /org/gnome/Ptyxis/Profiles/e120f9c06588439938bd64ec67a5b22a/palette '"gnome"'
dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type '"nothing"'
dconf write /org/gnome/shell/extensions/advanced-weather/panel-position '"left"'
dconf write /org/gnome/shell/extensions/advanced-weather/use-fahrenheit true
dconf write /org/gnome/shell/extensions/advanced-weather/wind-speed-unit '"mph"'
dconf write /org/gnome/shell/extensions/appindicator/legacy-tray-enabled true
dconf write /org/gnome/shell/extensions/dash-to-dock/background-opacity "0.5"
dconf write /org/gnome/shell/extensions/dash-to-dock/click-action '"minimize-or-previews"'
dconf write /org/gnome/shell/extensions/dash-to-dock/custom-theme-shrink true
dconf write /org/gnome/shell/extensions/dash-to-dock/disable-overview-on-startup true
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed true
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position '"LEFT"'
dconf write /org/gnome/shell/extensions/dash-to-dock/hot-keys false
dconf write /org/gnome/shell/extensions/dash-to-dock/running-indicator-style '"DOTS"'
dconf write /org/gnome/shell/extensions/dash-to-dock/show-apps-at-top true
dconf write /org/gnome/shell/extensions/dash-to-dock/show-mounts false
dconf write /org/gnome/shell/extensions/dash-to-dock/transparency-mode '"FIXED"'
dconf write /org/gnome/shell/extensions/just-perfection/support-notifier-type "0"
dconf write /org/gnome/shell/extensions/notifications-alert/color '"rgb(51,209,122)"'
dconf write /org/gnome/shell/extensions/openweatherrefined/position-in-panel '"left"'
dconf write /org/gnome/shell/extensions/openweatherrefined/show-comment-in-panel true
dconf write /org/gnome/shell/extensions/tiling-assistant/enable-tiling-popup false
dconf write /org/gnome/shell/weather/automatic-location true
dconf write /org/gnome/system/locale/region '"en_US.UTF-8"'
dconf write /org/gtk/gtk4/settings/file-chooser/show-hidden true

# Add 'Games' to your existing folders
gsettings set org.gnome.desktop.app-folders folder-children "['System', 'Utilities', 'Games']"

# Configure the Games folder to include all apps with Game category
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Games/ name 'Games'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Games/ categories "['Game']"

