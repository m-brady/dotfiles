# Sourced by EVERY zsh invocation, interactive or not — unlike .zshrc, which
# non-interactive shells (git hooks, editor tooling, ssh commands) never read.
#
# Shims resolve the per-directory tool version at call time, so a repo's
# mise.toml is honored even where mise's chpwd/prompt hook never fires.
# `mise activate` in .zshrc strips the shims dir back out for interactive
# shells, so terminals resolve straight to the real binary with no extra hop.
eval "$(/opt/homebrew/bin/mise activate --shims)"

# pipx-installed CLIs (idb) live here and are otherwise invisible over ssh.
export PATH="$HOME/.local/bin:$PATH"
