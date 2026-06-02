#!/bin/zsh
# FZF and Zoxide integration

# FZF - check version before using --zsh flag (old fzf < 0.30 doesn't have it)
if command -v fzf &> /dev/null; then
    FZF_VERSION=$(fzf --version 2>/dev/null | awk '{print $2}')
    if [[ -n "$FZF_VERSION" ]] && [[ $(echo -e "0.30.0\n$FZF_VERSION" | sort -V | head -1) == "0.30.0" ]]; then
        eval "$(fzf --zsh)"
    fi
fi

# Zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh --cmd cd)"
fi