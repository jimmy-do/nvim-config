-- Bufferline restyled to the tmux/incline chip identity (07-31, Jimmy's ask:
-- the stock tabs looked like grey boxes with "!" noise).
--
-- Identity palette, deliberately OURS and not the theme's (same rule as the
-- incline chips in focus-fx.lua): accent #66fff2, dim #307a74, chip bg #101410.
-- Active tab = accent text, nothing else -- no chip bg, no underline (both were
-- removed 2026-07-31, see below); inactive tabs = dim teal. The accent/dim
-- FOREGROUND split is the entire selection cue. The "×" close buttons are gone
-- (buffers die via <leader>bd), and diagnostics render as a count in the
-- identity error/warn colours instead of the stock "!" glyph.
--
-- Offset separator note (kept from the original file): WinSeparator only
-- paints inside the window grid, so the divider stopped dead at the tab bar.
-- bufferline/offset.lua renders no edge glyph unless `separator` is set, and
-- LazyVim's default offsets omit the key. Mutate the inherited list rather
-- than redeclaring it so new LazyVim offsets keep working.

local ACCENT = "#66fff2"
local DIM = "#307a74"
-- 2026-07-31: was "#101410". That is an OPAQUE near-black, and it only ever
-- looked like a "lifted chip" because the terminal bg sat one shade below it.
-- Under ghostty background-opacity every other group here is bg="NONE" and
-- sees through, so this constant became the one opaque thing in the bar -- the
-- active tab turned into a black slab with black wedges at its ends. Put a hex
-- back here and the wedges come back with it.
--
-- The underline that used to accompany this is ALSO gone (2026-07-31): Jimmy's
-- call, "remove the line glow underneath the active buffer, it's buggy and
-- annoying -- the glowing in the active buffer name is good enough". Do not
-- reintroduce `underline = true, sp = ACCENT` anywhere in this file.
local CHIP_BG = "NONE"
local ORANGE = "#FF8500" -- modified dot, same as the insert-mode identity
local ERR = "#ff4444"
local WARN = "#e8d44d"

return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      for _, offset in ipairs(vim.tbl_get(opts, "options", "offsets") or {}) do
        offset.separator = true
      end

      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        -- a plain space as separator + transparent bgs = a 1-cell gap
        -- between chips instead of butted grey boxes
        separator_style = { " ", " " },
        indicator = { style = "none" }, -- accent vs dim fg is the indicator
        show_buffer_close_icons = false,
        show_close_icon = false,
        modified_icon = "●",
        tab_size = 0, -- shrink-wrap each chip to its name
        -- snipe tag on each tab: the letter gb+<tag> will summon this buffer
        -- with. Same tag_map the gb menu reads (persist_tags pins bufnr->tag),
        -- assigned eagerly here so the letter is known BEFORE the menu opens.
        -- Everything pcall'd: snipe is lazy-loaded and this must never take
        -- down the tabline.
        numbers = function(o)
          local ok, snipe = pcall(require, "snipe")
          local menu = ok and snipe.global_menu or nil
          if not menu or not menu.tag_map then return "" end
          local ok2, tag = pcall(function()
            return menu:_get_persistent_tag_for(o.id)
          end)
          if not ok2 or type(tag) ~= "table" or not tag.name then return "" end
          return tag.name .. (tag.ord and tag.ord > 0 and tag.ord or "")
        end,
        diagnostics_indicator = function(_, _, diag)
          local out = {}
          -- non-private-use glyphs on purpose: nerd-font icons got stripped
          -- to "" by an editing pipeline once already
          if diag.error then out[#out + 1] = "\226\156\152 " .. diag.error end -- ✘
          if diag.warning then out[#out + 1] = "\226\150\178 " .. diag.warning end -- ▲
          return #out > 0 and table.concat(out, " ") or ""
        end,
      })

      local active = { fg = ACCENT, bg = CHIP_BG, bold = true, italic = false }
      opts.highlights = vim.tbl_deep_extend("force", opts.highlights or {}, {
        fill = { bg = "NONE" },
        background = { fg = DIM, bg = "NONE", italic = false },
        buffer_selected = active,
        -- visible-but-unfocused (shown in another split): mid-bright, no chip bg
        buffer_visible = { fg = ACCENT, bg = "NONE", bold = false, italic = false },
        separator = { fg = "NONE", bg = "NONE" },
        separator_visible = { fg = "NONE", bg = "NONE" },
        separator_selected = { fg = "NONE", bg = "NONE" },
        duplicate = { fg = DIM, bg = "NONE", italic = true },
        duplicate_visible = { fg = DIM, bg = "NONE", italic = true },
        duplicate_selected = { fg = DIM, bg = CHIP_BG, italic = true },
        modified = { fg = ORANGE, bg = "NONE" },
        modified_visible = { fg = ORANGE, bg = "NONE" },
        modified_selected = { fg = ORANGE, bg = CHIP_BG },
        error = { fg = DIM, bg = "NONE" },
        error_visible = { fg = DIM, bg = "NONE" },
        error_selected = { fg = ACCENT, bg = CHIP_BG, bold = true },
        error_diagnostic = { fg = ERR, bg = "NONE" },
        error_diagnostic_visible = { fg = ERR, bg = "NONE" },
        error_diagnostic_selected = { fg = ERR, bg = CHIP_BG },
        warning = { fg = DIM, bg = "NONE" },
        warning_visible = { fg = DIM, bg = "NONE" },
        warning_selected = { fg = ACCENT, bg = CHIP_BG, bold = true },
        warning_diagnostic = { fg = WARN, bg = "NONE" },
        warning_diagnostic_visible = { fg = WARN, bg = "NONE" },
        warning_diagnostic_selected = { fg = WARN, bg = CHIP_BG },
        hint = { fg = DIM, bg = "NONE" },
        hint_selected = { fg = ACCENT, bg = CHIP_BG },
        info = { fg = DIM, bg = "NONE" },
        info_selected = { fg = ACCENT, bg = CHIP_BG },
        -- was fg=CHIP_BG,bg=CHIP_BG -- i.e. "hide it by painting it the chip
        -- colour". With CHIP_BG transparent that trick is meaningless; state it
        -- as NONE/NONE directly, matching indicator_visible.
        indicator_selected = { fg = "NONE", bg = "NONE" },
        indicator_visible = { fg = "NONE", bg = "NONE" },
        -- snipe tags: a notch brighter than the dim tab text so the letter is
        -- scannable at a glance; bold everywhere so it reads as a key, not a
        -- word fragment
        numbers = { fg = "#5ad9cc", bg = "NONE", bold = true, italic = false },
        numbers_visible = { fg = "#5ad9cc", bg = "NONE", bold = true, italic = false },
        numbers_selected = { fg = ACCENT, bg = CHIP_BG, bold = true, italic = false },
      })
    end,
  },
}
