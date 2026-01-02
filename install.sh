#!/bin/bash

# install.sh - Main installation script for dotfiles
# This script sets up symlinks from the home directory to dotfiles in this repo

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}Installing dotfiles from: ${DOTFILES_DIR}${NC}"

# Function to create a symlink
create_symlink() {
  local source="$1"
  local target="$2"
  
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ]; then
      # It's already a symlink
      local current_source="$(readlink "$target")"
      if [ "$current_source" = "$source" ]; then
        echo -e "${YELLOW}✓${NC} $target already linked correctly"
        return
      else
        echo -e "${YELLOW}⚠${NC}  $target is a symlink to a different location. Replacing..."
        rm "$target"
      fi
    else
      # It's a regular file/directory
      echo -e "${YELLOW}⚠${NC}  $target already exists. Backing up to ${target}.backup"
      mv "$target" "${target}.backup"
    fi
  fi
  
  ln -s "$source" "$target"
  echo -e "${GREEN}✓${NC} Linked $target -> $source"
}

# Create necessary directories
echo -e "\n${GREEN}Creating necessary directories...${NC}"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/bin"

# Symlink dotfiles
echo -e "\n${GREEN}Creating symlinks for dotfiles...${NC}"
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
create_symlink "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"

# Symlink .config directory
if [ -d "$DOTFILES_DIR/.config" ]; then
  for config_dir in "$DOTFILES_DIR/.config"/*; do
    if [ -d "$config_dir" ]; then
      config_name="$(basename "$config_dir")"
      create_symlink "$config_dir" "$HOME/.config/$config_name"
    fi
  done
fi

# Check if Homebrew is installed
echo -e "\n${GREEN}Checking for Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
  echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
  echo -e "${YELLOW}Note: This will download and run the official Homebrew installation script.${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    echo -e "${RED}Failed to install Homebrew. Exiting...${NC}"
    exit 1
  }
  
  # Add Homebrew to PATH based on architecture
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo -e "${GREEN}✓${NC} Homebrew already installed"
fi

# Install from Brewfile
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
  echo -e "\n${GREEN}Installing packages from Brewfile...${NC}"
  echo -e "${YELLOW}This may take a while...${NC}"
  brew bundle --file="$DOTFILES_DIR/Brewfile"
else
  echo -e "${YELLOW}⚠${NC}  No Brewfile found. Skipping package installation."
fi

# Install Oh My Zsh if not installed
echo -e "\n${GREEN}Checking for Oh My Zsh...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
    echo -e "${RED}Failed to install Oh My Zsh. Continuing...${NC}"
  }
  
  # Install zsh-autosuggestions
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || {
      echo -e "${RED}Failed to install zsh-autosuggestions. Continuing...${NC}"
    }
  fi
  
  # Install zsh-syntax-highlighting
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || {
      echo -e "${RED}Failed to install zsh-syntax-highlighting. Continuing...${NC}"
    }
  fi
else
  echo -e "${GREEN}✓${NC} Oh My Zsh already installed"
fi

# Set zsh as default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
  echo -e "\n${GREEN}Setting zsh as default shell...${NC}"
  chsh -s "$(which zsh)"
  echo -e "${GREEN}✓${NC} Default shell set to zsh. Please log out and back in for this to take effect."
else
  echo -e "${GREEN}✓${NC} zsh is already the default shell"
fi

# Run macOS defaults if script exists
if [ -f "$DOTFILES_DIR/scripts/macos.sh" ]; then
  echo -e "\n${GREEN}Apply macOS defaults? (y/N)${NC}"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    bash "$DOTFILES_DIR/scripts/macos.sh"
  else
    echo -e "${YELLOW}Skipping macOS defaults${NC}"
  fi
fi

echo -e "\n${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ Dotfiles installation complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "\nPlease restart your terminal or run: ${YELLOW}source ~/.zshrc${NC}"
