-- Per-delimiter punctuation colours: [] , {} and . each get their own hex.
--
-- WHY THIS IS AN OVERLAY AND NOT A HIGHLIGHT GROUP. Treesitter hands out ONE
-- capture for every bracket glyph in a language -- `[`, `]`, `{`, `}`, `(`, `)`
-- in a yaml buffer are all `@punctuation.bracket.yaml`. Measured 2026-07-30 on
-- `parameters: []`: both cells report that single capture and nothing more
-- specific. So :HlColor (or any :hi) on the capture necessarily repaints every
-- other bracket kind too -- that is the "it colours something else entirely"
-- report, not a bug in the stamping. The only way to split them is matchadd(),
-- which paints by pattern and outranks the capture underneath regardless of the
-- numeric priorities (see the RANKING notes in hi-here.lua).
--
-- COMMENTS ARE LEFT ALONE. Same trick theme.lua's dormant GlobalCommentReset
-- uses: repaint comment-leader -> EOL back to Comment at priority 200, above the
-- three overlays at 95. The leader comes from the buffer's commentstring and
-- must sit at line start or follow whitespace, so a `#` inside a string is not
-- mistaken for a comment. URLs are spared too -- `https://x.io` would otherwise
-- come out speckled with period-coloured dots -- but via a lookbehind in the
-- period pattern rather than a second overlay; see the note on that add() call.
--
-- These groups are stamped on every ColorScheme, so they survive :ThemeReload
-- and theme switches. Retune live with :PunctColor square|curly|period <hex>;
-- edit COLORS below to make it permanent.
--
-- WHY :PunctColor curly LOOKED DEAD (diagnosed 2026-08-01). In a GitHub Actions
-- workflow essentially every brace on screen is part of a `${{ ... }}`, and
-- those braces are NOT painted here -- yaml-expr.lua marks them `YamlExprBrace`
-- with an extmark at priority 220, which beats these matchadd overlays at 95.
-- So the curly knob was working perfectly and repainting a set of glyphs that
-- had none on screen. The brace colour that actually renders lives per-theme in
-- config/theme_baseline.lua under YamlExprBrace (twelve entries, each a quiet
-- per-theme colour -- do NOT unify them onto COLORS.curly, see the bloom note).
--
-- If curly ever looks unresponsive again: check whether the braces you are
-- staring at are inside `${{ }}`, and change YamlExprBrace, not this table.
-- Live equivalent: :HlColorGroup YamlExprBrace #rrggbb.

-- MAX CONTRAST, 2026-08-01. Punctuation is the top of the yaml hierarchy now:
-- keys recede (dark blue, see yaml_key_dark in theme.lua), values sit bright,
-- delimiters shout. Measured against Jimmy's #0f0f0f background, the old set was
-- badly uneven -- curly 17.6:1 but period only 6.8:1 at saturation 47, so the
-- dots read as the DIMMEST thing on a line that was supposed to be the loudest.
--
-- Every hue is held exactly where it was (30 / 62 / 187).
--
-- CONTRAST RATIO IS THE WRONG METRIC HERE (2026-08-01). Optimising these for
-- WCAG contrast produced colours Jimmy read as "glow" -- there is no shader
-- running, so glow just means bright and saturated text. square and curly are
-- DESATURATED from where they were (S 0.90 -> 0.68, 1.00 -> 0.76): more legible,
-- less shouty. period was pushed to #70efff for a 14:1 ratio, read as glow
-- immediately, and is back on its original #41a8b5.
--
-- The real damage was elsewhere: YamlExprBrace was unified onto this yellow
-- across all twelve themes, taking every `${{ }}` brace in a workflow from a
-- quiet lavender to full yellow. Reverted. Do not unify a quiet per-theme group
-- onto a vivid shared one; raise L and hold or lower S.
local COLORS = {
  square = "#ffa852", -- [ ]  was #ff8c1a; S 0.90 -> 0.68, LESS emission than before
  curly = "#f9ff3d", -- { }  was #f7ff00; S 1.00 -> 0.76, LESS emission than before
  period = "#41a8b5", -- .    reverted 2026-08-01: #70efff put V at 1.00 and it bloomed
}

local GROUP = {
  square = "PunctSquare",
  curly = "PunctCurly",
  period = "PunctPeriod",
}

-- Overlays sit at 95; the two "leave it alone" resets ride above them. Nothing
-- here competes with treesitter on numbers -- a match wins either way.
local PRIORITY = { overlay = 95, comment = 200 }

