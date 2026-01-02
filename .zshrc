# .zshrc - Zsh configuration

# Path to oh-my-zsh installation (if installed)
export ZSH="$HOME/.oh-my-zsh"

# Set theme (if oh-my-zsh is installed)
ZSH_THEME="robbyrussell"

# Plugins (if oh-my-zsh is installed)
plugins=(
  git
  docker
  kubectl
  npm
  python
  brew
  macos
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load oh-my-zsh if installed
if [ -d "$ZSH" ]; then
  source $ZSH/oh-my-zsh.sh
fi

# Environment variables
export EDITOR='vim'
export VISUAL='vim'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Homebrew setup
if [[ "$(uname -m)" == "arm64" ]]; then
  # Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # Intel
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Path additions
export PATH="$HOME/bin:$PATH"
export PATH="/usr/local/bin:$PATH"

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

# Pyenv
if command -v pyenv 1>/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# Rbenv
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

# FZF configuration
if command -v fzf 1>/dev/null 2>&1; then
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Load aliases
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Load local configuration if it exists
if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Completions
autoload -Uz compinit
# Check if compinit needs to be run (once per day)
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Better directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Enable color support
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# Modern tool replacements
if command -v bat 1>/dev/null 2>&1; then
  alias cat='bat'
fi

if command -v exa 1>/dev/null 2>&1; then
  alias ls='exa'
  alias ll='exa -l'
  alias la='exa -la'
  alias tree='exa --tree'
fi
