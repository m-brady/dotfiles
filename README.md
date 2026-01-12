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
  - `setup-claude-config.sh` - Installs safe command allowlist configuration
  - `.claude/settings.json` - Pre-configured permissions for common dev tools
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

## Claude Code Configuration

The included `.claude/settings.json` provides a safe allowlist of common development commands that Claude Code can run without prompting. This includes:

**Version Control:**
- Git operations (status, diff, commit, push, branch, merge, etc.)
- GitHub CLI (gh) commands

**Package Managers:**
- npm/npx commands (install, run, test, build)
- bun commands (install, add, run, test)
- go commands (build, run, test, mod)
- cargo, pip, and other language tools

**Development Tools:**
- mise tool version management
- Docker and docker-compose commands
- Build tools (make)

**File Operations:**
- Safe file operations (ls, mkdir, mv, cp, cat, touch)
- Navigation (cd, pwd)

**System Commands:**
- Environment inspection (env, printenv, whoami)
- Network tools (curl, wget)

The configuration is automatically installed to `~/.claude/settings.json` during bootstrap. You can customize it later by editing that file directly.

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