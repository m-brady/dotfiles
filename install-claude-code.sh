#!/usr/bin/env bash
# Install Claude Code CLI
# https://docs.anthropic.com/en/docs/claude-code/installation

set -e

echo "Installing Claude Code..."

# Check if already installed
if command -v claude &> /dev/null; then
    echo "Claude Code is already installed at: $(command -v claude)"
    claude --version
    read -p "Reinstall? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Download and run the official installer
curl -fsSL https://install.anthropic.com/claude | sh

echo ""
echo "Claude Code installed successfully!"
echo ""
echo "Make sure ~/.local/bin is in your PATH. Add this to your shell config:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
echo ""
echo "Run 'claude' to get started."
