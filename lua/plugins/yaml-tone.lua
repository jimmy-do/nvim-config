-- YAML / comment color overrides for base16-tokyo-night-terminal-storm.
-- Edit the hexes below, then: :w | :source % | :YamlTone
--
-- Kept out of theme.lua on purpose: this file is imported after it, so these
-- values land on top of that file's highlight pipeline instead of under it.
local colors = {
  ["@property.yaml"] = "#00ffff", -- fields (keys)
  ["@punctuation.delimiter.yaml"] = "#d18616", -- colons, commas, periods
  ["@punctuation.special.yaml"] = "#d18616", -- list dashes, anchors
  ["@punctuation.bracket"] = "#787c99", -- [] {}
  ["@string.yaml"] = "#41a6b5", -- values
  ["@string.yaml.value.yaml"] = "#41a6b5", -- unquoted values
}

-- Comments are set separately so italic is preserved: nvim_set_hl replaces the
-- whole definition, so passing fg alone would drop base16's italic.
local comment_fg = "#444b6a"

-- The indent guide that lights up on the block under the cursor. theme.lua
-- paints these from the palette cyan (base0C) on every ColorScheme, so this has
-- to run after it to win — hence the deferred apply below. sp is set alongside
-- fg because snacks draws the scope line with an underline-family attribute in
-- some configs, and a stale sp shows through.
local scope_fg = "#7dcfff"
local scope_groups = {
  "SnacksIndentScope",
  "SnacksIndentChunk",
  "IblScope",
  "IndentBlanklineContextChar",
  "IndentBlanklineContextStart",
  "MiniIndentscopeSymbol",
  "BlinkIndentScope",
}

local function apply()
  for group, fg in pairs(colors) do
    pcall(vim.api.nvim_set_hl, 0, group, { fg = fg })
  end
  for _, group in ipairs(scope_groups) do
    pcall(vim.api.nvim_set_hl, 0, group, { fg = scope_fg, sp = scope_fg })
  end
  pcall(vim.api.nvim_set_hl, 0, "@comment", { fg = comment_fg, italic = true })
  pcall(vim.api.nvim_set_hl, 0, "Comment", { fg = comment_fg, italic = true })
end

vim.api.nvim_create_user_command("YamlTone", apply, {})

-- Re-apply on theme load, deferred so it lands after theme.lua's pipeline
-- (which re-runs at 50ms and 200ms after ColorScheme).
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "base16-tokyo-night-terminal-storm",
  callback = function()
    vim.defer_fn(apply, 250)
  end,
})

return {}
