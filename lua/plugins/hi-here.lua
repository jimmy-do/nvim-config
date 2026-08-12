-- :HiHere — the winning highlight at the cursor, as one line.
--
--   :HiHere      @string.yaml  guifg=#41a8b5          (and #41a8b5 → + register)
--   :HiHere!     the full ranked stack, winner last
--
-- Why this exists on top of :Inspect. Two reasons:
--
--  1. :Inspect prints the whole stack and stops short of the answer — it shows
--     you `@string.yaml` linked to `String` linked to `Identifier` and leaves the
--     chase to you. :hi is worse: it is a listing command with no idea where the
--     cursor is, and `:hi Foo` reports the link rather than the resolved hex.
--
--  2. :Inspect DOES NOT SEE matchadd() overlays. theme.lua paints periods,
--     {{ }} / [[ ]] and comment regions with matchadd (GlobalPunctBlue,
--     GlobalPunctBracket, GlobalUrlReset, GlobalCommentReset) at priorities
--     95/96/200 — and matchadd outranks the treesitter capture underneath. So on
--     a `.` in a storm-family buffer :Inspect confidently names a treesitter
--     group that is NOT the colour on screen. This command reads getmatches()
--     and ranks it against everything else — see RANKING below.
--
-- RANKING. Two separate layers, not one priority scale:
--
--   * decorations — syntax, treesitter, LSP semantic tokens, extmarks — DO
--     compete on the numeric priority they carry (defaults below).
--   * matchadd() sits ON TOP of all of them, whatever the numbers say. Its
--     priority only orders matches against each other.
--
-- Measured 2026-07-28 rather than assumed, because the numbers invite the wrong
-- guess: in stormv2, GlobalPunctBracket is priority 95 and the @string.yaml.quoted
-- capture under it is 100, so a naive scale says treesitter wins. A tmux
-- capture-pane of `tpl: "{{ .Values.name }}"` renders the braces 247;255;0 =
-- #f7ff00 (the overlay) and the periods 255;140;26 = #ff8c1a, NOT the capture's
-- #41a6b5. The match wins at a lower number. theme.lua's comment on the
-- GlobalCommentReset matchadd reads "priority 200, above treesitter 100" — the
-- effect is right (200 beats the other matches at 95/96) but the stated reason
-- is not; nothing at any number would have let treesitter through.
--
-- Caveat this command does not model: match attrs COMBINE with what is under
-- them (hl_combine_attr), so a match that sets only guifg leaves the guibg
-- below it showing. The fg — the thing you are asking for — is the overridden
-- one, so the headline answer is right; a reported guibg may come from a lower
-- layer. `:HiHere!` shows you that layer.
local DEFAULT_PRIORITY = {
  syntax = 0,
  match = 10,
  treesitter = 100,
  semantic_token = 125,
  extmark = 4096,
}

-- Layer, not priority. Everything below MATCH_TIER compares on priority; matches
-- outrank the lot.
local DECOR_TIER, MATCH_TIER = 1, 2

local function hex(n)
  return type(n) == "number" and string.format("#%06x", n) or nil
end

