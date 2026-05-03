#!/usr/bin/env bash

set -e

echo "Configuring firewall for Dropbox LAN sync..."

ufw_rules_changed=0

allow_ufw_rule() {
    local rule="$1"
    local comment="$2"

    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -Fq "$rule"; then
            echo "ufw rule for $rule already exists."
        else
            sudo ufw allow "$rule" comment "$comment"
            ufw_rules_changed=1
        fi
    else
        echo "ufw is not installed; skipping firewall rule for $rule."
    fi
}

allow_ufw_rule 17500/udp "Dropbox LAN sync discovery"
allow_ufw_rule 17599:17609/tcp "Dropbox LAN sync transfer"

if command -v ufw &> /dev/null && [[ "$ufw_rules_changed" -eq 1 ]]; then
    sudo ufw reload
fi

echo "Dropbox LAN sync firewall configuration complete."
