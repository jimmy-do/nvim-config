-- Hide the terminal cursor while a picker menu is focused.
--
-- WHY: Ghostty's cursor shaders (cursor trail / sonic boom) fire on every cursor
-- MOVE, and a picker is nothing but cursor moves — one per row. Holding j/k down
-- a 300-line colorscheme list restarts the trail hundreds of times, so instead of
-- one tail you get a column of half-finished smears raking through the float.
-- scroll.lua already fights the same shader for held u/d (see its
-- smooth_page_scroll comment); this is the picker half of that problem.
--
-- Neovim cannot talk to the shader, so the fix is upstream of it: with
-- `guicursor=a:NoCursor` there is no cursor on screen for the shader to trail.
-- Nothing is lost inside a picker — the selection is shown by the cursorline and,
-- in the colorscheme picker, by its own `▶` marker, which is exactly why that
-- marker exists.
--
-- guicursor is GLOBAL (no window-local form), so this is refcounted: nested or
-- overlapping pickers each acquire, and the cursor comes back only when the last
-- one releases. Every release path is belt-and-braces — if this ever leaked, you
-- would be left editing with an invisible cursor, so `restore()` is also wired to
-- VimLeavePre and is safe to call when nothing is held.

local M = {}

local depth = 0
local saved = nil

-- The exact value guicursor is parked at while held. Anything else is a real
-- cursor shape and is safe to save.
local HIDDEN = "a:NoCursor"

-- What the cursor looks like when nothing is held, captured at setup() before
-- any picker can have run. Used when `saved` is missing or poisoned -- without
-- it, restore() has nothing to restore TO and would leave you hidden.
-- Seeded with Neovim's stock value so `saved or fallback` can never be nil (that
-- would throw inside a release path and strand the cursor). setup() replaces it
-- with the real one from options.lua.
local fallback = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

function M.acquire()
  if depth == 0 then
    local cur = vim.o.guicursor
    -- Never save the hidden value itself. If some path leaked and left
    -- guicursor at NoCursor with depth back at zero, saving it here would make
    -- the hiding permanent: every later release would faithfully "restore" an
    -- invisible cursor, and each new picker would re-save it. That is the one
    -- failure mode that does not heal on its own.
    saved = (cur ~= HIDDEN and cur ~= "") and cur or fallback
    vim.o.guicursor = HIDDEN
  end
  depth = depth + 1
end

function M.release()
  depth = math.max(0, depth - 1)
  if depth == 0 then
    vim.o.guicursor = saved or fallback
    saved = nil
  end
end

-- Unconditional escape hatch: drop the refcount and put the cursor back.
function M.restore()
  depth = 0
  vim.o.guicursor = saved or fallback
  saved = nil
end

-- Run `fn` with the cursor hidden, releasing even if `fn` throws.
function M.wrap(fn)
  M.acquire()
  local ok, err = pcall(fn)
  M.release()
  if not ok then
    error(err)
  end
end

-- Buffers that count as "a picker menu". Matched on filetype: fzf-lua's list is
-- a terminal buffer (ft=fzf), snacks' picker splits its own list/input/preview,
-- and the colorscheme picker sets ft=colorschemepicker itself.
local picker_filetypes = {
  colorschemepicker = true,
  fzf = true,
  snacks_picker_list = true,
  snacks_picker_input = true,
  snacks_picker_preview = true,
  TelescopePrompt = true,
  TelescopeResults = true,
}

-- The colorscheme picker acquires/releases by hand around its own lifetime (it
-- has to survive the WinLeave close path), so it opts out of the autocmd here.
local autocmd_exempt = { colorschemepicker = true }

local function is_picker(buf)
  local ft = vim.bo[buf].filetype
  return picker_filetypes[ft] and not autocmd_exempt[ft]
end

-- Track by BUFFER, not by a bare enter/leave pair: snacks' picker moves focus
-- between its own input/list/preview windows constantly, and a naive
-- release-on-leave would flash the cursor back on with every hop.
local held = {}

-- Is a picker actually on screen right now? Filetype over `held`, because the
-- whole point is to distrust the bookkeeping. colorschemepicker counts here even
-- though it is autocmd-exempt -- it holds the cursor by hand, and while its
-- float is up the hidden cursor is correct.
local function any_picker_visible()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, ft = pcall(function()
      return vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    end)
    if ok and picker_filetypes[ft] then
      return true
    end
  end
  return false
end

function M.setup()
  local group = vim.api.nvim_create_augroup("jimmy_hidden_cursor", { clear = true })

  -- Snapshot the real cursor before any picker can have touched it.
  if vim.o.guicursor ~= HIDDEN and vim.o.guicursor ~= "" then
    fallback = vim.o.guicursor
  end

  -- Self-heal. Every release below is event-driven, so a picker that dies in a
  -- way none of them see leaves the cursor hidden forever -- and you only find
  -- out by trying to edit. This is the ground-truth check: if the cursor is
  -- hidden and no picker is on screen, the bookkeeping is wrong, not the screen.
  -- SafeState fires when nvim is about to wait for input; the string compare
  -- short-circuits on effectively every one of them.
  vim.api.nvim_create_autocmd("SafeState", {
    group = group,
    callback = function()
      if vim.o.guicursor ~= HIDDEN or any_picker_visible() then
        return
      end
      held = {}
      M.restore()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TermEnter", "FileType" }, {
    group = group,
    callback = function(args)
      local buf = args.buf
      if is_picker(buf) and not held[buf] then
        held[buf] = true
        M.acquire()
      end
    end,
  })

  -- Release when the buffer actually goes away, so an abandoned picker cannot
  -- hold the cursor hostage.
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete", "BufUnload" }, {
    group = group,
    callback = function(args)
      if held[args.buf] then
        held[args.buf] = nil
        M.release()
      end
    end,
  })

  -- Last line of defence: if no picker buffer is displayed anywhere, nothing
  -- should be holding the cursor down.
  vim.api.nvim_create_autocmd({ "WinClosed", "TabEnter" }, {
    group = group,
    callback = function()
      vim.schedule(function()
        for buf in pairs(held) do
          if not vim.api.nvim_buf_is_valid(buf) or #vim.fn.win_findbuf(buf) == 0 then
            held[buf] = nil
            M.release()
          end
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.restore })

  -- :ShowCursor — manual unstick, in case a picker dies in a way none of the
  -- above sees. Purely a safety valve; you should never need it.
  vim.api.nvim_create_user_command("ShowCursor", function()
    held = {}
    M.restore()
    vim.notify("cursor restored: " .. vim.o.guicursor)
  end, {})
end

return M
