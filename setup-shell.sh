#!/usr/bin/env bash
# Setup shell configuration for dotfiles

# Add ~/.local/bin to PATH if not already present
add_to_path() {
    local shell_config="$1"
    local path_export='export PATH="$HOME/.local/bin:$PATH"'

    if [ -f "$shell_config" ]; then
        if ! grep -q '.local/bin' "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Added by dotfiles setup" >> "$shell_config"
            echo "$path_export" >> "$shell_config"
            echo "Added ~/.local/bin to PATH in $shell_config"
        else
            echo "~/.local/bin already in PATH in $shell_config"
        fi
    fi
}

# Detect shell and add to appropriate config file
if [ -n "$ZSH_VERSION" ]; then
    add_to_path "$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    add_to_path "$HOME/.bashrc"
    add_to_path "$HOME/.bash_profile"
else
    echo "Unknown shell. Manually add to your shell config:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi
