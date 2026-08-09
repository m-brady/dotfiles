# Sourced by EVERY zsh invocation, interactive or not — unlike .zshrc, which
# non-interactive shells (git hooks, editor tooling) never read.
#
# Shims resolve the per-directory tool version at call time, so a repo's
# mise.toml is honored even where mise's chpwd/prompt hook never fires.
# `mise activate` in .zshrc strips the shims dir back out for interactive
# shells, so terminals resolve straight to the real binary with no extra hop.
# Homebrew path on purpose: mise is installed via the Brewfile on every machine so
# this file can be byte-identical everywhere. It previously differed per host
# (~/.local/bin here, /opt/homebrew/bin on the mini), which is the kind of one-line
# divergence that quietly forks a dotfiles repo.
eval "$(/opt/homebrew/bin/mise activate --shims)"

# pipx-installed CLIs live here — notably `idb`, which drives the iOS simulator on the
# mini. This has to be in .zshenv rather than .zshrc: those calls arrive over ssh as
# non-interactive shells, which never read .zshrc, and a missing idb there reads as
# "not installed" rather than "not on PATH".
export PATH="$HOME/.local/bin:$PATH"
