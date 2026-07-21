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

local hash_comment_extensions = {
  bash = true,
  conf = true,
  dockerfile = true,
  hcl = true,
  makefile = true,
  py = true,
  rb = true,
  sh = true,
  tf = true,
  tfvars = true,
  toml = true,
  yaml = true,
  yml = true,
  zsh = true,
}

local slash_comment_extensions = {
  c = true,
  cc = true,
  cpp = true,
  css = true,
  go = true,
  hcl = true,
  java = true,
  js = true,
  jsx = true,
  less = true,
  rs = true,
  scss = true,
  tf = true,
  ts = true,
  tsx = true,
}

local dash_comment_extensions = {
  lua = true,
  sql = true,
}

local function grep_without_comment_lines(line, opts)
  if type(line) ~= "string" then
    return nil
  end

  local utils = require("fzf-lua.utils")
  local plain = utils.strip_ansi_coloring(line)
  if plain:match("^vim%.schedule callback:") or plain:match("^stack traceback:") or plain:match("^%s") then
    return nil
  end

  local path, text = plain:match("^(.-):%d+:%d+:(.*)$")
  if not path then
    path, text = plain:match("^(.-):%d+:(.*)$")
  end
  if not path or not text then
    return nil
  end

  local filename = vim.fs.basename(path):lower()
  local extension = filename:match("%.([^./]+)$") or filename
  local is_comment = (hash_comment_extensions[extension] and text:match("^%s*#"))
    or (
      slash_comment_extensions[extension]
      and (text:match("^%s*//") or text:match("^%s*/%*"))
    )
    or (dash_comment_extensions[extension] and text:match("^%s*%-%-"))
    or (
      (extension == "html" or extension == "md" or extension == "xml")
      and text:match("^%s*<!%-%-")
    )
    or (extension == "vim" and text:match('^%s*"'))

  if is_comment then
    return nil
  end
  return line
end

local function grep_picker(command, opts)
  return LazyVim.pick(command, vim.tbl_extend("force", {
    fn_transform = grep_without_comment_lines,
  }, opts or {}))
end

local function grep_directory(opts)
  opts = opts or {}
  if opts.root == false then
    return (vim.uv or vim.loop).cwd()
  end
  return LazyVim.root({ buf = vim.api.nvim_get_current_buf(), normalize = true })
end

local function grep_options(opts)
  local options = vim.tbl_extend("force", {}, opts or {})
  options.cwd = options.cwd or grep_directory(options)
  options.fn_transform = grep_without_comment_lines
  options.root = nil
  return options
end

local function grep_direct(command, opts)
  return function()
    require("fzf-lua")[command](grep_options(opts))
  end
end

local function grep_current_file_directory()
  local directory = vim.fn.expand("%:p:h")
  if directory == "" then
    vim.notify("Current buffer has no file directory", vim.log.levels.WARN)
    return
  end

  require("fzf-lua").live_grep({
    cwd = directory,
    fn_transform = grep_without_comment_lines,
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
    keys = {
      { "<leader>sg", grep_picker("live_grep"), desc = "Grep, No Comments (Root Dir)" },
      { "<leader>sG", grep_picker("live_grep", { root = false }), desc = "Grep, No Comments (cwd)" },
      { "<leader>sF", grep_current_file_directory, desc = "Grep current file directory" },
      { "<leader>sw", grep_direct("grep_cword"), desc = "Word, No Comments (Root Dir)" },
      { "<leader>sW", grep_direct("grep_cword", { root = false }), desc = "Word, No Comments (cwd)" },
      {
        "<leader>sw",
        grep_direct("grep_visual"),
        mode = "x",
        desc = "Selection, No Comments (Root Dir)",
      },
      {
        "<leader>sW",
        grep_direct("grep_visual", { root = false }),
        mode = "x",
        desc = "Selection, No Comments (cwd)",
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
