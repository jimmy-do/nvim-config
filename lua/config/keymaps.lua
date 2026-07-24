-- ~/.config/nvim/lua/config/keymaps.lua
-- Personal DevOps/platform engineering keymaps

local keymap = vim.keymap.set

-- Save fast
keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })

-- Clear search highlight
keymap("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

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

-- Open common DevOps files quickly
keymap("n", "<leader>er", "<cmd>edit README.md<cr>", { desc = "Edit README" })
keymap("n", "<leader>eg", "<cmd>edit .github/workflows<cr>", { desc = "Edit GitHub workflows" })
keymap("n", "<leader>ek", "<cmd>edit k8s<cr>", { desc = "Edit k8s folder" })
keymap("n", "<leader>et", "<cmd>edit terraform<cr>", { desc = "Edit Terraform folder" })

vim.keymap.set("n", "<leader>th", "<cmd>Telescope colorscheme<CR>", { desc = "Pick colorscheme" })

-- Buffer navigation
vim.keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "J", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "K", "<cmd>bnext<CR>", { desc = "Next buffer" })

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
vim.keymap.set("c", "<M-h>", "<S-Left>", { desc = "Back a word" })
vim.keymap.set("c", "<M-l>", "<S-Right>", { desc = "Forward a word" })
vim.keymap.set("c", "<M-b>", "<S-Left>", { desc = "Back a word" })
vim.keymap.set("c", "<M-f>", "<S-Right>", { desc = "Forward a word" })
