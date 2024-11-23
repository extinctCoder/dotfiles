# Load transient prompt


# zinit initailization
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# enable starship
eval "$(starship init zsh)"

# enable plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# additional plugins
zinit snippet OMZP::git
zinit snippet OMZP::ssh
zinit snippet OMZP::dnf
zinit snippet OMZP::sudo
zinit snippet OMZP::systemd
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose
zinit snippet OMZP::dotenv
zinit snippet OMZP::rust
zinit snippet OMZP::pip
zinit snippet OMZP::pipenv
zinit snippet OMZP::postgres
zinit snippet OMZP::web-search
zinit snippet OMZP::command-not-found
# zinit snippet OMZP::you-should-use
# load autocompletions
autoload -Uz compinit && compinit
zinit cdreplay -q

# keybinding to emacs mode
# bingins are 
#   ctrl+f accepct a suggestion/forwaord is not suggestion
#   ctrl+b backword a suggestion
#   ctrl+a start of a suggestion
#   ctrl+e end of a suggestion
#   ctrl+p previous command in command history
#   ctrl+n next command in command histroy
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# dont know the full command
bindkey '^[w' kill-region

# auto completion preferance
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# zsh essentials
HISTSIZE=100000
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

# enable fzf
source <(fzf --zsh)

# custom aliases
alias c='clear'
alias ls='ls --color'
alias vim='ivim $(fzf -m --preview="bat --color=always {}")'
alias nano='nano $(fzf -m --preview="bat --color=always {}")'

# for minikube only
# alias kubectl="minikube kubectl --"

# extra environment variables
export PATH=$PATH:/home/extinctcoder/.local/bin

# run fastfetch
fastfetch


# packages required
# fzf git zsh alacritty

