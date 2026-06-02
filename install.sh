#!/bin/bash
set -e

# Ensure HOME is set
export HOME="${HOME:-$(getent passwd $(whoami) | cut -d: -f6)}"

echo "Installing minimal Zsh environment..."

# Install zsh if missing
if ! command -v zsh &> /dev/null; then
    echo "Installing zsh..."
    sudo apt-get update && sudo apt-get install -y zsh
fi

# Install fzf if missing
if ! command -v fzf &> /dev/null; then
    echo "Installing fzf..."
    sudo apt-get update && sudo apt-get install -y fzf
fi

# Install zoxide - try apt first, fallback to binary
if ! command -v zoxide &> /dev/null; then
    echo "Installing zoxide..."
    if sudo apt-get install -y zoxide 2>/dev/null; then
        echo "zoxide installed via apt"
    else
        echo "Installing zoxide from binary..."
        ZOXIDE_LATEST=$(curl -sSfL https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'][1:])")
        curl -sSfL "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_LATEST}/zoxide-${ZOXIDE_LATEST}-x86_64-unknown-linux-musl.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/zoxide /usr/local/bin/zoxide
        chmod +x /usr/local/bin/zoxide
    fi
fi

# Create necessary directories
mkdir -p "${HOME}/.zshrc.d"
mkdir -p "${HOME}/.local/share"
mkdir -p "${HOME}/.cache"

# Install zinit if not present
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    echo "Installing zinit..."
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Install powerlevel10k if not present
P10K_DIR="${HOME}/.local/share/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    echo "Installing powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# Create additional directories for zinit
mkdir -p "${HOME}/.local/share/zinit/plugins"

echo "Deploying configuration files..."

# Deploy .zshrc
cat > "${HOME}/.zshrc" << 'EOF'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load init.sh first
source ~/.zshrc.d/init.sh

# Load all other .sh files in ~/.zshrc.d/
for file in ~/.zshrc.d/*.sh; do
    filename=$(basename "$file")
    [ "$filename" = "init.sh" ] && continue
    source "$file"
done

# Load p10k theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

# Deploy zshrc.d/init.sh
cat > "${HOME}/.zshrc.d/init.sh" << 'EOF'
#!/bin/zsh

# Set zinit directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Source zinit if exists
if [ -f "$ZINIT_HOME/zinit.zsh" ]; then
    source "$ZINIT_HOME/zinit.zsh"
else
    echo "zinit not found. Run install.sh first."
    return 1
fi

# Add powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load git snippets from Oh My Zsh
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Initialize compinit
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m-1) ]]; then
    compinit -C
else
    compinit
fi

zinit cdreplay -q

# Keybindings - Ctrl+Left/Right Arrow to jump words
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# History settings
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Add local bin to PATH
export PATH="$PATH:$HOME/.local/bin"
EOF

# Deploy zshrc.d/alias.sh
cat > "${HOME}/.zshrc.d/alias.sh" << 'EOF'
# Basic aliases
alias ls='ls --color'
alias ll='ls -lh --color'
alias vim='nvim'
alias c='clear'
alias k='kubectl'
alias tg='terragrunt'
alias tf='terraform'
EOF

# Deploy zshrc.d/fzf.sh
cat > "${HOME}/.zshrc.d/fzf.sh" << 'EOF'
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
EOF

# Deploy .p10k.zsh (copy from local dotfiles repo if exists, otherwise download)
if [ -f "$(dirname "${BASH_SOURCE[0]}")/.p10k.zsh" ]; then
    cp -f "$(dirname "${BASH_SOURCE[0]}")/.p10k.zsh" "${HOME}/.p10k.zsh"
else
    echo "Warning: .p10k.zsh not found, skipping powerlevel10k config deployment"
fi

# Make scripts executable
chmod +x "${HOME}/.zshrc.d/init.sh" "${HOME}/.zshrc.d/fzf.sh"

# Set zsh as default shell
echo "Setting zsh as default shell..."
if command -v chsh &> /dev/null; then
    if [ "$(which zsh)" != "$SHELL" ]; then
        sudo chsh -s "$(which zsh)" || echo "Could not change default shell. Run manually: sudo chsh -s $(which zsh)"
    fi
fi

echo ""
echo "Installation complete! Restart your shell or run: zsh"