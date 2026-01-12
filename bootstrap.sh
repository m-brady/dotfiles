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

# Setup Claude Code configuration
echo ""
echo "==> Setting up Claude Code configuration..."
./setup-claude-config.sh

# Install Starship prompt and Nerd Font
echo ""
echo "==> Installing Starship prompt..."
./install-starship.sh

# Install mise for language version management
echo ""
echo "==> Installing mise..."
./install-mise.sh

# Setup shell PATH
echo ""
echo "==> Setting up shell..."
./setup-shell.sh

# Install language runtimes via mise
echo ""
echo "==> Installing language runtimes (bun, node, go)..."
# Source mise to make it available in this script
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate bash)"
elif command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi
mise install -y || echo "Note: mise install will complete after shell restart"

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Configure your terminal to use 'FiraCode Nerd Font' or 'FiraCode NF'"
echo "  2. Restart your shell or run: source ~/.zshrc"
echo "  3. Run 'claude' to authenticate"
echo ""
