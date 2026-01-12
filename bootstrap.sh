#!/usr/bin/env bash
# Bootstrap script for setting up a new machine
# Run this on a fresh machine: curl -fsSL https://raw.githubusercontent.com/m-brady/dotfiles/main/bootstrap.sh | bash

set -e

DOTFILES_REPO="https://github.com/m-brady/dotfiles.git"
DOTFILES_DIR="$HOME/git/dotfiles"

echo "==> Bootstrapping dotfiles..."

# Create git directory if it doesn't exist
mkdir -p "$HOME/git"

# Clone dotfiles if not already present
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "==> Cloning dotfiles repo..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo "==> Dotfiles already cloned, pulling latest..."
    cd "$DOTFILES_DIR" && git pull
fi

cd "$DOTFILES_DIR"

# Install Homebrew
echo ""
echo "==> Installing Homebrew..."
./install-homebrew.sh

# Install Claude Code
echo ""
echo "==> Installing Claude Code..."
./install-claude-code.sh

# Setup shell PATH
echo ""
echo "==> Setting up shell..."
./setup-shell.sh

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Run 'claude' to authenticate"
echo ""
