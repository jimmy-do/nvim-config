-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Remove LazyVim's wrap+spell group, then re-add wrap-only (no spell checking)
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})

-- `nvim .` leaves an empty [No Name] buffer behind: LazyVim's neo-tree netrw
-- hijack bwipeouts the directory buffer, and wiping the last buffer makes Vim
-- spawn a fresh empty one. Drop it once a real file gets loaded.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("jimmy_kill_startup_scratch", { clear = true }),
  callback = function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if
        vim.bo[b].buflisted
        and vim.api.nvim_buf_get_name(b) == ""
        and not vim.bo[b].modified
        and vim.api.nvim_buf_line_count(b) == 1
        and vim.api.nvim_buf_get_lines(b, 0, 1, false)[1] == ""
      then
        pcall(vim.api.nvim_buf_delete, b, {})
      end
    end
  end,
})
