# Auto-update Homebrew once per day (86400 seconds = 24 hours)
export HOMEBREW_AUTO_UPDATE_SECS=86400

# Hide Homebrew environment hints in the terminal
export HOMEBREW_NO_ENV_HINTS=1

if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"


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
  elif [[ \$mime == application/json ]]; then
    bat -n --color=always --wrap=auto --language=json {};
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

# enable oh-my-posh
# eval "$(oh-my-posh init zsh --config ~/.config/oh_my_posh.toml)"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light loiccoyle/zsh-github-copilot

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# load docker completions
FPATH="$HOME/.docker/completions:$FPATH"

autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '»' zsh_gh_copilot_explain  # bind Option+shift+\ to explain
bindkey '«' zsh_gh_copilot_suggest  # bind Option+\ to suggest

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
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview "${_preview_options//\{\}/\$realpath}"
# zstyle ':fzf-tab:complete:git-branch:*' fzf-preview "git diff --color=always {-1}"
zstyle ':fzf-tab:complete:git-branch:*' fzf-preview 'git diff --color=always {-1} | delta'


# this is changed

# Aliases
alias vim='nvim'
alias c='clear'
alias ls='eza --icons=always --color=always'
alias cat='bat'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"


# Bat integration
export BAT_THEME="Catppuccin Mocha"

# FZF preview integration
export FZF_DEFAULT_OPTS="--preview '$_preview_options'"




# fastfetch

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/extinctcoder/.lmstudio/bin"
# End of LM Studio CLI section
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/extinctcoder/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
