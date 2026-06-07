# Neovim Config

Personal LazyVim-based Neovim configuration for local development and temporary Linux lab environments.

This `macos-dotfiles` branch adds the current Ghostty and Karabiner-Elements
configuration. Use `main` for the cross-platform Neovim/tmux-only setup.

## Supported Environments

- macOS
- Native Linux
- WSL2

For WSL2, install everything inside the Linux home directory. Use
`~/.config/nvim`, not a Windows-mounted path such as `/mnt/c/...`.

## Prerequisites

- Neovim
- Git
- tmux for the optional tmux configuration
- A Nerd Font configured in the host terminal
- Optional command-line tools used by status integrations, such as `kubectl`

## Install Neovim

The repository is a Neovim configuration, so clone it directly into
`~/.config/nvim`:

```bash
rm -rf ~/.config/nvim
git clone https://github.com/jimmy-do/nvim-config.git ~/.config/nvim
nvim
```

## Install Tmux

The repository also includes the matching tmux configuration under
`dotfiles/tmux/`. It remains separate from the Neovim root so cloning this
repository directly into `~/.config/nvim` continues to work.

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
mkdir -p ~/.config/tmux
ln -s ~/.config/nvim/dotfiles/tmux/tmux.conf ~/.tmux.conf
ln -s ~/.config/nvim/dotfiles/tmux/mode-dots-loop ~/.config/tmux/mode-dots-loop
tmux source-file ~/.tmux.conf
```

The status bar uses Nerd Font glyphs. The animated `WAIT`/`COPY` indicator runs
only while a tmux prefix or copy mode is active.

## Install macOS Dotfiles

The macOS-only files are stored under `dotfiles/macos/`:

- `dotfiles/macos/ghostty/config.ghostty`
- `dotfiles/macos/karabiner/karabiner.json`

Clone this branch when setting up a Mac:

```bash
rm -rf ~/.config/nvim
git clone --branch macos-dotfiles \
  https://github.com/jimmy-do/nvim-config.git ~/.config/nvim
```

Back up any existing configurations, then create symlinks:

```bash
mkdir -p ~/.config/karabiner
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"

test ! -e ~/.config/karabiner/karabiner.json ||
  mv ~/.config/karabiner/karabiner.json \
    ~/.config/karabiner/karabiner.json.backup

test ! -e "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" ||
  mv "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty.backup"

ln -s ~/.config/nvim/dotfiles/macos/karabiner/karabiner.json \
  ~/.config/karabiner/karabiner.json

ln -s ~/.config/nvim/dotfiles/macos/ghostty/config.ghostty \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
```

Quit and reopen Karabiner-Elements after linking its configuration. Reload
Ghostty with `Cmd+Shift+,` or restart it.

See [dotfiles/macos/README.md](dotfiles/macos/README.md) for macOS-specific
requirements and hardware notes.

## Platform Notes

- The Neovim and tmux configurations work on macOS, Linux, and WSL2.
- In WSL2, install Neovim, tmux, Git, and TPM inside the WSL distribution.
- Configure the Nerd Font in the Windows terminal application hosting WSL2.
- Ghostty and Karabiner are included only on the `macos-dotfiles` branch.
- Ghostty-specific macOS `Cmd` keybindings do not apply to WSL2 terminals.

## Notes

- Built on LazyVim
- Uses lazy.nvim for plugin management
- `lazy-lock.json` is committed to keep plugin versions reproducible
- Intended for local development and temporary playground environments
