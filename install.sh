#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Linking dotfiles from $DOTFILES..."

# Shell
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.zprofile" ~/.zprofile

# Git
ln -sf "$DOTFILES/.gitconfig" ~/.gitconfig

# Starship prompt
mkdir -p ~/.config
ln -sf "$DOTFILES/starship.toml" ~/.config/starship.toml

# Claude Code
mkdir -p ~/.claude
ln -sf "$DOTFILES/claude/settings.json" ~/.claude/settings.json

echo "Dotfiles linked."

# Homebrew
if command -v brew &>/dev/null; then
  echo "Installing brew packages..."
  brew bundle --file="$DOTFILES/Brewfile"
else
  echo "Homebrew not found. Install it first: https://brew.sh"
fi

echo "Done!"
