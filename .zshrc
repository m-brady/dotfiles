eval "$(/opt/homebrew/bin/mise activate zsh)"
eval "$(starship init zsh)"
# bun comes from mise (see ~/.config/mise/config.toml), not from ~/.bun or Homebrew.
# The old `export PATH="$HOME/.bun/bin:$PATH"` here pointed at a directory that no
# longer exists; the completions line below is guarded, so it stays harmlessly.

# opencode
export PATH=/Users/michaelbrady/.opencode/bin:$PATH

alias cc="claude"

# GNU coreutils (timeout, etc.)
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# bun completions
[ -s "/Users/michaelbrady/.bun/_bun" ] && source "/Users/michaelbrady/.bun/_bun"

alias cw="claude --worktree"

# Everything below is machine-specific, so each block guards on the thing existing.
# That is deliberately NOT a hosts/<hostname>.zsh split: these are the only two
# divergences left, and a presence check reads better than a second file to keep in
# sync. Add a host file only when a block can't be expressed as "if it's installed".

# pyenv — general-purpose Python (DICOM/pydicom, numpy, openpyxl, anthropic SDK), not
# version management: nothing in ~/Code pins a Python version. The guard on `pyenv init`
# matters — unguarded, it throws "command not found" on every shell start on a machine
# without pyenv.
# Two separate conditions on purpose. $PYENV_ROOT/bin does NOT exist here — pyenv is a
# Homebrew install and ~/.pyenv is only its data directory (versions/, shims/), so that
# first check has always been false and is kept only for a source-built pyenv. The
# `pyenv init` line is the one that actually does the work, and it must be guarded on
# the BINARY, not on that directory: nesting it inside the dead check silently dropped
# python3 from pyenv's 3.12.8 to Homebrew's 3.14.6.
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)"

# Android SDK (IronLog local builds) — added 2026-06-21
if [[ -d "/opt/homebrew/share/android-commandlinetools" ]]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
  export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
  export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
fi
