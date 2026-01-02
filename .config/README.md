# .config directory

This directory contains XDG Base Directory compliant configuration files.

## Structure

Modern applications often store their configuration in `~/.config/` following the XDG Base Directory specification.

Place application-specific configurations in subdirectories here, for example:
- `~/.config/git/` - Git configuration
- `~/.config/nvim/` - Neovim configuration
- `~/.config/tmux/` - Tmux configuration

## Symlinking

The install script will automatically create symlinks for any directories in this folder to `~/.config/` in your home directory.
