# Load transient prompt

# FOR MACOS specific setup
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    # load homebrew to mac systems
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # variable declaration for zlib and openssl
    LDFLAGS="-L$(brew --prefix openssl)/lib -L$(brew --prefix zlib)/lib"
    CPPFLAGS="-I$(brew --prefix openssl)/include -I$(brew --prefix zlib)/include"
    PKG_CONFIG_PATH="$(brew --prefix openssl)/lib/pkgconfig:$(brew --prefix zlib)/lib/pkgconfig"
    export LDFLAGS CPPFLAGS PKG_CONFIG_PATH

    # load zinit to mac systems
    if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
        command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
        command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
    fi
    source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
fi

# NOTE: please add for the linux systems

# pyENV initialization
eval "$(pyenv init --path)"
eval "$(pyenv init -)"


# enable starship
eval "$(starship init zsh)"

# enable plugins
# zinit light zsh-users/zsh-syntax-highlighting
zinit light zdharma-continuum/fast-syntax-highlighting # it is suppose to be the replacement for zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# coloured man pages
zinit light ael-code/zsh-colored-man-pages

# additional plugins
zinit snippet OMZP::git
zinit snippet OMZP::ssh
zinit snippet OMZP::dnf
zinit snippet OMZP::sudo
zinit snippet OMZP::systemd
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose
# zinit snippet OMZP::dotenv
zinit snippet OMZP::rust
zinit snippet OMZP::pip
zinit snippet OMZP::pipenv
zinit snippet OMZP::postgres
zinit snippet OMZP::web-search
zinit snippet OMZP::command-not-found
# zinit snippet OMZP::you-should-use


# load autocompletion
autoload -Uz compinit && compinit
zinit cdreplay -q

# keybinding to emacs mode
# bindings are 
#   ctrl+f accept a suggestion/forward is not suggestion
#   ctrl+b backward a suggestion
#   ctrl+a start of a suggestion
#   ctrl+e end of a suggestion
#   ctrl+p previous command in command history
#   ctrl+n next command in command history
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# don't know the full command
bindkey '^[w' kill-region

# auto completion preference
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
    # for docker plugin
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

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
export SAVEHIST HISTDUP

# enable fzf
# source <(fzf --zsh)
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# custom aliases
alias c='clear'
alias ls='ls --color'
alias vim='ivim $(fzf -m --preview="bat --color=always {}")'
alias nano='nano $(fzf -m --preview="bat --color=always {}")'

# for minikube only
# alias kubectl="minikube kubectl --"

# extra environment variables for linux
# export PATH=$PATH:/home/extinctcoder/.local/bin

# run fastfetch
fastfetch

# tmux
# packages required
# fzf git zsh alacritty







# # custom setup for pyenv
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init --path)"
# eval "$(pyenv init -)"



# need to use transient prompt and instant prompt need to configure zsh-completion


# videos for reference
# https://www.youtube.com/watch?v=ud7YxC33Z3w&t=483s