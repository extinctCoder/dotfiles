#---------------------------------
# Environment
#---------------------------------
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim
export MANPAGER="sh -c 'col -bx | bat -l man -p --paging always'"
export MANROFFOPT="-c"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_DEFAULT_OPTS="--inline-info"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'if [ -d {} ]; then eza --tree --level=2 --icons=always --color=always {}; else bat -n --color=always {}; fi'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=always --color=always {}'"

# Secrets (API keys, tokens): untracked file, never in the repo
[ -f "$HOME/.secrets.zsh" ] && source "$HOME/.secrets.zsh"

#---------------------------------
# History and shell options
#---------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS
setopt AUTO_CD INTERACTIVE_COMMENTS

#---------------------------------
# Python (only if pyenv is installed)
#---------------------------------
if command -v pyenv >/dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    eval "$(pyenv init - zsh)"
fi

#---------------------------------
# Zinit
#---------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" &>/dev/null
fi
source "$ZINIT_HOME/zinit.zsh"

#---------------------------------
# Completions, then plugins (order matters)
#---------------------------------
zinit light zsh-users/zsh-completions
autoload -Uz compinit && compinit
zinit cdreplay -q

zinit light Aloxaf/fzf-tab              # right after compinit
zinit light zsh-users/zsh-autosuggestions
zinit light wfxr/forgit
zinit light loiccoyle/zsh-github-copilot

zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo                # Esc Esc adds sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found   # uses pkgfile

zinit light zdharma-continuum/fast-syntax-highlighting   # always last

#---------------------------------
# Completion styling
#---------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --icons=always --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --level=2 --icons=always --color=always $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --color=always --style=numbers $realpath'

#---------------------------------
# Aliases
#---------------------------------
alias c='clear'
alias cat='bat --paging=never'
alias vim='nvim'
alias v='nvim'
alias top='btop'
alias y='yazi'
alias lg='lazygit'
alias ff='fastfetch'
alias reload='source ~/.zshrc'
alias update='yay -Syu'
alias ls='eza --icons=always --color=always --git --group-directories-first'
alias ll='ls -l'
alias la='ls -la'
alias tree='eza --tree --icons=always'
alias psg='ps aux | grep -v grep | grep -i -e'
alias vf='fd --type f --hidden --exclude .git | fzf -m --preview "bat -n --color=always {}" | xargs -r nvim'
alias fcd='cd "$(fd --type d --hidden --exclude .git | fzf --preview "eza --tree --level=2 --icons=always --color=always {}")"'

#---------------------------------
# Key bindings
#---------------------------------
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '^[e' zsh_gh_copilot_explain    # Alt+E
bindkey '^[s' zsh_gh_copilot_suggest    # Alt+S

#---------------------------------
# Integrations and prompt
#---------------------------------
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/config.yaml)"
