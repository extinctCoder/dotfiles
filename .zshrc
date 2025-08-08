if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

HB_CNF_HANDLER="$(brew --repository)/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
if [ -f "$HB_CNF_HANDLER" ]; then
source "$HB_CNF_HANDLER";
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# FZF PREVIEW OPTIONS
_preview_options="
if [ -d {} ]; then
  eza --long --tree --git --level=3 --color=always --icons=always --no-user --no-time --links --context --total-size {};
elif [ -r {} ]; then
  mime=\$(file --mime-type -b {});
  if [[ \$mime == image/* ]]; then
    echo \"📷 Image file: {}\"; 
  elif [[ \$mime == text/* ]]; then
    bat -n --color=always --wrap=auto {};
  else
    echo \"⚠️ Unsupported or binary file type: \$mime\";
  fi;
else
  echo \"🚫 File not readable\";
fi"

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# enable starship
eval "$(starship init zsh)"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
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
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview "${_preview_options//\{\}/\$realpath}"
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview "${_preview_options//\{\}/\$realpath}"

# Aliases
alias vim='nvim'
alias c='clear'
alias ls='eza --icons=always --color=always'
alias bat 

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"


# Bat integration
export BAT_THEME="Catppuccin Mocha"

# FZF preview integration
export FZF_DEFAULT_OPTS="--preview '$_preview_options'"


# Start tmux if not already inside tmux or SSH
# if [[ -z "$TMUX" ]] && [[ -z "$SSH_TTY" ]] && command -v tmux >/dev/null 2>&1; then
#   exec tmux new-session -A -s main
# fi

fastfetch