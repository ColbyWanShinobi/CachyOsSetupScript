#!/usr/bin/env bash

set -euo pipefail

echo "Configuring firewall for Dropbox LAN sync..."

ufw_rules_changed=0

have_ufw() {
    command -v ufw >/dev/null 2>&1
}

allow_ufw_rule() {
    local rule="$1"
    local comment="$2"

    if ! have_ufw; then
        echo "ufw is not installed; skipping firewall rule for $rule."
        return 0
    fi

    # Check existing numbered rules more precisely.
    # Example output line:
    # [ 1] 17500/udp                  ALLOW IN    Anywhere # Dropbox LAN sync discovery
    if sudo ufw status numbered | grep -Eq "^[[:space:]]*\[[[:space:]]*[0-9]+\][[:space:]]+${rule//\//\\/}[[:space:]]+ALLOW IN"; then
        echo "ufw rule for $rule already exists."
    else
        sudo ufw allow "$rule" comment "$comment"
        ufw_rules_changed=1
    fi
}

if ! have_ufw; then
    echo "ufw is not installed; nothing to configure."
    exit 0
fi

allow_ufw_rule "17500/udp" "Dropbox LAN sync discovery"
allow_ufw_rule "17500/tcp" "Dropbox LAN sync transfer"

if [[ "$ufw_rules_changed" -eq 1 ]]; then
    sudo ufw reload
fi

echo "Dropbox LAN sync firewall configuration complete."