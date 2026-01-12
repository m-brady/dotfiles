#!/usr/bin/env bash
# Setup zsh configuration for dotfiles (macOS)

ZSHRC="$HOME/.zshrc"

# Create .zshrc if it doesn't exist
touch "$ZSHRC"

# Add Homebrew initialization if not already present
if ! grep -q 'brew shellenv' "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# Initialize Homebrew" >> "$ZSHRC"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$ZSHRC"
    echo "Added Homebrew initialization to .zshrc"
else
    echo "Homebrew initialization already in .zshrc"
fi

# Add ~/.local/bin to PATH if not already present
if ! grep -q '.local/bin' "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# Add ~/.local/bin to PATH" >> "$ZSHRC"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
    echo "Added ~/.local/bin to PATH in .zshrc"
else
    echo "~/.local/bin already in PATH in .zshrc"
fi

# Initialize mise if not already present
if ! grep -q 'mise activate' "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# Initialize mise for language version management" >> "$ZSHRC"
    echo 'eval "$(mise activate zsh)"' >> "$ZSHRC"
    echo "Added mise initialization to .zshrc"
else
    echo "mise initialization already in .zshrc"
fi

# Initialize Starship prompt if not already present
if ! grep -q 'starship init' "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# Initialize Starship prompt" >> "$ZSHRC"
    echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
    echo "Added Starship initialization to .zshrc"
else
    echo "Starship initialization already in .zshrc"
fi
