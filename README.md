# Homebrew Orca

Homebrew tap for [Orca](https://github.com/stablyai/orca) — an IDE for orchestrating AI coding agents.

## Install

### macOS

```bash
brew install --cask stablyai/orca/orca
```

### Linux (x86_64 and ARM64)

```bash
brew install --formula stablyai/orca/orca
orca-ide --help
```

The formula installs the official stable AppImage into the Homebrew Cellar and
extracts it at install time, so FUSE and root installation are not required.
The CLI is named `orca-ide` to avoid conflicting with the GNOME Orca screen reader.
The macOS casks, including `orca@rc`, remain separate; the Linux formula tracks
stable releases only.

Install Electron's runtime libraries using your distribution's package manager.
For Ubuntu 24.04:

```bash
sudo apt-get install libgtk-3-0t64 libnss3 libasound2t64 libgbm1 libxss1 libxtst6 libnotify4 libsecret-1-0 libatspi2.0-0t64
```

For Orca's computer-use tools and headless browser panes, also install:

```bash
sudo apt-get install python3 python3-gi gir1.2-atspi-2.0 at-spi2-core xdotool xclip xvfb
```

The GUI requires a graphical session and Chromium's sandbox support through
unprivileged user namespaces. Distribution security policies may require an
administrator to allow the installed executable; the formula does not disable
the sandbox or install a root-owned setuid helper.

Launch the GUI with `"$(brew --prefix stablyai/orca/orca)/libexec/orca-ide"`.
To show Orca in your desktop application launcher:

```bash
mkdir -p ~/.local/share/applications
ln -sfn "$(brew --prefix)/share/applications/orca-ide.desktop" ~/.local/share/applications/orca-ide.desktop
```

## Updates

On macOS, Orca updates itself in place via its built-in updater. `brew upgrade`
is a no-op unless you pass `--greedy`. `brew uninstall --cask orca` works normally.

On Linux, the extracted AppImage has no `APPIMAGE` runtime identity, so use
Homebrew to update and uninstall it:

```bash
brew upgrade --formula stablyai/orca/orca
brew uninstall --formula stablyai/orca/orca
```

Uninstalling the Linux formula preserves user data such as `~/.orca`.

## About this repo

This tap's release definitions are generated automatically from
[stablyai/orca](https://github.com/stablyai/orca). The templates live in `Casks/`
and `Formula/` in that repo and are published by `.github/workflows/homebrew-bump.yml`.
Changes to generated definitions must also be made in the source templates.
