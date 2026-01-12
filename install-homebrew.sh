#!/usr/bin/env bash
# Install Homebrew package manager for macOS
# https://brew.sh

set -e

echo "Installing Homebrew..."

# Check if already installed
if command -v brew &> /dev/null; then
    echo "Homebrew is already installed at: $(command -v brew)"
    brew --version
    echo "Updating Homebrew..."
    brew update
    exit 0
fi

# Download and run the official installer
echo "Downloading and installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo ""
echo "Homebrew installed successfully!"
echo ""
