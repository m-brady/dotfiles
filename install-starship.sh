#!/usr/bin/env bash
# Install Starship prompt and FiraCode Nerd Font via Homebrew
# https://starship.rs

set -e

echo "Installing Starship prompt and FiraCode Nerd Font..."

# Check if Homebrew is available
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is not installed. Please run install-homebrew.sh first."
    exit 1
fi

# Install FiraCode Nerd Font
echo ""
echo "Installing FiraCode Nerd Font..."
if brew list --cask font-fira-code-nerd-font &> /dev/null; then
    echo "FiraCode Nerd Font is already installed"
else
    brew install --cask font-fira-code-nerd-font
    echo "FiraCode Nerd Font installed successfully!"
fi

# Install Starship
echo ""
echo "Installing Starship..."
if command -v starship &> /dev/null; then
    echo "Starship is already installed at: $(command -v starship)"
    starship --version
else
    brew install starship
    echo "Starship installed successfully!"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Configure your terminal to use 'FiraCode Nerd Font' or 'FiraCode NF'"
echo "  2. Restart your shell to activate Starship"
echo ""
