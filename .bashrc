# .bashrc - Bash configuration

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
  eval "$(rbenv init - bash)"
fi

# FZF configuration
if command -v fzf 1>/dev/null 2>&1; then
  [ -f ~/.fzf.bash ] && source ~/.fzf.bash
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Load aliases
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Load local configuration if it exists
if [ -f ~/.bashrc.local ]; then
  source ~/.bashrc.local
fi

# History configuration
export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# Better directory navigation
shopt -s autocd
shopt -s cdspell
shopt -s dirspell

# Enable color support
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# Bash completion
if [ -f "$HOMEBREW_PREFIX/etc/bash_completion" ]; then
  . "$HOMEBREW_PREFIX/etc/bash_completion"
fi

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

# Prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