local function stamp_highlights()
  for kind, group in pairs(GROUP) do
    pcall(vim.api.nvim_set_hl, 0, group, { fg = COLORS[kind] })
  end
  -- LINK, not a copied fg: copying captures whatever Comment happened to be
  -- mid-pipeline, which is how the old overlay once painted yaml comments green.
  pcall(vim.api.nvim_set_hl, 0, "PunctCommentReset", { link = "Comment" })
end

-- Only real, editable text. Painting the tree, help buffers or the terminal
-- would be a look change nobody asked for.
local function eligible()
  return vim.bo.buftype == "" and not vim.wo.diff
end

local function clear()
  if type(vim.w.punct_split_ids) == "table" then
    for _, id in ipairs(vim.w.punct_split_ids) do
      pcall(vim.fn.matchdelete, id)
    end
  end
  vim.w.punct_split_ids = nil
end

local function apply()
  clear()
  if not eligible() then
    return
  end
  local ids = {}
  local function add(group, pattern, priority)
    local ok, id = pcall(vim.fn.matchadd, group, pattern, priority)
    if ok then
      table.insert(ids, id)
    end
  end

  add(GROUP.square, [=[\v[\[\]]]=], PRIORITY.overlay) -- long-bracket form: a
  -- plain [[ ]] literal would terminate at the inner ]] and take the file down.
  add(GROUP.curly, [=[\v[{}]]=], PRIORITY.overlay)
  -- Periods, minus the ones inside a URL. The exclusion is in the PATTERN, not a
  -- reset overlay on top: an overlay would have to name a colour to repaint the
  -- URL with, and a cleared group is not a reset -- measured, a match with no
  -- attributes just lets the period overlay underneath show through. The
  -- lookbehind leaves the URL's own capture untouched instead of guessing at it.
  add(GROUP.period, [[\v%(https?://\S*)@<!\.]], PRIORITY.overlay)

  -- commentstring is "# %s" / "-- %s" / "// %s" -- keep the leader, drop the
  -- placeholder and any trailing closer.
  local leaders = {}
  local function add_leader(l)
    l = (l or ""):gsub("%%s.*$", ""):gsub("%s+$", "")
    if l ~= "" then
      leaders[l] = true
    end
  end
  add_leader(vim.bo.commentstring)
  -- Helm's commentstring is the Go-template {{/* %s */}} form, so the yaml '#'
  -- comments that dominate those files need adding by hand.
  if vim.bo.filetype == "helm" then
    add_leader("#")
  end
  for leader in pairs(leaders) do
    local esc = vim.fn.escape(leader, [[\.*$^~[]])
    add("PunctCommentReset", [[\(^\|\s\)\zs]] .. esc .. [[.*$]], PRIORITY.comment)
  end

  vim.w.punct_split_ids = ids
end

-- matchadd is window-local, so every event that can produce a window showing a
-- different buffer has to re-run. Cheap: a handful of matchadd calls.
local group = vim.api.nvim_create_augroup("PunctSplit", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew", "WinEnter", "FileType" }, {
  group = group,
  callback = apply,
})
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function()
    stamp_highlights()
    apply()
  end,
})
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    stamp_highlights()
    -- Windows already exist by VimEnter (session restore, `nvim file`), and only
    -- the current one would get the BufWinEnter above.
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      pcall(vim.api.nvim_win_call, win, apply)
    end
  end,
})

vim.api.nvim_create_user_command("PunctColor", function(opts)
  local kind, hex = opts.fargs[1], opts.fargs[2]
  if not GROUP[kind] then
    vim.notify("PunctColor: expected square | curly | period", vim.log.levels.ERROR)
    return
  end
  if not (hex and hex:match("^#%x%x%x%x%x%x$")) then
    vim.notify("PunctColor: expected #rrggbb, got " .. tostring(hex), vim.log.levels.ERROR)
    return
  end
  COLORS[kind] = hex
  stamp_highlights()
  vim.notify(string.format("PunctColor  %s = %q  (edit punct-split.lua to keep it)", kind, hex))
end, {
  nargs = "+",
  complete = function(_, line)
    return #vim.split(vim.trim(line), "%s+") > 2 and {} or { "square", "curly", "period" }
  end,
  desc = "PunctColor <square|curly|period> <#rrggbb> — retune a delimiter overlay live",
})

stamp_highlights()

return {}
