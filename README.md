# Neovim Config

Personal LazyVim-based Neovim configuration for local development and temporary Linux lab environments.

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

## Platform Notes

- The Neovim and tmux configurations work on macOS, Linux, and WSL2.
- In WSL2, install Neovim, tmux, Git, and TPM inside the WSL distribution.
- Configure the Nerd Font in the Windows terminal application hosting WSL2.
- The Ghostty configuration is not included in this repository.
- Ghostty-specific macOS `Cmd` keybindings do not apply to WSL2 terminals.

## Notes

- Built on LazyVim
- Uses lazy.nvim for plugin management
- `lazy-lock.json` is committed to keep plugin versions reproducible
- Intended for local development and temporary playground environments
