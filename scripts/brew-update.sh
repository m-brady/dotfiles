#!/bin/bash

# brew-update.sh - Update Homebrew packages and generate new Brewfile

set -e

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Updating Homebrew...${NC}"
brew update

echo -e "\n${GREEN}Upgrading installed packages...${NC}"
brew upgrade

echo -e "\n${GREEN}Cleaning up old versions...${NC}"
brew cleanup

echo -e "\n${GREEN}Running brew doctor...${NC}"
brew doctor || true

echo -e "\n${GREEN}Generating new Brewfile...${NC}"
# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
brew bundle dump --file="${DOTFILES_DIR}/Brewfile" --force

echo -e "\n${GREEN}✓ Homebrew update complete!${NC}"
echo -e "${YELLOW}Don't forget to commit the updated Brewfile if packages changed.${NC}"
