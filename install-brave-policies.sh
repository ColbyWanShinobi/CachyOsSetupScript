#! /bin/bash

echo "Copying Brave policy file..."

sudo mkdir -p /etc/brave/policies/managed

sudo cp brave-policies.json /etc/brave/policies/managed

echo "Brave policy file installed"
