local function references_previewer(symbol)
  return {
    _ctor = function()
      local previewer = require("fzf-lua.previewer.builtin").buffer_or_file:extend()

      function previewer:parse_entry(entry_str, cb)
        local entry = previewer.super.parse_entry(self, entry_str, cb)
        if entry.col and entry.col > 0 and #symbol > 0 then
          entry.end_line = entry.line
          entry.end_col = entry.col + #symbol
          entry.hlgroup = "FzfLuaPreviewMatch"
        end
        return entry
      end

      return previewer
    end,
  }
end

local function grep_previewer()
  return {
    _ctor = function()
      local utils = require("fzf-lua.utils")
      local previewer = require("fzf-lua.previewer.builtin").buffer_or_file:extend()

      function previewer:set_cursor_hl(entry)
        local ok, info = pcall(function()
          return _G.FzfLua and FzfLua.get_info and FzfLua.get_info() or {}
        end)
        info = ok and info or {}
        local pattern = type(info.query) == "string" and info.query ~= "" and info.query or self.opts.search

        if pattern and entry.line and entry.line > 0 and entry.col and entry.col > 0 and self.preview_bufnr then
          local line = vim.api.nvim_buf_get_lines(self.preview_bufnr, entry.line - 1, entry.line, false)[1] or ""
          local text = line:sub(entry.col)
          local case_sensitive = pattern:lower() ~= pattern
          local preview_pattern = pattern:gsub("\\b", "")
          local regex = utils.vim_regex(utils.regex_to_magic(preview_pattern), { silent = true })
          local start_col, end_col
          if regex then
            start_col, end_col = regex:match_str(case_sensitive and text or text:lower())
          end

          if start_col == 0 and end_col and end_col > 0 then
            entry.end_line = entry.line
            entry.end_col = entry.col + end_col
            entry.hlgroup = "FzfLuaPreviewMatch"
          end
        end

        return previewer.super.set_cursor_hl(self, entry)
      end

      return previewer
    end,
  }
end

local function lsp_references()
  local symbol = vim.fn.expand("<cword>")
  require("fzf-lua").lsp_references({
    jump1 = true,
    ignore_current_line = true,
    previewer = references_previewer(symbol),
  })
end

return {
  {
    "ibhagwan/fzf-lua",
    opts = {
      grep = {
        previewer = grep_previewer(),
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "gr", lsp_references, desc = "References", nowait = true },
          },
        },
      },
    },
  },
}
