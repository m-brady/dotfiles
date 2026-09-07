#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Linking dotfiles from $DOTFILES..."

# Shell
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.zprofile" ~/.zprofile
# .zshenv is read by EVERY zsh, interactive or not — it is what makes non-interactive
# shells (git hooks, ssh commands) resolve mise-managed tool versions. It went untracked
# for a long time, which is why the mini never got it and three tools there read as
# "not installed" over ssh.
ln -sf "$DOTFILES/.zshenv" ~/.zshenv

# Git
ln -sf "$DOTFILES/.gitconfig" ~/.gitconfig

# Starship prompt
mkdir -p ~/.config
ln -sf "$DOTFILES/starship.toml" ~/.config/starship.toml

# Claude Code
mkdir -p ~/.claude
ln -sf "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md

# The whole skills directory is linked, not one link per skill. Claude Code writes a new
# skill straight into ~/.claude/skills/<name>/, so linking the directory means every
# skill you write from now on is tracked with no edit here. Per-skill links would need a
# new line each time, and "remember to add a line" is the same failure that let
# settings.json drift for four months.
ln -sfn "$DOTFILES/claude/skills" ~/.claude/skills

# settings.json is COPIED, never symlinked. Claude Code writes it atomically (temp file
# + rename), and that rename REPLACES a symlink with a regular file — so a symlink here
# silently stops tracking after the very first write. This failed twice: four months of
# drift caught on 2026-08-02, then six more days of it by 2026-08-08. A comment telling
# you to check `ls -la` first was not a mechanism; this is.
#
# Never overwrite a live file. Losing real settings is worse than staying out of sync,
# so on any difference we report and let you decide.
if [ -L ~/.claude/settings.json ]; then
  # Left over from when this script symlinked it. The link still resolves to the repo,
  # so replacing it with a copy of the repo file preserves the content exactly.
  rm ~/.claude/settings.json
  cp "$DOTFILES/claude/settings.json" ~/.claude/settings.json
  echo "  settings.json: converted symlink -> real file"
elif [ ! -e ~/.claude/settings.json ]; then
  cp "$DOTFILES/claude/settings.json" ~/.claude/settings.json
  echo "  settings.json: installed"
elif ! diff -q "$DOTFILES/claude/settings.json" ~/.claude/settings.json >/dev/null 2>&1; then
  echo "  ⚠️  settings.json differs from the repo and was NOT overwritten."
  echo "      Review, then copy the live version back into the repo:"
  echo "      cp ~/.claude/settings.json \"$DOTFILES/claude/settings.json\""
fi

echo "Dotfiles linked."

# Homebrew
if command -v brew &>/dev/null; then
  echo "Installing brew packages..."
  brew bundle --file="$DOTFILES/Brewfile"
else
  echo "Homebrew not found. Install it first: https://brew.sh"
fi

echo "Done!"
