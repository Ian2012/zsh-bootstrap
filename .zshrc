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