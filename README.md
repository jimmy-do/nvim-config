# Neovim Config

Personal LazyVim-based Neovim configuration for local development and temporary Linux lab environments.

## Install

```bash
rm -rf ~/.config/nvim
git clone https://github.com/jimmy-do/nvim-config.git ~/.config/nvim
nvim
```

## Notes

- Built on LazyVim
- Uses lazy.nvim for plugin management
- `lazy-lock.json` is committed to keep plugin versions reproducible
- Intended for local development and temporary playground environments

## Optional Tmux Config

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