-- Resolve a group name to the attributes actually rendered. `link = false` is the
-- whole point: it walks the link chain so a group that only says "links to
-- String" still comes back with String's fg.
local function resolve(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  return ok and hl or {}
end

-- matchadd() patterns, tested against the cursor line. getmatches() gives the
-- pattern back, not the spans, so re-run it over the line and see which span the
-- cursor lands in. matchstrpos honours \zs / \ze, which GlobalCommentReset needs
-- (its leader pattern uses \zs to start the region AT the comment leader).
local function match_candidates(line, byte_col)
  local out = {}
  for _, m in ipairs(vim.fn.getmatches()) do
    local priority = m.priority or DEFAULT_PRIORITY.match
    if m.pattern and m.pattern ~= "" then
      local from = 0
      while true do
        -- Returns { text, start, end } with 0-based byte offsets; start is -1
        -- when nothing is left to find.
        local found = vim.fn.matchstrpos(line, m.pattern, from)
        local s, e = found[2], found[3]
        if s < 0 or e <= s then
          break
        end
        if byte_col > s and byte_col <= e then
          table.insert(out, { group = m.group, priority = priority, source = "match", tier = MATCH_TIER })
          break
        end
        from = e
      end
    else
      -- matchaddpos() form: pos1..posN, each {line}, {line, col} or
      -- {line, col, len}. Nothing in this config uses it, but it is cheap.
      for i = 1, 8 do
        local pos = m["pos" .. i]
        if not pos then
          break
        end
        local prow = pos[1]
        local pcol, plen = pos[2], pos[3] or 1
        local hit = prow == vim.fn.line(".")
          and (not pcol or (byte_col >= pcol and byte_col < pcol + plen))
        if hit then
          table.insert(out, { group = m.group, priority = priority, source = "match", tier = MATCH_TIER })
          break
        end
      end
    end
  end
  return out
end

-- Everything :Inspect knows about: treesitter captures, LSP semantic tokens,
-- legacy :syntax, and extmarks.
local function inspect_candidates(row, col)
  local ok, info = pcall(vim.inspect_pos, 0, row, col)
  if not ok or type(info) ~= "table" then
    return {}
  end
  local out = {}
  for _, item in ipairs(info.syntax or {}) do
    table.insert(out, {
      group = item.hl_group_link or item.hl_group,
      priority = DEFAULT_PRIORITY.syntax,
      source = "syntax",
      tier = DECOR_TIER,
    })
  end
  for _, item in ipairs(info.treesitter or {}) do
    table.insert(out, {
      group = item.hl_group,
      priority = item.priority or DEFAULT_PRIORITY.treesitter,
      source = "treesitter",
      tier = DECOR_TIER,
    })
  end
  for _, item in ipairs(info.semantic_tokens or {}) do
    local opts = item.opts or {}
    table.insert(out, {
      group = opts.hl_group,
      priority = opts.priority or DEFAULT_PRIORITY.semantic_token,
      source = "semantic",
      tier = DECOR_TIER,
    })
  end
  for _, item in ipairs(info.extmarks or {}) do
    local opts = item.opts or {}
    table.insert(out, {
      group = opts.hl_group,
      priority = opts.priority or DEFAULT_PRIORITY.extmark,
      source = "extmark",
      tier = DECOR_TIER,
    })
  end

  -- EPHEMERAL extmarks are invisible to vim.inspect_pos. yaml-key-depth paints
  -- the key rungs (YamlKeyD1..D8) from an on_win decoration provider, so they
  -- exist only for the duration of a redraw and the loop above reports NO
  -- extmarks at all on a yaml key. :HiHere therefore answered with the
  -- treesitter group underneath -- @property.yaml, a colour nothing on screen is
  -- using -- and put THAT hex on the clipboard.
  --
  -- theme.lua's :HlColor resolver already asks the painter directly for exactly
  -- this reason (see its comment at the __yaml_key_depth_group_at call). Two
  -- resolvers with one of them wrong is how :HiHere and :HlColor came to
  -- disagree about the same cell. Ranked at the priority the rungs really use
  -- (200), which puts it above the captures and below the matchadd overlays --
  -- the same slot theme.lua gives it.
  --
  -- Only became visible in helm buffers on 2026-08-06: before the parser fix
  -- nothing was painted there, so the treesitter group WAS the truth. In plain
  -- yaml this had been wrong all along.
  if type(_G.__yaml_key_depth_group_at) == "function" then
    local ok_rung, rung = pcall(_G.__yaml_key_depth_group_at, 0, row, col)
    if ok_rung and rung then
      table.insert(out, { group = rung, priority = 200, source = "keydepth", tier = DECOR_TIER })
    end
  end

  return out
end

local function candidates_at_cursor()
  local win_row, win_col = unpack(vim.api.nvim_win_get_cursor(0))
  local row, col = win_row - 1, win_col -- 0-based for inspect_pos
  local line = vim.api.nvim_get_current_line()

  local out = {}
  vim.list_extend(out, inspect_candidates(row, col))
  -- matchstrpos offsets are 0-based and exclusive at the end, and the cursor
  -- byte is 0-based too — compare as 1-based so a span [s,e) covers cols s+1..e.
  vim.list_extend(out, match_candidates(line, col + 1))

  -- Sort weakest → strongest: tier first (matches always on top), then priority,
  -- then insertion order so ties break toward whatever was added later. Record
  -- the index first — table.sort is not stable on its own.
  for i, c in ipairs(out) do
    c.order = i
  end
  table.sort(out, function(a, b)
    if a.tier ~= b.tier then
      return a.tier < b.tier
    end
    if a.priority ~= b.priority then
      return a.priority < b.priority
    end
    return a.order < b.order
  end)
  return out
end

-- "guifg=#41a8b5 guibg=#0f0f0f bold" — only what is actually set.
local function describe(group)
  local hl = resolve(group)
  local parts = {}
  local fg = hex(hl.fg)
  if fg then
    table.insert(parts, "guifg=" .. fg)
  end
  local bg = hex(hl.bg)
  if bg then
    table.insert(parts, "guibg=" .. bg)
  end
  for _, attr in ipairs({ "bold", "italic", "underline", "undercurl", "reverse", "nocombine" }) do
    if hl[attr] then
      table.insert(parts, attr)
    end
  end
  if #parts == 0 then
    table.insert(parts, "cleared")
  end
  return table.concat(parts, " "), fg
end

-- setreg("+") alone is not enough: inside tmux the clipboard provider falls back
-- to OSC 52, which the float swallows. pbcopy is the only thing that reliably
-- lands in the system clipboard, so do both.
local function clip(text)
  vim.fn.setreg("+", text)
  if vim.fn.executable("pbcopy") == 1 then
    vim.system({ "pbcopy" }, { stdin = text })
  end
end

local function hi_here(opts)
  local list = candidates_at_cursor()
  if #list == 0 then
    vim.notify("HiHere: nothing highlighting the cursor (Normal)", vim.log.levels.WARN)
    return
  end

  if opts.bang then
    -- Full stack, weakest first, so the winner is the last line you read.
    local lines = {}
    for _, c in ipairs(list) do
      table.insert(
        lines,
        string.format("%-10s %4d  %-34s %s", c.source, c.priority, c.group, (describe(c.group)))
      )
    end
    -- Still copy the winner's hex — the stack is where you are hunting for it.
    local _, wfg = describe(list[#list].group)
    if wfg then
      clip(wfg)
    end
    vim.notify(table.concat(lines, "\n"))
    return
  end

  local winner = list[#list]
  local attrs, fg = describe(winner.group)
  if fg then
    clip(fg)
  end
  vim.notify(string.format("%s  %s  [%s]%s", winner.group, attrs, winner.source, fg and "  → clipboard" or ""))
end

vim.api.nvim_create_user_command("HiHere", hi_here, {
  bang = true,
  desc = "Winning highlight group + hex at the cursor (! for the full stack)",
})

-- Lowercase aliases. User commands are required to start with a capital, so the
-- only way to type `:inspect` / `:hihere` is a cmdline abbreviation. Guard on
-- getcmdtype() == ":" and getcmdline() being nothing but the word itself, so the
-- expansion cannot fire inside `:%s/inspect/x/` or an argument.
local function cmd_alias(short, long)
  vim.keymap.set("ca", short, function()
    local at_start = vim.fn.getcmdtype() == ":" and vim.fn.getcmdline():match("^%s*" .. short .. "$")
    return at_start and long or short
  end, { expr = true })
end

cmd_alias("inspect", "Inspect")
cmd_alias("hihere", "HiHere")

-- Nothing to install; this file is here for the user command only.
return {}
