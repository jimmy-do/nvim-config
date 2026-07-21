-- YAML / comment color overrides for base16-tokyo-night-terminal-storm.
-- Edit the hexes below, then: :w | :source % | :YamlTone
--
-- Kept out of theme.lua on purpose: this file is imported after it, so these
-- values land on top of that file's highlight pipeline instead of under it.
local colors = {
  ["@property.yaml"] = "#717FAB", -- fields (keys)
  ["@punctuation.delimiter.yaml"] = "#ff8c1a", -- colons, commas, periods
  ["@punctuation.special.yaml"] = "#ff8c1a", -- list dashes, anchors
  ["@punctuation.bracket"] = "#f7ff00", -- [] {}
  ["@string.yaml"] = "#00ffff", -- values
  ["@string.yaml.value.yaml"] = "#00ffff", -- unquoted values
}

-- Comments are set separately so italic is preserved: nvim_set_hl replaces the
-- whole definition, so passing fg alone would drop base16's italic.
local comment_fg = "#243745"

-- Every period in the buffer, in every filetype -- inside strings, unquoted
-- values, code, anywhere. This is a matchadd() overlay rather than a highlight
-- group because no treesitter capture covers "a period inside a string": the
-- string is one node, and a window match paints over it regardless.
--
-- Independent of @punctuation.delimiter.yaml above: that one colors YAML's
-- structural colons/commas, this one colors periods everywhere. Set them to
-- the same value if you ever want them to agree.
--
-- Set to nil to turn the overlay off entirely.
local period_fg = "#ff8c1a"

-- The indent guide that lights up on the block under the cursor. theme.lua
-- paints these from the palette cyan (base0C) on every ColorScheme, so this has
-- to run after it to win — hence the deferred apply below. sp is set alongside
-- fg because snacks draws the scope line with an underline-family attribute in
-- some configs, and a stale sp shows through.
local scope_fg = "#00ffff"
local scope_groups = {
  "SnacksIndentScope",
  "SnacksIndentChunk",
  "IblScope",
  "IndentBlanklineContextChar",
  "IndentBlanklineContextStart",
  "MiniIndentscopeSymbol",
  "BlinkIndentScope",
}

-- Single gate for the whole file. Every entry point checks this, so nothing
-- here touches any colorscheme but storm.
local THEME = "base16-tokyo-night-terminal-storm"

local function active()
  return (vim.g.colors_name or "") == THEME
end

local function apply()
  if not active() then
    return
  end
  for group, fg in pairs(colors) do
    pcall(vim.api.nvim_set_hl, 0, group, { fg = fg })
  end
  for _, group in ipairs(scope_groups) do
    pcall(vim.api.nvim_set_hl, 0, group, { fg = scope_fg, sp = scope_fg })
  end
  pcall(vim.api.nvim_set_hl, 0, "@comment", { fg = comment_fg, italic = true })
  pcall(vim.api.nvim_set_hl, 0, "Comment", { fg = comment_fg, italic = true })
end

-- ── Global period overlay ───────────────────────────────────────────────────
-- Priorities are the same scale theme.lua uses (treesitter 100, LSP semantic
-- tokens 125):
--   95  every period
--   96  URLs repaint back to normal, so https://... keeps one color
--   200 comment leader → EOL repaints back to Comment, so periods inside a
--       comment are excluded, as asked.
local function clear_period_matches()
  if type(vim.w.yaml_tone_period_ids) == "table" then
    for _, id in ipairs(vim.w.yaml_tone_period_ids) do
      pcall(vim.fn.matchdelete, id)
    end
  end
  vim.w.yaml_tone_period_ids = nil
end

local function apply_period_matches()
  -- Cleared unconditionally, then re-added only on storm: switching away from
  -- storm must take the overlay's existing window matches down with it.
  clear_period_matches()
  if not period_fg or not active() then
    return
  end
  -- Linked, not copied: resolves to Comment's live color, so the exclusion
  -- keeps working after any theme or comment_fg change.
  pcall(vim.api.nvim_set_hl, 0, "YamlTonePeriodCommentReset", { link = "Comment" })
  pcall(vim.api.nvim_set_hl, 0, "YamlTonePeriodUrlReset", { link = "Normal" })
  pcall(vim.api.nvim_set_hl, 0, "YamlTonePeriod", { fg = period_fg })

  local ids = {}
  local function add(group, pattern, priority)
    local ok, id = pcall(vim.fn.matchadd, group, pattern, priority)
    if ok then
      table.insert(ids, id)
    end
  end

  add("YamlTonePeriod", [[\v\.]], 95)
  add("YamlTonePeriodUrlReset", [[\vhttps?://\S+]], 96)

  -- Comment leader → EOL, derived from the buffer's own commentstring so this
  -- works per filetype. The leader must start the line or follow whitespace, so
  -- a '#' inside a string is not mistaken for a comment.
  local leader = (vim.bo.commentstring or ""):gsub("%%s.*$", ""):gsub("%s+$", "")
  if leader ~= "" then
    local esc = vim.fn.escape(leader, [[\.*$^~[]])
    add("YamlTonePeriodCommentReset", [[\(^\|\s\)\zs]] .. esc .. [[.*$]], 200)
  end

  vim.w.yaml_tone_period_ids = ids
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType" }, {
  pattern = "*",
  callback = apply_period_matches,
})

vim.api.nvim_create_user_command("YamlTone", function()
  if not active() then
    vim.notify("YamlTone: only applies to " .. THEME, vim.log.levels.WARN)
    return
  end
  apply()
  apply_period_matches()
end, {})

-- Re-apply on theme load, deferred so it lands after theme.lua's pipeline
-- (which re-runs at 50ms and 200ms after ColorScheme).
-- theme.lua fires this once its pipeline settles (400ms). Knob commands like
-- :FgAdjust re-run that pipeline without changing the colorscheme, which
-- repaints Comment from the captured theme base and drops comment_fg -- this is
-- what puts it back.
vim.api.nvim_create_autocmd("User", {
  pattern = "ThemeAdjusted",
  callback = function()
    apply()
    apply_period_matches()
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "base16-tokyo-night-terminal-storm",
  callback = function()
    vim.defer_fn(apply, 250)
  end,
})

return {}
