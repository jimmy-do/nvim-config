-- ~/.config/nvim/lua/config/keymaps.lua
-- Personal DevOps/platform engineering keymaps

local keymap = vim.keymap.set

-- Save fast
keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })

-- LazyVim also binds <leader>wd (close window) and <leader>wm (zoom), which
-- makes <leader>w an ambiguous prefix: every save stalls the full timeoutlen
-- waiting for a possible d/m. Delete them — window close stays on <C-w>c and
-- zoom stays on <leader>uZ — so save fires instantly.
pcall(vim.keymap.del, "n", "<leader>wd")
pcall(vim.keymap.del, "n", "<leader>wm")

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
vim.keymap.set("n", "<leader>;", "q:", { desc = "Command-line window (history)" })

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
