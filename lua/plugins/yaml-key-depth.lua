-- yaml-key-depth.lua — per-depth colour for yaml keys BELOW depth 2.
--
-- ---------------------------------------------------------------------------
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------
-- after/queries/yaml/highlights.scm captures exactly two depths:
-- @property.yaml.toplevel (document root) and @property.yaml.level2. Its own
-- comment states the limit -- "Depth 3 and deeper do not match and keep plain
-- @property.yaml". So the key ramp in theme.lua had three rungs to paint and a
-- file like a k8s manifest or an Actions workflow spends most of its lines at
-- depth 4+, all of them on one hex.
--
-- That is why :YamlKeyColor <hex> looked like it stamped ONE STATIC COLOUR on
-- every key. It wasn't broken -- it was ramping correctly across three rungs in
-- a file that is mostly deeper than three.
--
-- Tree-sitter queries cannot count, so depth cannot come from the .scm at all
-- without writing one explicit pattern per level -- and one per level per
-- mapping/sequence combination, which is 2^(n-1) patterns and still capped.
-- Depth comes from the tree instead:
--
--   DEPTH = number of block_mapping_pair ancestors of the KEY node
--
-- The key's own enclosing pair is one of those ancestors, which is where the
-- count comes from -- walking up from the pair node instead needs a +1 and it is
-- the easy off-by-one here (it put `jobs:` at depth 2 on the first pass).
--
-- Measured against the real grammar (2026-07-29), which is why this is exact
-- and not an indent heuristic:
--
--   jobs:          1 pair ancestor  -> depth 1
--     terraform:   2                -> depth 2
--       steps:     3                -> depth 3
--         - name:  4                -> depth 4   (sequence item costs a level,
--           with:  4                -> depth 4    same as the eye reads it)
--             fetch: 5              -> depth 5
--
-- Counting pair ancestors gets block_sequence_item nesting for free -- there is
-- no separate case for list items, which is the thing that makes the query
-- approach explode.
--
-- ---------------------------------------------------------------------------
-- WHAT IT PAINTS, AND WHAT IT DELIBERATELY DOES NOT
-- ---------------------------------------------------------------------------
-- Only depth >= 4. Depths 1-3 are left entirely alone:
--   depth 1 -> @property.yaml.toplevel   (query)
--   depth 2 -> @property.yaml.level2     (query)
--   depth 3 -> @property.yaml            (query fallthrough; the ramp gives d3
--                                         the same 110% anyway, so painting it
--                                         would be a visual no-op)
-- So if this file is removed, the rendering returns exactly to what it was
-- before -- no depth is left depending on it for a colour it had already.
--
-- Groups @property.yaml.d4 .. .d8 are created by apply_yaml_key_ramp in
-- theme.lua, which owns every key colour decision. This file decides WHICH
-- group a key gets, never what colour that group is. Depth past 8 clamps to d8
-- rather than fading further -- see the Comment floor in the ramp.
--
-- Extmarks, not a query file, means priority is explicit: treesitter highlights
-- land at priority 100, so 200 wins on colour while the ramp's own nocombine
-- keeps attrs from merging up out of @string.yaml.

local NS = vim.api.nvim_create_namespace("yaml_key_depth")

-- ALL depths, 1 through 8. This used to start at 4 because the .scm captured
-- depth 1 (@property.yaml.toplevel) and depth 2 (@property.yaml.level2), with
-- depth 3 left as a deliberate no-op seam so the query half and the extmark
-- half met without a visible step.
--
-- Those captures are gone. They were the worst offenders against the naming
-- rule in :help treesitter-highlight-groups (a fake `yaml` language segment in
-- the middle of the name), and nesting depth is not a treesitter concept in the
-- first place -- a query cannot count, which is the whole reason this file
-- exists. Owning every rung here means one mechanism, no seam, and no pair of
-- files that have to agree on where the handover happens.
local MIN_DEPTH = 1
local MAX_DEPTH = 8 -- matches the rungs apply_yaml_key_ramp generates
local PRIORITY = 200 -- above treesitter's 100

-- Keys are (string_scalar) inside a plain_scalar/flow_node in key position. The
-- capture sits on string_scalar for the same reason the .scm does: it is the
-- innermost node spanning the text, so the range is the key and nothing else.
local QUERY = [[
  (block_mapping_pair
    key: (flow_node [
      (plain_scalar (string_scalar) @key)
      (single_quote_scalar) @key
      (double_quote_scalar) @key
    ]))
]]

local query_ok, query = pcall(vim.treesitter.query.parse, "yaml", QUERY)

