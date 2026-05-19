-- ~/.config/nvim/lua/config/keymaps.lua
-- Personal DevOps/platform engineering keymaps

local keymap = vim.keymap.set

-- Save fast
keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })

-- Clear search highlight
keymap("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

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

vim.keymap.set("n", "<leader>nr", "<cmd>Neotree reveal left<CR>", {
  desc = "Reveal current file in Neo-tree",
})
