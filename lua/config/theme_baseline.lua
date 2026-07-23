-- Per-theme baseline colours, kept in their OWN module so :ThemeReload can
-- re-read them fresh from disk (see apply_theme_baseline_colors in theme.lua).
--
-- Why this lives here and not inline in theme.lua: theme.lua is loaded once at
-- nvim startup and its locals are frozen into closures. Editing a hex in an
-- inline table changes the file but not the running session -- :ThemeReload
-- would keep stamping the startup values. This module is dofile()'d on every
-- baseline apply, so edits here take effect on the next :ThemeReload, no
-- restart. Edit the hexes, save, :ThemeReload.
--
-- These are applied ONCE, immediately before the base capture, so they read in
-- as if the colorscheme shipped them. Everything downstream (:FgAdjust, :Sepia,
-- the bg knobs) then transforms them like any other theme colour.
return {
  ["base16-tokyo-night-terminal-storm"] = {
    ["@property.yaml"] = "#717FAB", -- fields (keys)
    ["@punctuation.delimiter.yaml"] = "#ff8c1a", -- colons, commas
    ["@punctuation.special.yaml"] = "#ff8c1a", -- list dashes, anchors
    ["@punctuation.bracket"] = "#f7ff00", -- [] {}
    ["@string.yaml"] = "#00ffff", -- values
    ["@comment"] = "#243745",
    ["Comment"] = "#243745",
  },
}