local function depth_of(node)
  local depth = 0 -- the key's OWN enclosing pair is counted by the walk below
  local parent = node:parent()
  while parent do
    if parent:type() == "block_mapping_pair" then
      depth = depth + 1
      if depth >= MAX_DEPTH then
        return MAX_DEPTH
      end
    end
    parent = parent:parent()
  end
  return depth
end

-- ---------------------------------------------------------------------------
-- FILE-DEPTH NORMALIZATION (:YamlKeyDepthFit)
-- ---------------------------------------------------------------------------
-- The ramp always builds eight rungs, but a file that only nests three levels
-- deep uses three of them and renders nearly flat -- the ladder is there, the
-- file just never walks down it. Fit stretches the eight rungs across whatever
-- depth THIS buffer actually reaches, so a shallow file gets the full contrast
-- range instead of the top third of it.
--
-- The tradeoff, and the reason it is off by default: the same key is a different
-- colour in two files. `spec:` at depth 2 of a three-deep file lands on a
-- different rung than `spec:` at depth 2 of an eight-deep one. That is the point
-- (depth is being read RELATIVE to the file), but it does mean colour stops
-- being a stable global signal.
--
-- Computed on buffer change rather than per redraw: it needs a walk of the WHOLE
-- tree, not just the visible window, and doing that inside the decoration
-- callback would charge every scroll for it. Recomputed on a debounce so a burst
-- of edits costs one pass.
local fit_max = {} -- buf -> deepest depth in the buffer
local fit_timer = {} -- buf -> pending debounce timer

-- Stop AND close, idempotently. Every path that abandons a timer must go
-- through this; see the note in schedule_fit for what a bare :stop() leaks.
local function close_timer(t)
  if t and not t:is_closing() then
    t:stop()
    t:close()
  end
end

