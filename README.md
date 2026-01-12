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
  - `setup-shell.sh` - Adds `~/.local/bin` to PATH
  - `bootstrap.sh` - One-command setup for fresh machines

## Manual Steps

After running the scripts:

1. Restart your shell or run `source ~/.zshrc` (or equivalent)
2. Run `claude` to authenticate and complete setup
3. Configure your preferred settings with `/config` in Claude Code