# Every Homebrew tool on every machine, in one file. Language runtimes and their CLIs
# (node, pnpm, python) belong in mise/config.toml, not here.
#
# Add a tool here, then run ./install.sh. Never `brew install` by hand: a tool that is
# only installed, not listed, is missing on the next machine.
#
# One file, not one per machine, on purpose: `brew bundle cleanup --force` resets
# Homebrew's tap trust to what the Brewfile it reads declares. A second file's taps
# would lose their trust, and their formulae would then refuse to load.
#
# To list what is installed but not listed (it removes nothing without --force):
#   brew bundle cleanup --file=~/Code/dotfiles/Brewfile

# The mini is named by its host name; every other machine is a laptop.
# Set DOTFILES_ROLE=mini or DOTFILES_ROLE=laptop to override.
role = ENV.fetch("DOTFILES_ROLE") do
  `scutil --get LocalHostName 2>/dev/null`.strip == "michael-mini" ? "mini" : "laptop"
end
mini = role == "mini"
laptop = role == "laptop"

# ---- Every machine ----------------------------------------------------------------

# Non-official taps need trust. Trust only the formulae used, not the whole tap.
tap "facebook/fb", trusted: { formulae: ["idb", "idb-cli", "idb-companion"] }

brew "cocoapods"
brew "coreutils"
# iOS simulator input. The laptop runs the simulator too, for the cases that need it.
brew "facebook/fb/idb"
# Screen recordings from the iOS simulator skills.
brew "ffmpeg"
brew "gh"
brew "herdr"
brew "mise"
brew "ollama"
brew "starship"

cask "codex"
cask "font-meslo-lg-nerd-font"
cask "ghostty"
cask "orbstack"

# ---- Laptops: development and admin work --------------------------------------------

if laptop
  tap "getsentry/tools", trusted: { formula: "sentry-cli" }

  # franticfanfic admin. Log in to each one by hand on a new machine.
  brew "auth0"
  brew "getsentry/tools/sentry-cli"
  brew "stripe-cli"
  cask "gcloud-cli"

  # Gmail filters, from the life repo.
  brew "gmailctl"
  # pdftotext and pdftoppm, for the ynab and life scripts.
  brew "poppler"

  # General-purpose python3 (see .zshrc), with packages installed into its 3.12.8.
  # Keep it until Python moves to mise, or `brew bundle cleanup --force` breaks python3.
  brew "pyenv"

  # Android builds. .zshrc sets JAVA_HOME and ANDROID_HOME when these are present.
  brew "openjdk@17"
  cask "android-commandlinetools"

  # The app. The mini uses the tailscale formula instead, so that it starts at boot.
  cask "tailscale-app"
end

# ---- michael-mini: the always-on media, finance and model server -----------------
# See ~/Code/homelab/mini-services.md for what each service does.

if mini
  # Starts at boot as a LaunchDaemon, before anyone logs in.
  brew "tailscale"
  # Runs as a brew service. Turning it off stops all downloads.
  brew "transmission-cli"
  brew "smartmontools"
  cask "plex-media-server"

  brew "mas"
  brew "mosh"
  brew "tmux"
  cask "font-hack-nerd-font"

  # The launchd scripts in ~/bin have a minimal PATH with /opt/homebrew/bin and no
  # mise, so they need these from Homebrew. Move them to mise only after those scripts do.
  brew "node"
  brew "python@3.12"
  brew "pillow"

  # The fb-idb client lives in pipx here. Remove pipx after the mini uses the
  # facebook/fb/idb formula above, and ~/.local/bin/idb is gone.
  brew "pipx"
end
