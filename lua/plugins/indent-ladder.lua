-- Single enclosing indent guide.
--
-- The rule: exactly ONE guide is lit at any time -- the vertical line
-- immediately enclosing the cursor (the guide just left of the block you are
-- in). When the cursor sits in the shallowest nested block, the furthest-left
-- guide (col 0) lights; go one level deeper and the next guide to the right
-- lights instead; never more than one.
--
-- Why this exists instead of snacks' own scope highlight: snacks lit the guide
-- at the *inside* column of the block (scope.indent) and drew nothing on leaf
-- `key: value` lines, so it was consistently one level too deep and usually
-- invisible. Snacks' scope rendering is therefore disabled in indent.lua; snacks
-- still paints all the DIM guides (SnacksIndent) and this overlay recolours just
-- the single enclosing column on top of them.
--
-- The lit colour is whatever SnacksIndentScope resolves to (theme.lua pins it to
-- maxed cyan #00ffff on the storm theme), so the theme stays the source of truth
-- for the guide colour.

local enabled = true
if not enabled then
  pcall(function()
    local ns = vim.api.nvim_create_namespace("indent_ladder")
    pcall(vim.api.nvim_create_augroup, "IndentLadder", { clear = true })
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
    end
  end)
  return {}
end

local config = {
  char = "│", -- keep in sync with indent.lua's indent char
  hl = "SnacksIndentScope", -- theme.lua pins this to the maxed cyan on storm
  priority = 250, -- above snacks' dim guides (priority 1) so our colour wins
}

local ns = vim.api.nvim_create_namespace("indent_ladder")

-- ---- indent scanning --------------------------------------------------------

local function is_blank(lnum)
  return vim.fn.getline(lnum):match("^%s*$") ~= nil
end

-- Effective indent of a line, or nil when the line is blank.
local function indent_of(lnum)
  if is_blank(lnum) then
    return nil
  end
  return vim.fn.indent(lnum)
end

-- Cursor's contextual indent. On a blank line, use the deeper of its nearest
-- non-blank neighbours so an empty line inside a block still lights the guide.
local function cursor_indent(cur, last)
  local ci = indent_of(cur)
  if ci then
    return ci
  end
  local up, down
  for l = cur - 1, 1, -1 do
    up = indent_of(l)
    if up then
      break
    end
  end
  for l = cur + 1, last do
    down = indent_of(l)
    if down then
      break
    end
  end
  return math.max(up or 0, down or 0)
end

-- Vertical extent of the block whose guide sits at column x, around the cursor.
-- Blank lines continue the block; the first non-blank line at indent <= x ends
-- it. Returns from,to (1-based, inclusive).
local function block_range(cur, x, last)
  local from, to = cur, cur
  for l = cur - 1, 1, -1 do
    if is_blank(l) then
      -- provisional: only kept if a qualifying line is found further up
    elseif vim.fn.indent(l) > x then
      from = l
    else
      break
    end
  end
  for l = cur + 1, last do
    if is_blank(l) then
      -- provisional
    elseif vim.fn.indent(l) > x then
      to = l
    else
      break
    end
  end
  return from, to
end

-- ---- render -----------------------------------------------------------------

local function repaint()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  if vim.bo.buftype ~= "" then
    return
  end
  local sw = vim.fn.shiftwidth()
  if sw == 0 then
    sw = vim.bo.tabstop
  end
  if sw == 0 then
    return
  end

  local last = vim.fn.line("$")
  local cur = vim.fn.line(".")
  local ci = cursor_indent(cur, last)
  if ci <= 0 then
    return -- top level: no enclosing guide to light
  end

  -- The enclosing guide is the guide column immediately to the left of the
  -- cursor's own indent: the largest guide column strictly less than ci.
  local col = math.floor((ci - 1) / sw) * sw

  local from, to = block_range(cur, col, last)
  from = math.max(from, vim.fn.line("w0"))
  to = math.min(to, vim.fn.line("w$"))

  for l = from, to do
    -- Only draw where the column falls inside the line's indentation
    -- whitespace (or on a blank continuation line) -- never over real text.
    if is_blank(l) or vim.fn.indent(l) > col then
      vim.api.nvim_buf_set_extmark(buf, ns, l - 1, 0, {
        virt_text = { { config.char, config.hl } },
        virt_text_win_col = col,
        virt_text_pos = "overlay",
        hl_mode = "combine",
        priority = config.priority,
        ephemeral = false,
      })
    end
  end
end

-- Debounce: CursorMoved fires in bursts; coalesce to one repaint per tick.
local scheduled = false
local function schedule()
  if scheduled then
    return
  end
  scheduled = true
  vim.schedule(function()
    scheduled = false
    pcall(repaint)
  end)
end

local group = vim.api.nvim_create_augroup("IndentLadder", { clear = true })
vim.api.nvim_create_autocmd(
  { "CursorMoved", "CursorMovedI", "WinScrolled", "BufWinEnter", "TextChanged", "TextChangedI", "ColorScheme" },
  { group = group, callback = schedule }
)

return {}
