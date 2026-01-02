# dotfiles

My personal dotfiles for fresh Mac installations. This repository includes shell configurations, Homebrew package management, custom fonts, and macOS system preferences.

## 🚀 Quick Start

```bash
# Clone this repository
git clone https://github.com/m-brady/dotfiles.git ~/.dotfiles

# Navigate to the directory
cd ~/.dotfiles

# Run the installation script
./install.sh
```

The install script will:
- Create symlinks for dotfiles in your home directory
- Install Homebrew (if not already installed)
- Install all packages and applications from the Brewfile
- Install Oh My Zsh with useful plugins
- Set zsh as your default shell
- Optionally apply macOS system defaults

## 📁 What's Included

### Shell Configuration

- **`.zshrc`** - Zsh configuration with Oh My Zsh support
- **`.bashrc`** - Bash configuration
- **`.aliases`** - Common shell aliases and functions for both shells

Features:
- Sensible defaults and history settings
- Modern tool replacements (bat, exa, fd, ripgrep)
- Version manager support (nvm, pyenv, rbenv)
- FZF integration for fuzzy finding
- Custom aliases for git, docker, and system commands

### Git Configuration

- **`.gitconfig`** - Git configuration with useful aliases and colors
- **`.gitignore_global`** - Global gitignore for common files

Features:
- Pretty log formatting
- Helpful git aliases
- Automatic whitespace fixing
- Enhanced diff output

### Homebrew

- **`Brewfile`** - List of packages and applications to install

Includes:
- Core utilities (coreutils, findutils, gnu-sed, etc.)
- Development tools (git, gh, curl, wget, jq)
- Modern CLI tools (bat, exa, fd, ripgrep, fzf)
- Version managers (nvm, pyenv, rbenv)
- Programming languages (Python, Node, Go)
- Applications (VS Code, iTerm2, Docker, Rectangle, Alfred, 1Password)
- Fonts (Fira Code, JetBrains Mono, Nerd Fonts)

### Scripts

- **`install.sh`** - Main installation script
- **`scripts/macos.sh`** - macOS system defaults and preferences
- **`scripts/brew-update.sh`** - Update Homebrew and regenerate Brewfile

### Configuration

- **`.config/`** - XDG Base Directory compliant configs
- **`fonts/`** - Directory for custom fonts

## 📋 Requirements

- macOS (tested on recent versions)
- Command Line Tools or Xcode
- Internet connection

## 🛠️ Usage

### First Time Setup

1. Clone this repository to `~/.dotfiles`
2. Run `./install.sh`
3. Restart your terminal

### Updating

```bash
cd ~/.dotfiles
git pull
./install.sh  # Re-run to update symlinks if needed
```

### Keeping Homebrew Packages Up to Date

```bash
# Update packages and regenerate Brewfile
./scripts/brew-update.sh
```

### Applying macOS Defaults

```bash
# Run macOS defaults script
./scripts/macos.sh
```

This will configure various macOS settings including:
- Finder preferences (show hidden files, extensions, path bar)
- Keyboard and trackpad settings
- Dock preferences
- Screenshot settings
- Safari privacy settings
- And more...

## 🎨 Customization

### Adding Your Own Settings

The dotfiles are designed to be forked and customized:

1. Fork this repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles`
3. Modify the files to suit your preferences
4. Run `./install.sh` to apply changes

### User-Specific Configuration

You can add local configurations that won't be tracked by git:

- **`~/.zshrc.local`** - Local zsh configuration
- **`~/.bashrc.local`** - Local bash configuration
- **`~/.gitconfig.local`** - Local git configuration

Example `~/.gitconfig.local`:
```gitconfig
[user]
    name = Your Name
    email = your.email@example.com
```

Then add to `.gitconfig`:
```gitconfig
[include]
    path = ~/.gitconfig.local
```

### Adding More Packages

Edit the `Brewfile` to add more packages:

```ruby
# Add a formula
brew "package-name"

# Add a cask (application)
cask "application-name"

# Add a font
cask "font-name-nerd-font"
```

Then run:
```bash
brew bundle --file=~/.dotfiles/Brewfile
```

## 📚 Directory Structure

```
.
├── .config/                 # XDG config directory
│   └── README.md
├── fonts/                   # Custom fonts
│   └── README.md
├── scripts/                 # Utility scripts
│   ├── macos.sh            # macOS defaults
│   └── brew-update.sh      # Homebrew update script
├── .aliases                 # Shell aliases
├── .bashrc                  # Bash configuration
├── .gitconfig               # Git configuration
├── .gitignore_global        # Global gitignore
├── .zshrc                   # Zsh configuration
├── Brewfile                 # Homebrew packages
├── install.sh               # Main installation script
└── README.md                # This file
```

## 🤝 Contributing

Feel free to fork this repository and customize it for your own use. If you have suggestions for improvements, please open an issue or pull request.

## 📝 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

Inspired by and borrowed ideas from:
- [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles)
- [Holman's dotfiles](https://github.com/holman/dotfiles)
- [Oh My Zsh](https://ohmyz.sh/)

## 📬 Contact

For questions or suggestions, please open an issue in this repository.