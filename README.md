# dotfiles

Personal dotfiles and setup scripts for a fresh machine.

## Quick Start

On a new machine:

```bash
git clone https://github.com/m-brady/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-claude-code.sh
./setup-shell.sh
```

## What's Included

- **Claude Code CLI** - AI-powered coding assistant
  - `install-claude-code.sh` - Downloads and installs Claude Code
  - `setup-shell.sh` - Adds `~/.local/bin` to PATH and initializes tools
  - `bootstrap.sh` - One-command setup for fresh machines

- **mise** - Polyglot tool version manager
  - `install-mise.sh` - Installs mise via Homebrew
  - `.mise.toml` - Configures language runtimes (bun, node, go)
  - Automatically installs and manages language versions

- **Starship Prompt** - Cross-shell prompt
  - `install-starship.sh` - Installs Starship and FiraCode Nerd Font

## Manual Steps

After running the scripts:

1. Restart your shell or run `source ~/.zshrc` (or equivalent)
2. Run `claude` to authenticate and complete setup
3. Configure your preferred settings with `/config` in Claude Code

## Using mise

mise is configured via `.mise.toml` to manage language versions. After setup:

```bash
# Check installed tools
mise list

# Update all tools to latest versions
mise upgrade

# Install a specific tool version
mise use node@20

# Add tools to your project
cd your-project
mise use bun@latest go@1.21
```

The global `.mise.toml` in this repo includes:
- **bun** - Fast JavaScript runtime and package manager
- **node** - Node.js runtime (includes npm)
- **go** - Go programming language