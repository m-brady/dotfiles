#!/usr/bin/env bash
# Install mise - a polyglot tool version manager
# https://mise.jdx.dev

set -e

echo "Installing mise..."

# Check if already installed
if command -v mise &> /dev/null; then
    echo "mise is already installed at: $(command -v mise)"
    mise --version
    echo "Updating mise..."
    mise self-update -y || true
    exit 0
fi

# Install via Homebrew
if command -v brew &> /dev/null; then
    echo "Installing mise via Homebrew..."
    brew install mise
else
    echo "Warning: Homebrew not found. Installing mise via curl..."
    curl https://mise.run | sh
fi

echo ""
echo "mise installed successfully!"
echo ""
