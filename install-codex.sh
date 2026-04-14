#! /bin/bash

mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
npm i -g @openai/codex

EXPORT_LINE='export PATH="$HOME/.npm-global/bin:$PATH"'
if ! grep -qF "$EXPORT_LINE" "$HOME/.bashrc"; then
    echo "$EXPORT_LINE" >> "$HOME/.bashrc"
fi