-- fit_max[buf] is a tri-state and the distinction is load-bearing:
--   nil    -- never measured; rung_for is allowed to kick one measurement
--   false  -- measured and FAILED (no parser yet, invalid buffer). Never retried
--             from the paint path.
--   number -- the buffer's deepest key.
--
-- Without the `false` state this deadlocks the GPU: rung_for runs inside a
-- redraw, a miss schedules a measurement, the measurement ends with redraw!,
-- and if the measurement keeps failing that redraw re-enters rung_for and
-- schedules another one. A hook whose own action re-fires it. Only a real
-- buffer change clears `false` back to nil.
-- The BUFFER'S OWN parser, never `get_parser(buf, "yaml")`.
--
-- On a `helm` buffer the attached parser is `helm`, which INJECTS yaml -- that
-- injected tree is where @property.yaml comes from, and it is the one this file
-- must walk. Asking for lang "yaml" explicitly does not return that parser: it
-- builds a SECOND, independent yaml parser for the same buffer. Nothing ever
-- parses that one (paint() deliberately does not call :parse(), see below), so
-- for_each_tree yielded zero trees and every key in a Helm template fell
-- through to flat @property.yaml -- the depth-3+ receding colour, on every
-- line. That is the "keys are purple in deployment.yaml" bug.
--
-- The lang filter inside each for_each_tree is what selects yaml, and it works
-- for both cases: plain `yaml` buffers have a yaml root tree, `helm` buffers
-- have a yaml injected tree.
local function yaml_parser(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok then
    return nil
  end
  return parser
end

local function compute_fit_max(buf)
  if not query_ok or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local parser = yaml_parser(buf)
  if not parser then
    fit_max[buf] = false
    return
  end
  -- parse(true) so INJECTED yaml is materialised before measuring. This runs on
  -- a debounce, not in a decoration callback, so the reparse is affordable here
  -- (paint() must never do it -- see there).
  --
  -- Without this, a `helm` buffer measured deepest = 1: the root gotmpl tree has
  -- no block_mapping_pair and the injected yaml tree had not been built yet, so
  -- for_each_tree found nothing to count. rung_for then compressed the whole
  -- ladder onto D1 and every key in the file rendered at the brightest rung --
  -- no depth falloff at all, which is the second half of the Helm bug.
  pcall(parser.parse, parser, true)
  local deepest = 1
  parser:for_each_tree(function(tree, ltree)
    if ltree:lang() ~= "yaml" then
      return
    end
    for _, node in query:iter_captures(tree:root(), buf) do
      local d = depth_of(node)
      if d > deepest then
        deepest = d
      end
    end
  end)
  fit_max[buf] = deepest
end

local function schedule_fit(buf)
  if not vim.g.yaml_key_depth_fit then
    return
  end
  -- :stop() is NOT :close(). A stopped timer keeps its libuv handle in the
  -- loop's handle queue, and because timer:start's callback closes over `timer`
  -- itself, luv's registry keeps the userdata reachable -- so it is never
  -- garbage collected either. Dropping the reference here without closing
  -- leaked one handle per preempted debounce, permanently. Measured: 824 live
  -- timer handles after 60 edits to a yaml buffer, growing forever.
  if fit_timer[buf] then
    close_timer(fit_timer[buf])
  end
  local timer = vim.uv.new_timer()
  fit_timer[buf] = timer
  timer:start(
    200,
    0,
    vim.schedule_wrap(function()
      close_timer(timer)
      fit_timer[buf] = nil
      if vim.api.nvim_buf_is_valid(buf) then
        compute_fit_max(buf)
        -- Redraw ONLY on a real measurement. Redrawing after a failure is what
        -- would close the loop described above.
        if type(fit_max[buf]) == "number" then
          vim.cmd("redraw!")
        end
      end
    end)
  )
end

-- Map a real nesting depth onto a rung, given what this buffer actually reaches.
-- A buffer whose deepest key is depth 1 has no ladder to stretch, so it falls
-- through to the identity rather than dividing by zero.
local function rung_for(buf, depth)
  if not vim.g.yaml_key_depth_fit then
    return depth
  end
  local deepest = fit_max[buf]
  if deepest == false then
    return depth -- measured and failed; a buffer change is what retries it
  end
  if not deepest then
    -- No measurement yet. Every ordering hole ends up here: fit switched on from
    -- a -c argument before the parser existed, a buffer that was already open
    -- when it was switched on, a BufReadPost that fired before treesitter
    -- started. Kicking the debounce (never measuring inline -- this is a redraw
    -- callback) makes the miss self-correct one tick later instead of leaving
    -- the buffer inert until its next edit.
    schedule_fit(buf)
    return depth
  end
  if deepest <= 1 then
    return depth
  end
  local scaled = 1 + math.floor(((depth - 1) * (MAX_DEPTH - 1) / (deepest - 1)) + 0.5)
  return math.max(1, math.min(MAX_DEPTH, scaled))
end

local function paint(buf, top, bot)
  if not query_ok then
    return
  end
  local parser = yaml_parser(buf)
  if not parser then
    return
  end
  -- Do NOT call parser:parse() here: on_win runs inside a decoration callback
  -- where a reparse of a large buffer is charged to every redraw. The already
  -- parsed trees are what the treesitter highlighter is rendering from anyway.
  parser:for_each_tree(function(tree, ltree)
    if ltree:lang() ~= "yaml" then
      return
    end
    local root = tree:root()
    local r_top, _, r_bot = root:range()
    if r_bot < top or r_top > bot then
      return
    end
    for _, node in query:iter_captures(root, buf, top, bot + 1) do
      local depth = depth_of(node)
      -- `<<` is a merge OPERATOR that happens to sit in key position; the .scm
      -- captures it as @operator. Painting a key rung over it would put it back
      -- in the key colour and undo that, which is the bug the .scm comment
      -- warns about from the other direction.
      local text = vim.treesitter.get_node_text(node, buf)
      if depth >= MIN_DEPTH and text ~= "<<" then
        local srow, scol, erow, ecol = node:range()
        if srow == erow then -- a key spanning lines is not a key worth painting
          pcall(vim.api.nvim_buf_set_extmark, buf, NS, srow, scol, {
            end_col = ecol,
            hl_group = "YamlKeyD" .. rung_for(buf, depth),
            priority = PRIORITY,
            ephemeral = true,
          })
        end
      end
    end
  end)
end

-- Decoration provider rather than a persistent extmark pass: ephemeral marks are
-- rebuilt per redraw for visible lines only, so editing never leaves stale
-- colours behind and there is nothing to invalidate on TextChanged.
local yaml_ft = require("config.yaml_ft")

-- :YamlKeyDepthFit [on|off|toggle]. State lives on vim.g rather than a local so
-- theme.lua can snapshot it into :ThemeConfigSave -- the knob belongs to the
-- ladder, and saving half the ladder's settings would be worse than saving none.
vim.api.nvim_create_user_command("YamlKeyDepthFit", function(opts)
  local arg = vim.trim(opts.args):lower()
  -- Fit is a ladder knob, so it echoes the whole ladder like the rest of them.
  -- The buffer's measured depth is the one fact the shared report cannot know
  -- (it lives here, per buffer), so it is appended rather than replaced.
  local function report()
    local buf = vim.api.nvim_get_current_buf()
    local deepest = fit_max[buf]
    local tail = deepest and (" [this buffer reaches depth " .. deepest .. "]") or ""
    -- theme.lua owns the ladder state; go through its status builder so the two
    -- can never disagree about what the ladder is set to. It is absent only if
    -- this file loaded without theme.lua, in which case fall back to fit alone.
    local ok, line = pcall(function()
      return _G.__yaml_key_depth_status()
    end)
    if ok and type(line) == "string" then
      vim.notify(line .. tail)
    else
      vim.notify(("YamlKeyDepthFit: %s%s"):format(vim.g.yaml_key_depth_fit and "on" or "off", tail))
    end
  end
  if arg == "" then
    report()
    return
  end
  if arg == "on" then
    vim.g.yaml_key_depth_fit = true
  elseif arg == "off" then
    vim.g.yaml_key_depth_fit = false
  elseif arg == "toggle" then
    vim.g.yaml_key_depth_fit = not vim.g.yaml_key_depth_fit
  else
    vim.notify("YamlKeyDepthFit: expected on, off or toggle", vim.log.levels.ERROR)
    return
  end
  -- Turning it on mid-session has to measure the buffers that are already open;
  -- nothing has fired a change event for them.
  if vim.g.yaml_key_depth_fit then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and yaml_ft.is_yaml(buf) then
        compute_fit_max(buf)
      end
    end
  end
  vim.cmd("redraw!")
  report()
end, {
  nargs = "?",
  complete = function()
    return { "on", "off", "toggle" }
  end,
  desc = "Stretch the 8 depth rungs across the depth THIS file actually reaches",
})

vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("YamlKeyDepthFit", { clear = true }),
  pattern = "*",
  callback = function(ev)
    if yaml_ft.is_yaml(ev.buf) then
      if fit_max[ev.buf] == false then
        fit_max[ev.buf] = nil -- a genuine change: allow another attempt
      end
      schedule_fit(ev.buf)
    end
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("YamlKeyDepthFitCleanup", { clear = true }),
  pattern = "*",
  callback = function(ev)
    fit_max[ev.buf] = nil
    if fit_timer[ev.buf] then
      close_timer(fit_timer[ev.buf])
      fit_timer[ev.buf] = nil
    end
  end,
})

