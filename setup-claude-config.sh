#!/usr/bin/env bash
# Setup Claude Code configuration with safe command allowlist

set -e

CLAUDE_CONFIG_DIR="$HOME/.claude"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CONFIG="$DOTFILES_DIR/.claude/settings.json"
TARGET_CONFIG="$CLAUDE_CONFIG_DIR/settings.json"

echo "Setting up Claude Code configuration..."

# Create .claude directory if it doesn't exist
mkdir -p "$CLAUDE_CONFIG_DIR"

# Check if config already exists
if [ -f "$TARGET_CONFIG" ]; then
    echo "Claude Code config already exists at $TARGET_CONFIG"
    echo "Backing up existing config to $TARGET_CONFIG.backup"
    cp "$TARGET_CONFIG" "$TARGET_CONFIG.backup"
fi

# Copy the config
echo "Copying Claude Code configuration..."
cp "$SOURCE_CONFIG" "$TARGET_CONFIG"

echo "Claude Code configuration installed successfully!"
echo "Config location: $TARGET_CONFIG"
echo ""
echo "The config includes safe allowlists for:"
echo "  - Git commands (status, diff, commit, push, etc.)"
echo "  - Package managers (npm, bun, go, cargo, pip)"
echo "  - mise tool version manager"
echo "  - Build tools (make, docker)"
echo "  - File operations (ls, mkdir, mv, cp, cat, etc.)"
echo ""
