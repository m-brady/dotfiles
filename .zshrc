eval "$(starship init zsh)"
export PATH="/Users/michaelbrady/.bun/bin:$PATH"
alias gemini="bunx --package @google/gemini-cli gemini"

# opencode
export PATH=/Users/michaelbrady/.opencode/bin:$PATH

alias cc="claude"

# GNU coreutils (timeout, etc.)
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# bun completions
[ -s "/Users/michaelbrady/.bun/_bun" ] && source "/Users/michaelbrady/.bun/_bun"

alias cw="claude --worktree"
