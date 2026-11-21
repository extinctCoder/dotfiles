ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "$ZINIT_HOME/zinit.zsh"


zinit light zsh-users/zsh-completions
autoload -Uz compinit && compinit
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

eval "$(zoxide init zsh)"
source <(fzf --zsh)
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/config.yaml)"

export BAT_THEME=ansi
alias ls='eza --icons'
