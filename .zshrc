eval "$(/Users/michaelbrady/.local/bin/mise activate zsh)"
eval "$(starship init zsh)"
export PATH="/Users/michaelbrady/.bun/bin:$PATH"
alias gemini="bunx --package @google/gemini-cli gemini"

# opencode
export PATH=/Users/michaelbrady/.opencode/bin:$PATH

alias cc="claude"

# GNU coreutils (timeout, etc.)
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# bun completions
[ -s "/Users/michaelbrady/.bun/_bun" ] && source "/Users/michaelbrady/.bun/_bun"

alias cw="claude --worktree"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Android SDK (IronLog local builds) — added 2026-06-21
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
