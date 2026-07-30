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

local MIN_DEPTH = 4 -- depths 1-3 already have their own groups
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

local function paint(buf, top, bot)
  if not query_ok then
    return
  end
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "yaml")
  if not ok or not parser then
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
      if depth >= MIN_DEPTH then
        local srow, scol, erow, ecol = node:range()
        if srow == erow then -- a key spanning lines is not a key worth painting
          pcall(vim.api.nvim_buf_set_extmark, buf, NS, srow, scol, {
            end_col = ecol,
            hl_group = "@property.yaml.d" .. depth,
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
vim.api.nvim_set_decoration_provider(NS, {
  on_win = function(_, _, buf, toprow, botrow)
    if vim.bo[buf].filetype ~= "yaml" then
      return false
    end
    paint(buf, toprow, botrow)
    return false
  end,
})

return {}