-- Which YamlKeyD* group is drawn at a position, or nil if no key rung is.
--
-- WHY THIS HAS TO EXIST. The rungs are EPHEMERAL extmarks (see the decoration
-- provider below) -- they live only for the frame being painted, so
-- vim.inspect_pos reports `extmarks: {}` for a yaml key and :HlColor resolves the
-- capture underneath instead (@property.yaml). Recolouring that does nothing,
-- because the rung draws over it every frame. That is the whole "HlColor cannot
-- recolour the top key" bug.
--
-- Global rather than a module return: this file returns a lazy.nvim spec, and
-- theme.lua already reaches for _G.__yaml_key_depth_report the same way.
_G.__yaml_key_depth_group_at = function(buf, row, col)
  buf = buf or vim.api.nvim_get_current_buf()
  if not query_ok or not yaml_ft.is_yaml(buf) then
    return nil
  end
  local parser = yaml_parser(buf)
  if not parser then
    return nil
  end
  -- parse(true) so injected yaml (helm) is materialised, then walk every yaml
  -- tree -- on helm the root tree is gotmpl and holds no block_mapping_pair.
  parser:parse(true)
  local group = nil
  parser:for_each_tree(function(tree, ltree)
    if group or ltree:lang() ~= "yaml" then
      return
    end
    for _, node in query:iter_captures(tree:root(), buf, row, row + 1) do
      local srow, scol, erow, ecol = node:range()
      -- Single-row keys in practice, but a multi-row scalar key is still legal.
      local after_start = row > srow or (row == srow and col >= scol)
      local before_end = row < erow or (row == erow and col < ecol)
      if after_start and before_end then
        local depth = depth_of(node)
        local text = vim.treesitter.get_node_text(node, buf)
        if depth >= MIN_DEPTH and text ~= "<<" then
          group = "YamlKeyD" .. rung_for(buf, depth)
          return
        end
      end
    end
  end)
  return group
end

vim.api.nvim_set_decoration_provider(NS, {
  on_win = function(_, _, buf, toprow, botrow)
    -- Root-filetype test, not equality: see lua/config/yaml_ft.lua. A compound
    -- filetype like `yaml.github` must not silently disable key depth on
    -- .github/workflows while the .scm keeps painting everything else.
    if not yaml_ft.is_yaml(buf) then
      return false
    end
    paint(buf, toprow, botrow)
    return false
  end,
})

return {}
