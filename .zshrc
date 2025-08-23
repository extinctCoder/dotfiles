#---------------------------------
# Environment Variables
#---------------------------------
export PATH="$HOME/bin:/usr/local/bin:$PATH"
export EDITOR="vim"
export BAT_THEME="Catppuccin Mocha"
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_AUTO_UPDATE_SECS=86400

#---------------------------------
# Exported Variables
#---------------------------------
export PYENV_ROOT="$HOME/.pyenv"

#---------------------------------
# Shell Options
#---------------------------------
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

#---------------------------------
# Prompt Configuration
#---------------------------------
eval "$(starship init zsh)"
# eval "$(oh-my-posh init zsh --config ~/.config/oh_my_posh.toml)"

#---------------------------------
# Plugin/Framework Initialization
#---------------------------------
# Homebrew
if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # Homebrew Command Not Found Handler
  HB_CNF_HANDLER="$(brew --repository)/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
  if [ -f "$HB_CNF_HANDLER" ]; then
    source "$HB_CNF_HANDLER"
  fi
  # Forgit Plugin
  [ -f $HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh ] && source $HOMEBREW_PREFIX/share/forgit/forgit.plugin.zsh
fi

# Pyenv
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

#---------------------------------
# Completions
#---------------------------------
FPATH="$HOME/.docker/completions:$FPATH"
autoload -Uz compinit && compinit

#---------------------------------
# Zinit Plugins & Snippets
#---------------------------------
# Basic plugins
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light loiccoyle/zsh-github-copilot

# Snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# Additional
zinit cdreplay -q

#---------------------------------
# FZF Preview Options
#---------------------------------
_preview_options="
if [ -d {} ]; then
  eza --long --tree --git --level=3 --color=always --icons=always --no-user --no-time --links --context --total-size {};
elif [ -r {} ]; then
  mime=\$(file --mime-type -b {});
  if [[ \$mime == image/* ]]; then
    echo \"Image file: {}\";
  elif [[ \$mime == application/json ]]; then
    bat -n --color=always --wrap=auto --language=json {};
  elif [[ \$mime == text/* ]]; then
    bat -n --color=always --wrap=auto {};
  else
    echo \"Unsupported or binary file type: \$mime\";
  fi;
else
  echo \"File not readable\";
fi"
export FZF_DEFAULT_OPTS="--preview '$_preview_options'"

#---------------------------------
# Aliases
#---------------------------------
alias c='clear'
alias cat='bat'
alias vim='nvim'
alias reload='source ~/.zshrc'
alias ls='eza --icons=always --color=always --git'
alias vi='fd --type f --hidden --exclude .git . | fzf | xargs nvim'
alias fcd='cd "$(fd --type d --hidden --exclude ".*" . | fzf )"'

#---------------------------------
# Functions
#---------------------------------
# (ADDITIONAL FUNCTIONS CAN BE ADDED HERE)

#---------------------------------
# Key Bindings
#---------------------------------
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '»' zsh_gh_copilot_explain
bindkey '«' zsh_gh_copilot_suggest

#---------------------------------
# Shell Integrations
#---------------------------------
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

#---------------------------------
# Other Customizations
#---------------------------------
# (ADDITIONAL CUSTOMIZATIONS CAN BE ADDED HERE)
