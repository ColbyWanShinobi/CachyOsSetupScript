#! /bin/bash

# Move Show Apps Button
#gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
dconf write /org/gnome/shell/extensions/dash-to-dock/show-apps-at-top true

# Use dark theme
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Always show thumbnail previews in Nautilus
dconf write /org/gnome/nautilus/preferences/show-image-thumbnails '"always"'

# Enable link creation in Nautilus
dconf write /org/gnome/nautilus/preferences/show-create-link true

# Allow location in weather applet
gsettings set org.gnome.shell.weather automatic-location true

# Set GNOME to use imperial units by default
gsettings set org.gnome.system.locale region 'en_US.UTF-8'

# Enable maximize and minimize buttons and move them to the top left corner
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Change touchpad scroll direction to natural
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

# Set the number of workspaces to one
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1

# Disable hot corner
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Get the default profile ID
PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# Set the terminal width and height
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ default-size-columns 185
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ default-size-rows 35

dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position '"LEFT"'
dconf write /org/gnome/shell/extensions/dash-to-dock/disable-overview-on-startup true
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed true
dconf write /org/gnome/shell/extensions/openweatherrefined/position-in-panel '"center"'
dconf write /org/gnome/shell/extensions/openweatherrefined/show-comment-in-panel true
dconf write /org/gnome/shell/extensions/notifications-alert/color '"rgb(51,209,122)"'

gsettings set org.gnome.mutter experimental-features '["variable-refresh-rate"]'

#gnome-shell --replace &

dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed true
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"