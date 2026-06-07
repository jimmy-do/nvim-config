# macOS Dotfiles

This directory contains the macOS-only portion of the dotfiles:

- Ghostty terminal configuration
- Karabiner-Elements keyboard remapping

## Requirements

- macOS
- Ghostty
- Karabiner-Elements
- JetBrainsMono Nerd Font
- tmux configuration from `dotfiles/tmux/`

The Ghostty `Cmd+H/J/K/L` mappings send custom terminal sequences consumed by
the included tmux configuration. The Karabiner rules also provide:

- `Caps Lock`: tap for Escape, hold for Control
- Right Command + `H/J/K/L`: global arrow keys
- Ghostty left Command + `H`: tmux-compatible remapping
- Firefox left Command + `J/K`: disabled to avoid shortcut conflicts

## Hardware-specific Karabiner Settings

The committed Karabiner profile retains the current device vendor and product
IDs. They are not credentials, but they are specific to the keyboards used when
the file was exported.

On another Mac, review the `devices` array in `karabiner.json`. Remove or update
entries that do not match that Mac's hardware, especially settings that disable
the built-in keyboard while an external keyboard is connected.

## Updating the Export

After changing the live macOS configurations, refresh the repository copies:

```bash
cp ~/.config/karabiner/karabiner.json \
  ~/.config/nvim/dotfiles/macos/karabiner/karabiner.json

cp "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" \
  ~/.config/nvim/dotfiles/macos/ghostty/config.ghostty
```

Do not commit generated backups such as `karabiner.json.bak.*` or
`config.ghostty.backup.*`.
