# UI colour tooling

Three commands on top of the existing per-surface family (`tmux-bar`,
`tmux-color`, `tmux-chip`, `tmux-pane`, `tmux-pane-lines`, `tmux-copy`,
`cc-fg`, `cc-fg-dim`, `cc-em`). None of them edit tmux.conf, starship.toml
or the Ghostty config directly — every write goes through the command that
owns that surface, so pinning, theme mirroring and each command's own `-`
history keep working.

The nine surfaces one scheme covers:

| surface           | paints                                                |
|-------------------|-------------------------------------------------------|
| `tmux-bar`        | the bar's frame: row-1 rule/HUD, popup + menu frames, float border |
| `tmux-color`      | written on the bar: inactive windows, rail, date, clock chip |
| `tmux-chip`       | session chip + active window chip (global default)   |
| `tmux-pane`       | pane title pills, pane numbers, clock mode            |
| `tmux-pane-lines` | pane dividers (lit/unlit)                             |
| `tmux-copy`       | copy mode: border, pill, COPY chip, scrollbar, selection |
| `cc-fg`           | Claude Code body text, active pane                    |
| `cc-fg-dim`       | Claude Code body text, inactive panes                 |
| `cc-em`           | Claude Code emphasis — inline code, bold, paths (ANSI blue 4/12) |

## ui-colors — what is everything set to right now

    ui-colors

Read-only. One screen: every surface's BRIGHT hex with a live swatch and
its palette name, the derived DIM (48%) and, for copy mode, the SUNK trough
(20%), this session's `@session_hue`, and the three cc values.

## ui-theme — presets on disk

    ui-theme               list presets (swatch strips, * = current scheme)
    ui-theme save <name>   snapshot the current nine colours
    ui-theme <name>        apply a preset (auto-saves `_previous` first)
    ui-theme -             back to the scheme before the last apply
    ui-theme show <name>   inspect without applying
    ui-theme rm <name>     delete

Presets are the JSON files in this directory, one per name. Applying skips
surfaces already at the target value, and runs `tmux-chip auto` afterwards
so this session's chip goes back to its session-hue colour instead of
staying pinned to the preset's (the preset value stays as the global
default).

## ui-tui — the interactive one

    ui-tui                 (? inside shows help + the current scheme)

Left column: the nine surfaces with their current colour. Right column:
the palette for the selected surface, scraped from that command's own
listing — so cc-fg offers its luminance-banded phosphors/neutrals while
the tmux surfaces offer the saturated pill/tmux set. `*` marks the colour
a surface is currently on.

| key            | does                                                  |
|----------------|-------------------------------------------------------|
| `j`/`k`, arrows| move                                                  |
| `Tab`,`h`,`l`  | switch between surface and palette columns            |
| `Enter`        | apply the highlighted colour to the selected surface  |
| `u`            | undo the selected surface (its own `-`)               |
| `0`            | restore the scheme from when the TUI started          |
| `s`            | save the current scheme as a named preset             |
| `p`            | presets view — `Enter` applies, `x` deletes           |
| `r`            | re-read colours, palettes and presets from disk       |
| `?`            | help + current scheme with swatches                   |
| `q`, `Esc`     | quit                                                  |

Nothing is written until Enter is pressed on a colour or a preset —
startup and navigation only read. On launch the live scheme is snapshotted
to the preset `tui-startup`, so `0` inside the TUI (or `ui-theme
tui-startup` afterwards) always restores what you walked in with.
`tui-startup` is delete-protected inside the TUI.

## Safety nets, newest first

- `tui-startup` — rewritten every time `ui-tui` launches
- `_previous` — rewritten by every `ui-theme` apply; `ui-theme -` uses it
- each surface command's own `-` — per-surface, untouched by all of this
- `keep-20260726` / `cyan-uv` — the scheme as of 2026-07-26
- `tmux/tmux.conf.bak-before-tui-20260726` — raw file copy from the same day
