-- ~/.config/nvim/lua/config/keymaps.lua
-- Personal DevOps/platform engineering keymaps

local keymap = vim.keymap.set

-- <leader>w is the WINDOWS prefix (LazyVim maps it to <c-w>), so which-key
-- pops the window menu. It used to be <cmd>w<cr> (save), which meant no menu
-- ever appeared and every press echoed a "file 70L, 3128B" write message that
-- stacked up in noice's bottom-right view. Save is :w (or LazyVim's <C-s>).

-- Bare q kept starting accidental macro recordings ("recording @w" in the
-- statusline). Recording moves to Q (whose default, replay-last-macro, is
-- covered by @@). Buffer-local q maps (close help/quickfix/etc.) are unaffected
-- — local always beats global. q: (command-line window) also still works via
-- the explicit map below.
keymap("n", "q", "<nop>", { desc = "Disabled (macro record is on Q)" })
keymap("n", "q:", "q:", { desc = "Command-line window" })
keymap("n", "Q", "q", { desc = "Record macro" })

-- Clear search highlight — AND flash.nvim's f/t char-mode state. Flash
-- normally dismisses itself when it sees a raw <Esc> via vim.on_key, but this
-- mapping swallows the raw key (only the <cmd> output is processed), so
-- without the explicit hide below, pressing f locks you into flash's search
-- until the cursor moves.
keymap("n", "<Esc>", function()
  vim.cmd("nohlsearch")
  local ok, char = pcall(require, "flash.plugins.char")
  if ok and char.state then
    char.state:hide()
  end
end, { desc = "Clear search highlight / flash state" })

-- Better window navigation
-- NOTE: <C-h/j/k/l> are now handled by vim-tmux-navigator
-- (lua/plugins/tmux-navigator.lua) so they cross the nvim/tmux seam.
-- Keeping these here would shadow the plugin, so they're intentionally removed.

