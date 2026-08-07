-- diagnostics.lua -- diagnostics rendered in the chip identity (2026-07-31).
--
-- Before this file there was NO vim.diagnostic.config anywhere in the config:
-- `grep -rn "virtual_text\|diagnostic.config" lua/` returned nothing, so the
-- single loudest, most-often-onscreen element in the editor was running pure
-- LazyVim stock -- default red, default "●" prefix, default sign column -- in
-- a setup where the punctuation split and the yaml key bolding are hand-tuned.
--
-- THE CORE MOVE: the full message renders BELOW the cursor's line and nowhere
-- else; every other diagnostic collapses to a short mark at EOL. Both halves
-- are native and need no autocmd:
--   virtual_lines = { current_line = true  }  -- full text, cursor line only
--   virtual_text  = { current_line = false }  -- short mark, cursor line NEVER
-- The `current_line == false -> hide on that line` branch is real and shared by
-- both renderers (runtime/lua/vim/diagnostic.lua:1885-1886, nvim 0.12); the
-- redraw autocmd is installed by nvim itself at :1948. That is what keeps a
-- 200-char type error from shoving code off-screen while still being readable
-- the instant the cursor is on it -- and why the two never double up.
--
-- SEVERITY IS A WEIGHT RAMP, NOT FOUR HUES. Error and warn keep the identity
-- error/warn colours already used by bufferline.lua's diagnostics_indicator
-- (#ff4444 / #e8d44d). Info and hint do NOT get their own hue -- they are the
-- identity dim teal at two steps of brightness. Four competing colours is
-- noise; two hues plus a ramp is a system.
--
-- SIGNS ARE OFF. bufferline.lua already counts errors/warnings per buffer with
-- its ✘/▲ glyphs, and statuscolumn.lua deliberately trimmed that column down to
-- real signs only. Repeating the same count in the gutter is duplicate ink.
--
-- NO BACKGROUNDS. Every group here is fg/sp only, same rule as focus-fx.lua:
-- a bg would be an opaque slab under ghostty background-opacity (the trap that
-- bit bufferline.lua and incline's chip on 07-31), and backgrounds belong to
-- the theme regardless.
--
-- Toggle live with :DiagFx (chip <-> LazyVim stock) to A/B it.

-- identity palette -- the same constants as bufferline.lua / focus-fx.lua.
-- (These three files each hardcode the set; a shared identity module is the
-- obvious follow-up, deliberately not done here to keep this change one file.)
local ERR = "#ff4444"
local WARN = "#e8d44d"
local INFO = "#307a74" -- identity dim
local HINT = "#265c58" -- identity dim, one step down

-- Left pill cap U+E0B6, as byte escapes on purpose: raw nerd-font glyphs have
-- been stripped to "" by an editing pipeline in this config before (see the
-- note in bufferline.lua's diagnostics_indicator). Same glyph the incline chip
-- opens with, so a diagnostic reads as part of the chrome, not an intruder.
local CAP = "\238\130\182"

local SEV = vim.diagnostic.severity

local COLORS = {
  [SEV.ERROR] = ERR,
  [SEV.WARN] = WARN,
  [SEV.INFO] = INFO,
  [SEV.HINT] = HINT,
}

local NAMES = {
  [SEV.ERROR] = "Error",
  [SEV.WARN] = "Warn",
  [SEV.INFO] = "Info",
  [SEV.HINT] = "Hint",
}

-- Long messages are truncated in the EOL mark only. The untruncated text is
-- always one cursor-move away in the virtual_lines block, so nothing is lost --
-- this is purely about the mark staying a mark instead of becoming a paragraph.
local MAX_INLINE = 60

local function stamp_highlights()
  for sev, name in pairs(NAMES) do
    local c = COLORS[sev]
    -- base group: drives the float, the location list, and anything that links
    -- to Diagnostic<Sev> without asking for a variant
    pcall(vim.api.nvim_set_hl, 0, "Diagnostic" .. name, { fg = c })
    -- EOL mark. Error is the only one that gets bold -- the weight ramp is the
    -- hierarchy, so warn/info/hint must NOT also be bold or it flattens.
    pcall(vim.api.nvim_set_hl, 0, "DiagnosticVirtualText" .. name, {
      fg = c,
      bg = "NONE",
      bold = sev == SEV.ERROR,
      italic = false,
    })
    -- the full block under the cursor line (nvim 0.11+ groups)
    pcall(vim.api.nvim_set_hl, 0, "DiagnosticVirtualLines" .. name, {
      fg = c,
      bg = "NONE",
      italic = false,
    })
    -- undercurl in the severity colour rather than an underline: an underline
    -- competes with the indent ladder rungs, a curl does not.
    pcall(vim.api.nvim_set_hl, 0, "DiagnosticUnderline" .. name, {
      undercurl = true,
      underline = false,
      sp = c,
    })
    pcall(vim.api.nvim_set_hl, 0, "DiagnosticFloating" .. name, { fg = c, bg = "NONE" })
  end
end

local chip_opts = {
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  -- see the header: bufferline already carries the per-buffer counts
  signs = false,
  virtual_text = {
    current_line = false, -- never on the cursor line; virtual_lines owns it
    spacing = 2,
    source = false, -- "if_many" appends "(lua_ls)" and doubles the mark's width
    prefix = CAP,
    format = function(d)
      local msg = (d.message or ""):gsub("%s+", " ")
      if #msg > MAX_INLINE then msg = msg:sub(1, MAX_INLINE - 1) .. "…" end
      return msg
    end,
  },
  virtual_lines = {
    current_line = true, -- full, wrapped, readable -- only where you are
  },
  float = {
    border = "rounded",
    source = "if_many",
    header = "",
    prefix = "",
  },
}

-- :DiagFx --------------------------------------------------------------------
-- Flip to LazyVim stock and back without restarting, so the two can be compared
-- on the same buffer. Stock is reconstructed here rather than captured, because
-- whatever is live at the time this file runs is already ours on a reload.
local stock_opts = {
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
  virtual_lines = false,
  signs = {
    text = {
      [SEV.ERROR] = " ",
      [SEV.WARN] = " ",
      [SEV.HINT] = " ",
      [SEV.INFO] = " ",
    },
  },
}

local mode = "chip"

local function apply(which)
  mode = which
  if which == "chip" then
    stamp_highlights()
    vim.diagnostic.config(vim.deepcopy(chip_opts))
  else
    vim.diagnostic.config(vim.deepcopy(stock_opts))
  end
  vim.notify("diagnostics: " .. which, vim.log.levels.INFO)
end

-- Registration runs at module scope, NOT from an `init` on a plugin spec.
-- First attempt hung this off a second { "LazyVim/LazyVim", init = ... }
-- fragment; lazy.nvim does not merge `init` across fragments for the same
-- plugin, so it was silently dropped -- :DiagFx did not exist and the stamped
-- groups were still the theme's (measured headless, 07-31). Worse, had it won
-- the merge instead it would have REPLACED LazyVim's own init. This file is
-- required while lazy evaluates the spec, i.e. at startup, which is early
-- enough for a user command and an autocmd and owns nothing else.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("DiagFxStamp", { clear = true }),
  callback = function()
    if mode == "chip" then stamp_highlights() end
  end,
})
stamp_highlights()

-- Apply immediately as well as via the lspconfig opts below. The opts merge is
-- what SURVIVES (LazyVim re-applies the table on its lspconfig config()), but
-- lspconfig is lazy-loaded on BufReadPre -- until a real file is open nothing
-- has called vim.diagnostic.config at all, so without this the defaults are
-- live. Both paths set the same table, so whichever lands last is identical.
vim.diagnostic.config(vim.deepcopy(chip_opts))

vim.api.nvim_create_user_command("DiagFx", function(a)
  local arg = a.args ~= "" and a.args or (mode == "chip" and "stock" or "chip")
  if arg ~= "chip" and arg ~= "stock" then
    return vim.notify("DiagFx: chip | stock", vim.log.levels.WARN)
  end
  apply(arg)
end, {
  nargs = "?",
  complete = function() return { "chip", "stock" } end,
  desc = "diagnostics: chip identity <-> LazyVim stock",
})

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Merge into LazyVim's table rather than calling vim.diagnostic.config
      -- directly: LazyVim applies opts.diagnostics itself in its lspconfig
      -- config() (lazyvim/plugins/lsp/init.lua:224), so a raw call from this
      -- file would simply be overwritten on LspAttach. `signs = false` replaces
      -- the inherited signs TABLE, which is the intent.
      opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, chip_opts)
      opts.diagnostics.signs = false
      return opts
    end,
  },
}
