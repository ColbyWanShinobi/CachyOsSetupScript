#!/usr/bin/env bash
set -euo pipefail

BASHRC="${HOME}/.bashrc"
BLOCK_START="# >>> cachy-os-setup-script: bash customizations >>>"
BLOCK_END="# <<< cachy-os-setup-script: bash customizations <<<"
BACKUP_DIR="${HOME}/.cache/cachy-os-setup-script/bashrc-backups"
BACKUP_TS="$(date +%Y%m%dT%H%M%S%z)"
BACKUP_FILE="${BACKUP_DIR}/.bashrc.${BACKUP_TS}.bak"

MANAGED_BLOCK="$(cat <<'EOF'
[[ $- != *i* ]] && return

# Source global definitions from the distro shell config.
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

__cachy_git_prompt() {
    if ! command -v git >/dev/null 2>&1; then
        return
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    local branch
    branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || true)"
    [ -n "$branch" ] || return

    printf ' (%s)' "$branch"
}

__cachy_history_sync() {
    history -a
    history -n
}

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

prompt_command_decl="$(declare -p PROMPT_COMMAND 2>/dev/null || true)"

case "$prompt_command_decl" in
    declare\ -a\ PROMPT_COMMAND=*)
        case " ${PROMPT_COMMAND[*]} " in
        *" __cachy_history_sync "*) ;;
        *)
            PROMPT_COMMAND+=(__cachy_history_sync)
            export PROMPT_COMMAND
            ;;
        esac
        ;;
    *)
        case ";${PROMPT_COMMAND:-};" in
        *";__cachy_history_sync;"*) ;;
        *)
            if [ -n "${PROMPT_COMMAND:-}" ]; then
                PROMPT_COMMAND="__cachy_history_sync;${PROMPT_COMMAND}"
            else
                PROMPT_COMMAND="__cachy_history_sync"
            fi
            export PROMPT_COMMAND
            ;;
        esac
        ;;
esac

PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\]$(__cachy_git_prompt)\[\033[00m\]\$ '

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export MANGOHUD=1
export MANGOHUD_CONFIG=no_display,arch,gpu_name,resolution,cpu_temp,gpu_temp
export LD_LIBRARY_PATH="$HOME/.local/lib:${LD_LIBRARY_PATH:-}"

if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
fi
EOF
)"

mkdir -p "$(dirname "$BASHRC")"
mkdir -p "$BACKUP_DIR"
if [ -e "$BASHRC" ]; then
    cp -p "$BASHRC" "$BACKUP_FILE"
else
    : > "$BASHRC"
fi

tmp_file="$(mktemp "${BASHRC}.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

awk -v start="$BLOCK_START" -v end="$BLOCK_END" '
    $0 == start { in_block = 1; next }
    $0 == end { in_block = 0; next }
    !in_block { print }
' "$BASHRC" > "$tmp_file"

{
    printf '%s\n' "$BLOCK_START"
    printf '%s\n' "$MANAGED_BLOCK"
    printf '%s\n' "$BLOCK_END"
} >> "$tmp_file"

if cmp -s "$tmp_file" "$BASHRC"; then
    rm -f "$tmp_file"
    trap - EXIT
    exit 0
fi

mv "$tmp_file" "$BASHRC"
trap - EXIT