-- Resize splits
keymap("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
keymap("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
keymap("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
keymap("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Keep visual selection when indenting
keymap("v", "<", "<gv", { desc = "Indent left and reselect" })
keymap("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Move selected lines up/down
keymap("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
keymap("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Diagnostics navigation
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
keymap("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostic" })
keymap("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "Diagnostics list" })

-- Quick terminal
keymap("n", "<leader>tt", "<cmd>terminal<cr>", { desc = "Open terminal" })

-- Open common DevOps files quickly.
--
-- On <leader>o, NOT <leader>e. <leader>e is the explorer toggle, and any mapping
-- that extends it turns it into an ambiguous prefix: nvim then has to wait the
-- full timeoutlen (300ms here) on every <leader>e press to find out whether an
-- r/g/k/t is coming. Since <leader>e is pressed constantly, that delay was the
-- single most-felt bit of latency in this config. Nothing extends <leader>o.
keymap("n", "<leader>or", "<cmd>edit README.md<cr>", { desc = "Open README" })
keymap("n", "<leader>og", "<cmd>edit .github/workflows<cr>", { desc = "Open GitHub workflows" })
keymap("n", "<leader>ok", "<cmd>edit k8s<cr>", { desc = "Open k8s folder" })
keymap("n", "<leader>ot", "<cmd>edit terraform<cr>", { desc = "Open Terraform folder" })

-- <leader>th lives in plugins/colorscheme-picker.lua (custom scroll-preview picker; telescope removed 2026-07-26).

-- Buffer navigation
vim.keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

-- NOTE: bare J / K used to duplicate <S-h> / <S-l> here. Removed deliberately:
-- they are the same two commands already bound one row up, and holding them cost
-- both K (LSP hover -- the docs popup, with no gK fallback bound either) and J
-- (join lines). Buffer nav lives on <S-h>/<S-l> only.

-- Close current buffer
-- Safely delete current buffer without letting Neo-tree take over the screen
vim.keymap.set("n", "<leader>bd", function()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_ft = vim.bo[current_buf].filetype

  -- If focused inside Neo-tree, close Neo-tree instead of deleting buffers
  if current_ft == "neo-tree" then
    vim.cmd("Neotree close")
    return
  end

  -- Get other normal/listed buffers, excluding current buffer and Neo-tree
  local other_buffers = vim.tbl_filter(function(buf)
    return buf ~= current_buf
      and vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
      and vim.bo[buf].filetype ~= "neo-tree"
  end, vim.api.nvim_list_bufs())

  -- Move to another real buffer first so Neo-tree does not become the only visible window
  if #other_buffers > 0 then
    vim.api.nvim_set_current_buf(other_buffers[#other_buffers])
  else
    vim.cmd("enew")
  end

  -- Delete the original buffer safely
  local ok, err = pcall(vim.api.nvim_buf_delete, current_buf, { force = false })

  if not ok then
    vim.notify("Could not delete buffer: " .. err, vim.log.levels.WARN)
  end
end, { desc = "Delete buffer safely" })

vim.keymap.set("n", "<leader>nt", "<cmd>Neotree toggle reveal left<CR>", {
  desc = "Toggle Neo-tree",
})

-- Exit terminal mode with Esc Esc
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
  desc = "Exit terminal mode",
})

vim.keymap.set("n", "<leader>nr", "<cmd>Neotree reveal left<CR>", {
  desc = "Reveal current file in Neo-tree",
})

-- ── u / d ⇄ C-u / C-d ────────────────────────────────────────────────────────
-- Bare keys SCROLL, Ctrl keys do the editing. Deliberate: scrolling is the thing
-- you do constantly and it should cost no modifier; undo and delete are the
-- occasional, destructive ones and they can pay a chord.
--
-- This matches the same swap in tmux copy mode (tmux.conf), so u/d scroll a half
-- page in both places.
--
-- The SCROLL half (u / d) is NOT here -- it lives in lua/plugins/scroll.lua,
-- bound to that file's instant_page_scroll wrapper so a page jump is not
-- animated by snacks. Only the EDITING half is below. Change one, check both.
--
--   n  u        -> page up      (scroll.lua)     n  <C-u> -> u   undo
--   n  d        -> page down    (scroll.lua)     n  <C-d> -> d   delete operator
--   x  u / d    -> page up/down (scroll.lua)     x  <C-u> -> u   lowercase selection
--                                                x  <C-d> -> d   delete selection
--   o  <C-d>    -> d    so <C-d><C-d> still resolves to linewise "dd"
--
-- Counts survive on both sides: 5u scrolls what 5<C-u> did, 3<C-d>w deletes what
-- 3dw did.
vim.keymap.set("n", "<C-u>", "u", { desc = "Undo" })
vim.keymap.set("x", "<C-u>", "u", { desc = "Lowercase selection" })

-- <C-d> must exist in n, x AND o: normal starts the operator, visual deletes the
-- selection, and operator-pending is what makes the doubled form (<C-d><C-d>)
-- resolve to linewise dd.
vim.keymap.set({ "n", "x", "o" }, "<C-d>", "d", { desc = "Delete (operator)" })

-- Enter command mode without Shift: Ctrl+; acts as ":". Ghostty speaks the
-- kitty keyboard protocol, so <C-;> arrives as a distinct key in nvim.
vim.keymap.set({ "n", "x" }, "<C-;>", ":", { desc = "Command mode (no Shift)" })

-- ---------------------------------------------------------------------------
-- Cmdline practicality
-- ---------------------------------------------------------------------------
-- The cmdline is a modeless one-line prompt -- it has no normal mode and never
-- will, so 0/$/b/w cannot work there. What DOES work is the command-line
-- WINDOW (:h cmdwin): a real, editable buffer holding your command history,
-- opened in normal mode, with full motions/search/yank. <CR> on a line runs it.
--   q:  from normal mode        -- history of :commands
--   q/  from normal mode        -- history of /searches
--   <C-f> while already typing  -- dumps the half-typed cmdline into it
-- That is the answer to "navigating previous commands": edit history as text.
-- NOTE: no <leader>; alias here -- that key belongs to focus-fx (wincmd p,
-- mirroring tmux prefix-;). Use q: / q/ directly; they are mapped above.

-- ...and for the cases where popping a window is overkill, make the one-line
-- prompt behave like every other text field on macOS. Ghostty has
-- macos-option-as-alt=left, so Opt+arrow arrives as <M-Left>/<M-Right>; nvim
-- binds nothing there by default, which is why it "does nothing". <S-Left> /
-- <S-Right> are the built-in cmdline word motions -- just forward to them.
vim.keymap.set("c", "<M-Left>", "<S-Left>", { desc = "Back a word" })
vim.keymap.set("c", "<M-Right>", "<S-Right>", { desc = "Forward a word" })
vim.keymap.set("c", "<M-BS>", "<C-w>", { desc = "Delete word back" })
vim.keymap.set("c", "<C-a>", "<Home>", { desc = "Start of line (0)" })
vim.keymap.set("c", "<C-e>", "<End>", { desc = "End of line ($)" })
vim.keymap.set("c", "<C-d>", "<Del>", { desc = "Delete char forward" })
-- Prefix-filtered history: type ":Theme" then <C-p> cycles only :Theme* lines,
-- unlike <Up> which noice/wildmenu may consume for completion.
vim.keymap.set("c", "<C-p>", "<Up>", { desc = "Prev history (prefix match)" })
vim.keymap.set("c", "<C-n>", "<Down>", { desc = "Next history (prefix match)" })

-- Opt+arrow depends on Ghostty emitting CSI 1;3D and tmux forwarding it, which
-- is not guaranteed. Opt+h / Opt+l ARE guaranteed: config.ghostty explicitly
-- binds alt+h=esc:h and alt+l=esc:l, so those bytes definitely arrive, and
-- tmux.conf no longer claims them (its `bind -n M-h/M-l previous/next-window`
-- fallback was removed -- window switching lives on User0/User1 instead).
-- Opt+b / Opt+f are kept as the readline-shaped synonyms.
-- Copy/paste IN the prompt. The cmdline has no visual selection and no normal
-- mode, so there is nothing for Cmd+V's bracketed paste or a `y` motion to hook
-- into -- which is why editing a pasted-in command has always been a dead end.
-- Register insertion is the mechanism that does work there (:h c_CTRL-R), so
-- these two wrap it:
--   <C-v>  pastes the system clipboard  (was: literal-insert, which still lives
--          on <C-q> -- see :h c_CTRL-Q -- so nothing is actually lost here)
--   <M-y>  copies the WHOLE prompt to the clipboard; there is no selection to
--          copy a part of, and <C-y> is taken by blink (select_and_accept)
vim.keymap.set("c", "<C-v>", "<C-r>+", { desc = "Paste system clipboard" })
vim.keymap.set("c", "<M-v>", "<C-r>+", { desc = "Paste system clipboard" })
vim.keymap.set("c", "<M-y>", function()
  local line = vim.fn.getcmdline()
  vim.fn.setreg("+", line)
  -- Deferred: notifying mid-expr-mapping redraws over the prompt you are in.
  vim.schedule(function()
    vim.notify("Copied cmdline: " .. line)
  end)
  return ""
end, { expr = true, desc = "Copy the whole cmdline to the clipboard" })

vim.keymap.set("c", "<M-h>", "<S-Left>", { desc = "Back a word" })
vim.keymap.set("c", "<M-l>", "<S-Right>", { desc = "Forward a word" })
vim.keymap.set("c", "<M-b>", "<S-Left>", { desc = "Back a word" })
vim.keymap.set("c", "<M-f>", "<S-Right>", { desc = "Forward a word" })

-- Shrink FLOOR, shared by the sticky mode and the one-shot <M-*> maps below.
--
-- Ghostty sends Cmd+J as ESC-prefixed `j`, and ESC+j is exactly what <M-j> is:
-- by the time nvim sees the bytes, Cmd+J and Opt+J are the same keypress and no
-- mapping can tell them apart. So a Cmd+J aimed at something else lands on
-- `resize -3`, and holding it walked a window from 19 lines down to 4 (measured
-- 2026-07-31) with nothing to stop it at zero.
--
-- The floor is the fix that works regardless of which key sent it. Shrinking
-- stops at a window that is still usable instead of collapsing to a sliver you
-- then have to rebuild by hand; growing is never restricted.
local MIN_H, MIN_W = 4, 12

local function resize_guarded(cmd, amount)
  local shrinking = cmd:find("%-$") ~= nil
  if shrinking then
    local vertical = cmd:find("^vertical") ~= nil
    local cur = vertical and vim.fn.winwidth(0) or vim.fn.winheight(0)
    local floor = vertical and MIN_W or MIN_H
    if cur <= floor then
      return -- already at the floor: a no-op beats collapsing it further
    end
    amount = math.min(amount, cur - floor)
  end
  pcall(vim.cmd, cmd .. amount)
end

-- Sticky resize mode (tmux-style): <leader>r, then hold h/j/k/l as long as you
-- like. No leader spam — the loop keeps reading keys until you press something
-- that isn't a resize key, and that key is fed back to nvim so nothing is eaten.
vim.keymap.set("n", "<leader>r", function()
  local step = 3
  local actions = {
    h = "vertical resize -",
    l = "vertical resize +",
    j = "resize -",
    k = "resize +",
    H = "vertical resize -",
    L = "vertical resize +",
    J = "resize -",
    K = "resize +",
  }
  -- The indicator is a FLOAT, not an echo, and that is not a style choice.
  --
  -- Measured 2026-07-31: with nvim_echo the message line was blank for the
  -- entire loop -- the one thing telling you a sticky mode is active never
  -- appeared. noice owns msg_show and renders it from a scheduled callback,
  -- and getcharstr() blocks the main loop, so that callback cannot run until
  -- after you have already left the mode. Redrawing before the echo does not
  -- help; the message never reaches the screen at all.
  --
  -- A float we own is painted synchronously by the redraw below, so it survives
  -- the blocking read. focusable=false + enter=false keeps it out of window
  -- navigation and stops it firing WinEnter at focus-fx.
  local hint = " -- RESIZE --  h/l width   j/k height   CAPS = 10   = equalize   <Esc> done "
  local hint_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(hint_buf, 0, -1, false, { hint })
  local ok_win, hint_win = pcall(vim.api.nvim_open_win, hint_buf, false, {
    relative = "editor",
    anchor = "SW",
    row = vim.o.lines - 1,
    col = 0,
    width = math.min(#hint, vim.o.columns),
    height = 1,
    style = "minimal",
    focusable = false,
    zindex = 250,
  })
  if ok_win then
    vim.wo[hint_win].winhl = "Normal:ModeMsg"
  end

  local function close_hint()
    if ok_win and vim.api.nvim_win_is_valid(hint_win) then
      pcall(vim.api.nvim_win_close, hint_win, true)
    end
    if vim.api.nvim_buf_is_valid(hint_buf) then
      pcall(vim.api.nvim_buf_delete, hint_buf, { force = true })
    end
  end

  while true do
    -- Paint before blocking: a resize repaints the screen, and without this the
    -- float would only appear after the NEXT keypress.
    vim.cmd("redraw")
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok then
      break
    end
    if key == "\27" or key == "q" then
      break
    elseif key == "=" then
      vim.cmd("wincmd =")
    elseif actions[key] then
      -- capitals move in bigger jumps
      local amount = key:match("%u") and 10 or step
      resize_guarded(actions[key], amount)
    else
      vim.api.nvim_feedkeys(key, "n", false)
      break
    end
  end
  close_hint()
  vim.cmd("redraw")
end, { desc = "Resize mode (h/j/k/l)" })

-- Direct one-shot resizes, no arrow-key reach.
-- Routed through resize_guarded, not a raw <cmd>resize<cr>: <M-j> is also what
-- Cmd+J arrives as (see the floor above), so this is the pair most likely to be
-- pressed by accident.
vim.keymap.set("n", "<M-h>", function()
  resize_guarded("vertical resize -", 3)
end, { desc = "Width -" })
vim.keymap.set("n", "<M-l>", function()
  resize_guarded("vertical resize +", 3)
end, { desc = "Width +" })
vim.keymap.set("n", "<M-j>", function()
  resize_guarded("resize -", 3)
end, { desc = "Height -" })
vim.keymap.set("n", "<M-k>", function()
  resize_guarded("resize +", 3)
end, { desc = "Height +" })
