-- GENERATED FILE -- do not hand-edit, :HlColorSave rewrites it wholesale.
--
-- This is the persistent half of the :HlColor workflow. :HlColor recolours a
-- group in the live session only; :HlColorSave appends whatever is currently
-- overridden into this file under the active colorscheme, so the edit survives
-- restarts. :HlColorForget removes entries again.
--
-- Precedence, from load_theme_baseline_colors in plugins/theme.lua:
--   derived yaml palette  ->  theme_baseline.lua (hand-tuned)  ->  THIS FILE
-- i.e. a saved edit wins over the hand table for the same group, because it is
-- by definition the more recent deliberate decision. Delete a group here and the
-- hand-tuned value underneath comes straight back.
--
-- Everything in here is a pipeline INPUT, exactly like theme_baseline.lua: the
-- hexes are stamped before the base capture, so :FgAdjust, :Sepia and the bg
-- knobs keep transforming them like any other theme colour.
return {
  ["base16-everforest-dark-hard"] = {
    ["YamlExprOp"] = "#e69875",
  },
  ["base16-gruvbox-material-dark-hard"] = {
    ["@string.special.image.yaml"] = "#d28453",
  },
  ["base16-hardhacker"] = {
    ["@punctuation.special.yaml"] = "#ff3b3b",
    ["@string.special.symbol.yaml"] = "#fdcce0",
    ["@variable.parameter.bash"] = "#ebde76",
    ["FlashLabel"] = "#ff9d40",
    ["YamlExprContext"] = "#ebde76",
    ["YamlExprOp"] = "#ff9d40",
    ["YamlExprProp"] = "#fdcce0",
  },
  ["base16-jabuti"] = {
    ["@variable.parameter.bash"] = "#3fdaa4",
    ["YamlExprContext"] = "#ff9b69",
    ["YamlExprProp"] = "#8ebbff",
  },
  ["base16-moonlight"] = {
    ["@variable.parameter.bash"] = "#bcebe8",
    ["YamlExprContext"] = "#bcebe8",
    ["YamlExprOp"] = "#9fefff",
  },
  ["base16-tokyo-night-storm"] = {
    ["YamlExprOp"] = "#ff5b8a",
  },
  ["icyv2"] = {
    ["@variable.parameter.bash"] = "#03fc45",
    ["YamlExprProp"] = "#ff3b3b",
  },
  ["moonlightv4"] = {
    ["@string.special.image.yaml"] = "#ff8486",
    ["@string.special.symbol.yaml"] = "#f45eff",
    ["@variable.parameter.bash"] = "#73d0ff",
    ["YamlExprContext"] = "#73d0ff",
    ["YamlExprOp"] = "#ff8486",
    ["YamlExprProp"] = "#f7998d",
    ["YamlExprStr"] = "#f45eff",
  },
  ["moonlightv5"] = {
    ["@boolean.yaml"] = "#ff5370",
    ["@function.call.bash"] = "#33ff33",
    ["@property.yaml"] = "#000000",
    ["@string.special.image.yaml"] = "#ff5e7a",
    ["@string.special.symbol.yaml"] = "#3d8bff",
    ["@string.special.url.yaml"] = "#ff9b69",
    ["@string.yaml"] = "#00ffff",
    ["@variable.parameter.bash"] = "#33ff33",
    ["YamlExprContext"] = "#ff5e7a",
    ["YamlExprOp"] = "#ff33cc",
    ["YamlExprProp"] = "#b14dff",
    ["YamlExprSigil"] = "#ff33cc",
  },
  ["moonlit"] = {
    ["@boolean.yaml"] = "#ff5ec4",
    ["@punctuation.delimiter.yaml"] = "#00ffff",
    ["@punctuation.special.yaml"] = "#00ffff",
    ["@string.special.image.yaml"] = "#bcebe8",
    ["@string.special.path.yaml"] = "#bcebe8",
    ["@string.special.symbol.yaml"] = "#9fefff",
    ["@string.special.url.yaml"] = "#ee5f83",
    ["@string.special.version.yaml"] = "#ff5ec4",
    ["@string.yaml"] = "#41f1be",
    ["@variable.parameter.bash"] = "#bcebe8",
    ["YamlExprContext"] = "#bcebe8",
    ["YamlExprOp"] = "#d6fdff",
    ["YamlExprProp"] = "#cacafc",
    ["YamlExprStr"] = "#9fefff",
  },
  ["nvim-gruvbox"] = {
    ["@boolean.yaml"] = "#ffb3ec",
    ["@function.call.bash"] = "#ffff4d",
    ["@punctuation.delimiter.yaml"] = "#66fff2",
    ["@punctuation.special.yaml"] = "#66fff2",
    ["@string.special.image.yaml"] = "#96ff61",
    ["@string.special.symbol.yaml"] = "#ffff4d",
    ["@string.special.url.yaml"] = "#c98bff",
    ["@string.special.version.yaml"] = "#ff5e7a",
    ["@string.yaml"] = "#ff6329",
    ["@type.yaml"] = "#3390ff",
    ["@variable.parameter.bash"] = "#96ff61",
    ["PunctCurly"] = "#ffa852",
    ["YamlExprContext"] = "#9fefff",
    ["YamlExprOp"] = "#9fefff",
    ["YamlExprProp"] = "#d3869b",
    ["YamlExprSigil"] = "#00ffff",
    ["YamlExprStr"] = "#96ff61",
  },
  ["palenightv2"] = {
    ["@boolean.yaml"] = "#ffff4d",
    ["@function.call.bash"] = "#ff8c9f",
    ["@punctuation.delimiter.yaml"] = "#00d5ff",
    ["@string.special.condition.yaml"] = "#3390ff",
    ["@string.special.image.yaml"] = "#3390ff",
    ["@string.special.path.yaml"] = "#00ffff",
    ["@string.special.symbol.yaml"] = "#ff8c9f",
    ["@string.special.url.yaml"] = "#84fc03",
    ["@string.yaml"] = "#03fc45",
    ["@type.yaml"] = "#2194ff",
    ["@variable.parameter.bash"] = "#00ffff",
    ["YamlExprSigil"] = "#00ffff",
    ["YamlExprStr"] = "#84fc03",
  },
}

