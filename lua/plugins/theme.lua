-- ── Tuning knobs ─────────────────────────────────────────────────────────────
local sepia_amount = 5 -- 0-100, sepia intensity. 0 = off, 50 = half sepia, 100 = full sepia
local bg_transparency = 40 -- 0 = opaque, 50 = default (0.20 base + 1.00 extra for core groups), 100 = fully transparent
local fg_lightness = 50 -- 0-100, HSL L channel. 50 = original, <50 = darker, >50 = brighter
local fg_saturation = 40 -- 0-100, HSL S channel. 50 = original, 0 = grayscale, 100 = max vivid
local darken_background = 52 -- 0-100, bg luminance. 50 = original, 0 = #000000, 100 = #cccccc
local normalize_background = 0 -- 0-100, bg saturation toward neutral gray (same luminance). 0 = original hue, 100 = fully neutral

-- Extra transparent groups applied only when habamax is active
local habamax_extra_transparent = {
  "^TabLine",
}

-- Groups whose bg is set to nil (or gets extra blend) — the "see-through" layer
local transparent_bg_groups = {
  "^Normal$",
  "^NormalNC$",
  "^EndOfBuffer$",
  "^LineNr",
  "^CursorLineNr$",
  "^SignColumn$",
  "^FoldColumn$",
  "^Folded$",
  "^ColorColumn$",
  "^CursorLine$",
  "^CursorColumn$",
  "^StatusColumn$",
  "^NeoTree",
}

-- Color used globally for periods, {{}} and [[]] (catppuccin blue / soft periwinkle)
-- Change this one constant to re-tune all three features at once.
local PUNCT_BLUE = "#9bb0e0"

-- Groups that must stay opaque regardless of transparency setting
-- fzf-lua is explicitly listed here so it is never blurred/transparent
local opaque_groups = {
  "^NormalFloat$",
  "^FloatBorder$",
  "^FloatTitle$",
  "^FloatFooter$",
  "^Pmenu",
  "^WildMenu$",
  "^CmdLine",
  "^MsgArea$",
  "^MsgSeparator$",
  "^ModeMsg$",
  "^MoreMsg$",
  "^Question$",
  "^NoiceCmdline",
  "^NoiceMini$",
  "^NoicePopup",
  "^NoiceConfirm",
  "^FzfLua",
  "^Fzf",
  "^fzf",
  "^SnacksPicker",
  "^SnacksInput",
  "^Telescope",
}

-- Groups excluded from FG adjustments (sepia fg, fg_lightness, fg_saturation).
-- These still receive BG adjustments (darken_background, bg_transparency).
-- Tab/bufferline groups have their own carefully-tuned fg colors that break
-- visually when our global fg knobs touch them.
local fg_protected_groups = {
  "^TabLine",
  "^TabLineFill",
  "^TabLineSel",
  "^BufferLine",
  "^BufferLineFill",
  "^WinBar",
  "^WinBarNC",
}

-- ── Color math ───────────────────────────────────────────────────────────────
local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function clamp_color(v)
  return math.max(0, math.min(255, math.floor(v + 0.5)))
end

local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x", clamp_color(r), clamp_color(g), clamp_color(b))
end

local function sepia_hex(color, amount)
  local r, g, b = hex_to_rgb(color)
  local sr = r * 0.393 + g * 0.769 + b * 0.189
  local sg = r * 0.349 + g * 0.686 + b * 0.168
  local sb = r * 0.272 + g * 0.534 + b * 0.131
  return rgb_to_hex(r + (sr - r) * amount, g + (sg - g) * amount, b + (sb - b) * amount)
end

-- ── RGB ↔ HSL helpers ────────────────────────────────────────────────────────
local function rgb_to_hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local l = (max + min) / 2
  local h, s = 0, 0
  if max ~= min then
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    else
      h = (r - g) / d + 4
    end
    h = h / 6
  end
  return h * 360, s * 100, l * 100
end

local function hsl_to_rgb(h, s, l)
  h, s, l = h / 360, s / 100, l / 100
  local r, g, b
  if s == 0 then
    r, g, b = l, l, l
  else
    local function hue(p, q, t)
      if t < 0 then
        t = t + 1
      end
      if t > 1 then
        t = t - 1
      end
      if t < 1 / 6 then
        return p + (q - p) * 6 * t
      end
      if t < 1 / 2 then
        return q
      end
      if t < 2 / 3 then
        return p + (q - p) * (2 / 3 - t) * 6
      end
      return p
    end
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue(p, q, h + 1 / 3)
    g = hue(p, q, h)
    b = hue(p, q, h - 1 / 3)
  end
  return r * 255, g * 255, b * 255
end

local function adjust_fg_hsl(hex, lightness_level, saturation_level)
  local r, g, b = hex_to_rgb(hex)
  local h, s, l = rgb_to_hsl(r, g, b)
  if lightness_level ~= 50 then
    if lightness_level < 50 then
      l = l * (lightness_level / 50)
    else
      l = l + (100 - l) * ((lightness_level - 50) / 50)
    end
  end
  if saturation_level ~= 50 then
    if saturation_level < 50 then
      s = s * (saturation_level / 50)
    else
      s = s + (100 - s) * ((saturation_level - 50) / 50)
    end
  end
  l = math.max(0, math.min(100, l))
  s = math.max(0, math.min(100, s))
  return rgb_to_hex(hsl_to_rgb(h, s, l))
end

local function resolve_transparency()
  if bg_transparency <= 50 then
    local f = bg_transparency / 50
    return 0.20 * f, 1.00 * f
  else
    local f = (bg_transparency - 50) / 50
    return math.min(0.20 + (1.0 - 0.20) * f, 1.0), 1.0
  end
end

local function normalize_bg_adjust(hex, level)
  if level == 0 then
    return hex
  end
  local r, g, b = hex_to_rgb(hex)
  local gray = (r + g + b) / 3
  local factor = level / 100
  return rgb_to_hex(r + (gray - r) * factor, g + (gray - g) * factor, b + (gray - b) * factor)
end

local function darken_bg_adjust(hex, level)
  if level == 50 then
    return hex
  end
  local r, g, b = hex_to_rgb(hex)
  local function adj(c, target)
    if level < 50 then
      return c * (level / 50)
    else
      return c + (target - c) * ((level - 50) / 50)
    end
  end
  return rgb_to_hex(adj(r, 0xcc), adj(g, 0xcc), adj(b, 0xcc))
end

local function color_to_hex(color)
  if type(color) == "number" then
    return string.format("#%06x", color)
  end
  return color
end

local function normalize_hex(color)
  local hex = color_to_hex(color)
  if type(hex) == "string" and hex:match("^#?%x%x%x%x%x%x$") then
    return "#" .. hex:gsub("#", "")
  end
end

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function matches(group, patterns)
  for _, p in ipairs(patterns) do
    if group:match(p) then
      return true
    end
  end
  return false
end

local function normal_bg()
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
  if ok and hl.bg then
    return color_to_hex(hl.bg)
  end
  return "#181616"
end

local function opaque_ui_bg()
  local function bg(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl.bg then
      return color_to_hex(hl.bg)
    end
  end
  return bg("NormalFloat") or bg("Pmenu") or bg("Normal") or "#0d0c0c"
end

-- ── fzf-lua: force opaque ─────────────────────────────────────────────────────
local function apply_fzf_opaque_highlights()
  local bg = opaque_ui_bg()
  local function fg(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl.fg then
      return color_to_hex(hl.fg)
    end
  end
  vim.api.nvim_set_hl(0, "FzfLuaNormal", { bg = bg, fg = fg("Normal") or "#c5c9c5", blend = 0 })
  vim.api.nvim_set_hl(0, "FzfLuaBorder", { bg = bg, fg = "#737c73", blend = 0 })
  vim.api.nvim_set_hl(0, "FzfLuaPreviewNormal", { bg = bg, blend = 0 })
  vim.api.nvim_set_hl(0, "FzfLuaPreviewBorder", { bg = bg, fg = "#737c73", blend = 0 })
  vim.api.nvim_set_hl(0, "FzfLuaFzfNormal", { link = "FzfLuaNormal" })
  vim.api.nvim_set_hl(0, "FzfLuaFzfGutter", { link = "FzfLuaNormal" })
end

-- ── Global period / bracket overlays (all filetypes) ─────────────────────────
local function apply_global_punct_highlights()
  local theme = vim.g.colors_name or ""
  if not (theme:match("^kanagawa") or theme:match("^gruvbox")) then
    pcall(vim.api.nvim_set_hl, 0, "GlobalPunctBlue", {})
    pcall(vim.api.nvim_set_hl, 0, "GlobalUrlReset", {})
    return
  end
  -- Seed the two groups; adjust_all_highlights will sepia-tint them if sepia > 0
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
  local norm_fg = (ok and hl.fg) and color_to_hex(hl.fg) or "#c5c9c5"
  -- For kanagawa, paint URLs in the golden identifier/constant color instead of near-white
  local url_fg = norm_fg
  if (vim.g.colors_name or ""):match("^kanagawa") then
    local c_ok, c_hl = pcall(vim.api.nvim_get_hl, 0, { name = "Constant", link = false })
    if c_ok and c_hl.fg then
      url_fg = color_to_hex(c_hl.fg)
    end
  end
  vim.api.nvim_set_hl(0, "GlobalPunctBlue", { fg = PUNCT_BLUE })
  vim.api.nvim_set_hl(0, "GlobalUrlReset", { fg = url_fg })
end

local function clear_global_punct_matches()
  if type(vim.w.global_punct_match_ids) == "table" then
    for _, id in ipairs(vim.w.global_punct_match_ids) do
      pcall(vim.fn.matchdelete, id)
    end
  end
  vim.w.global_punct_match_ids = nil
end

local function apply_global_punct_matches()
  local theme = vim.g.colors_name or ""
  if not (theme:match("^kanagawa") or theme:match("^gruvbox")) then
    clear_global_punct_matches()
    return
  end
  clear_global_punct_matches()
  local ids = {}
  local function add(group, pattern, priority)
    local ok, id = pcall(vim.fn.matchadd, group, pattern, priority)
    if ok then
      table.insert(ids, id)
    end
  end
  -- All periods at priority 95; full URLs override back to normal at 96
  add("GlobalPunctBlue", [[\v\.]], 95)
  add("GlobalUrlReset", [[\vhttps?://\S+]], 96)
  -- {{ }} and [[ ]] — double-curly (Helm/Jinja) and double-square (Lua/Markdown/Neorg)
  add("GlobalPunctBlue", [[\v\{\{|\}\}]], 95)
  add("GlobalPunctBlue", [=[\v\[\[|\]\]]=], 95)
  vim.w.global_punct_match_ids = ids
end

-- ── Main highlight post-processor ────────────────────────────────────────────
local adjust_base_highlights
local adjust_base_name

local function read_highlights()
  local ok, all = pcall(vim.api.nvim_get_hl, 0, {})
  return ok and type(all) == "table" and all or {}
end

local function capture_base()
  adjust_base_name = vim.g.colors_name or ""
  adjust_base_highlights = read_highlights()
end

local function get_highlights()
  if not (adjust_base_highlights and adjust_base_name == (vim.g.colors_name or "")) then
    return read_highlights()
  end
  -- Always start from pristine cached state so every pipeline run sees original theme colors
  local merged = {}
  for k, v in pairs(adjust_base_highlights) do
    merged[k] = vim.deepcopy(v)
  end
  -- Add only groups that appeared AFTER the base was captured (plugin-injected groups)
  -- Groups already in the base keep their cached version; current modified state is ignored
  for k, v in pairs(read_highlights()) do
    if adjust_base_highlights[k] == nil then
      merged[k] = v
    end
  end
  return merged
end

local function adjust_all_highlights()
  local fallback_opaque_bg = darken_bg_adjust(
    sepia_hex(normalize_bg_adjust(opaque_ui_bg(), normalize_background), sepia_amount / 100),
    darken_background
  )

  for group, hl in pairs(get_highlights()) do
    if not hl.link then
      local adj = {}
      local changed = false

      for k, v in pairs(hl) do
        adj[k] = v
      end

      -- Pipeline per channel:
      --   bg:  normalize_background → sepia → darken_background → transparency
      --   fg:  sepia → fg_lightness/fg_saturation HSL  (fg_protected groups skip sepia+HSL)
      --   sp:  sepia only
      local fg_protected = matches(group, fg_protected_groups)
      for _, key in ipairs({ "fg", "bg", "sp" }) do
        local hex = normalize_hex(adj[key])
        if hex then
          if key == "bg" and normalize_background ~= 0 then
            hex = normalize_bg_adjust(hex, normalize_background)
            adj[key] = hex
          end
          if not (fg_protected and key == "fg") then
            adj[key] = sepia_hex(hex, sepia_amount / 100)
          end
          if key == "bg" and darken_background ~= 50 then
            adj[key] = darken_bg_adjust(adj[key], darken_background)
          end
          if key == "fg" and not fg_protected and (fg_lightness ~= 50 or fg_saturation ~= 50) then
            adj[key] = adjust_fg_hsl(adj[key], fg_lightness, fg_saturation)
          end
          changed = true
        end
      end

      -- Strip italics globally
      if adj.italic then
        adj.italic = false
        changed = true
      end

      -- Transparency
      if matches(group, opaque_groups) then
        adj.bg = adj.bg or fallback_opaque_bg
        adj.blend = 0
        changed = true
      elseif adj.bg then
        local base_transp, extra_transp_val = resolve_transparency()
        local t = base_transp
        local is_habamax = vim.g.colors_name == "habamax"
        if matches(group, transparent_bg_groups) or (is_habamax and matches(group, habamax_extra_transparent)) then
          t = math.min(t + extra_transp_val, 1)
        end
        if t >= 1 then
          adj.bg = nil
        elseif t > 0 then
          adj.blend = math.max(adj.blend or 0, math.floor(t * 100 + 0.5))
        end
        changed = true
      end

      if changed then
        vim.api.nvim_set_hl(0, group, adj)
      end
    end
  end

  -- Prevent Neovim's own float-level transparency from doubling up
  vim.o.winblend = 0
  vim.o.pumblend = 0
end

-- ── Shared helper: transparent top bar ───────────────────────────────────────
local function apply_transparent_top_bar()
  for _, group in ipairs({ "TabLine", "TabLineSel", "TabLineFill", "NeoTreeTitleBar", "WinBar", "WinBarNC" }) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok then
      local adj = {}
      for k, v in pairs(hl) do
        adj[k] = v
      end
      adj.bg = nil
      adj.blend = nil
      pcall(vim.api.nvim_set_hl, 0, group, adj)
    end
  end
end

-- ── Habamax-specific overrides ───────────────────────────────────────────────
local function apply_habamax_overrides()
  if vim.g.colors_name ~= "habamax" then
    return
  end
  -- Black thin separator bar between Neo-tree and editor
  pcall(vim.api.nvim_set_hl, 0, "WinSeparator", { fg = "#000000", bg = "#000000" })
  apply_transparent_top_bar()
end

-- ── Catppuccin-specific overrides ────────────────────────────────────────────
local function apply_catppuccin_overrides()
  if not (vim.g.colors_name or ""):match("^catppuccin") then
    return
  end
  apply_transparent_top_bar()
end

-- ── Kanagawa: soft-white fg overrides (runs after plugins reset their groups) ─
-- #c5c9c5: neutral cool gray-white, softer than Normal fg #DCD7BA, not warm/yellow
local KANAGAWA_SOFT_WHITE = "#c5c9c5"

local function apply_kanagawa_soft_overrides()
  local theme = vim.g.colors_name or ""
  if not (theme:match("^kanagawa") or theme:match("^gruvbox")) then
    return
  end
  local groups = {
    "NeoTreeFileName",
    "NeoTreeFileNameOpened",
    "NeoTreeDirectoryName",
    "NeoTreeRootName",
  }
  for _, group in ipairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok then
      local adj = {}
      for k, v in pairs(hl) do
        adj[k] = v
      end
      adj.fg = KANAGAWA_SOFT_WHITE
      pcall(vim.api.nvim_set_hl, 0, group, adj)
    end
  end
end

local function apply_theme_adjustments(refresh_base)
  apply_global_punct_highlights()
  if refresh_base or adjust_base_name ~= (vim.g.colors_name or "") then
    capture_base()
  end
  -- Run immediately + 3 deferred passes to catch plugins that set highlights late
  adjust_all_highlights()
  vim.schedule(adjust_all_highlights)
  vim.defer_fn(adjust_all_highlights, 50)
  vim.defer_fn(adjust_all_highlights, 200)
  vim.defer_fn(apply_fzf_opaque_highlights, 250)
  vim.defer_fn(apply_habamax_overrides, 250)
  vim.defer_fn(apply_catppuccin_overrides, 250)
  vim.defer_fn(apply_kanagawa_soft_overrides, 300)
end

-- ── Plugin specs ─────────────────────────────────────────────────────────────
return {
  {
    "rebelot/kanagawa.nvim",
    opts = {
      theme = "dragon",
      overrides = function(colors)
        local kw = colors.theme.syn.keyword
        local red = colors.theme.syn.preproc
        local function blend_toward_bg(hex, amount)
          local r1, g1, b1 = hex_to_rgb(color_to_hex(hex))
          local r2, g2, b2 = hex_to_rgb(color_to_hex(colors.theme.ui.bg))
          return rgb_to_hex(r1 + (r2 - r1) * amount, g1 + (g2 - g1) * amount, b1 + (b2 - b1) * amount)
        end
        return {
          Comment = { fg = blend_toward_bg(colors.theme.syn.comment, 0.45) },
          -- NeoTreeDirectoryName is also patched via apply_kanagawa_soft_overrides at 300ms
          -- (kanagawa overrides alone don't stick; NeoTree resets its groups after load)
          NeoTreeDirectoryName = { fg = KANAGAWA_SOFT_WHITE },
          ["@variable.member"] = { fg = colors.theme.syn.special1 },
          ["@constant.builtin"] = { fg = colors.theme.syn.identifier },
          ["@property.yaml"] = { fg = kw },
          ["@property"] = { fg = kw },
          ["@punctuation.special.yaml"] = { fg = red },
          -- Soft white (#c5c9c5): neutral cool gray-white, dimmer than Normal fg #DCD7BA
          ["@variable.helm"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@variable.gotmpl"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@lsp.type.variable.dockerfile"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@lsp.typemod.variable.declaration.dockerfile"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@markup.raw.markdown_inline"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@markup.raw.markdown"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@markup.plain.markdown"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@markup.strong.markdown_inline"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@markup.italic.markdown_inline"] = { fg = KANAGAWA_SOFT_WHITE },
          ["@function.builtin.helm"] = { fg = colors.theme.syn.type },
          ["@function.builtin.gotmpl"] = { fg = colors.theme.syn.type },
          ["@keyword.conditional.helm"] = { fg = red },
          ["@keyword.repeat.helm"] = { fg = red },
          ["@keyword.directive.helm"] = { fg = red },
          ["@keyword.directive.define.helm"] = { fg = red },
          ["@keyword.conditional.gotmpl"] = { fg = red },
          ["@keyword.repeat.gotmpl"] = { fg = red },
          ["@keyword.directive.gotmpl"] = { fg = red },
          ["@keyword.directive.define.gotmpl"] = { fg = red },
          ["@punctuation.bracket.helm"] = { fg = red },
          ["@punctuation.bracket.gotmpl"] = { fg = red },
          ["@punctuation.special.helm"] = { fg = red },
          ["@punctuation.special.gotmpl"] = { fg = red },
        }
      end,
    },
  },

  -- Keep fzf-lua fully opaque; it is an overlay, not part of the background layer
  {
    "ibhagwan/fzf-lua",
    opts = function(_, opts)
      opts = opts or {}
      opts.winopts = opts.winopts or {}
      opts.winopts.backdrop = false
      opts.winopts.winblend = 0
      opts.winopts.preview = opts.winopts.preview or {}
      opts.winopts.preview.winopts = opts.winopts.preview.winopts or {}
      opts.winopts.preview.winopts.winblend = 0
      opts.hls = vim.tbl_deep_extend("force", opts.hls or {}, {
        normal = "FzfLuaNormal",
        border = "FzfLuaBorder",
        preview_normal = "FzfLuaPreviewNormal",
        preview_border = "FzfLuaPreviewBorder",
        fzf = { normal = "FzfLuaFzfNormal", gutter = "FzfLuaFzfGutter" },
      })
      local fzf_colors = type(opts.fzf_colors) == "table" and opts.fzf_colors
        or opts.fzf_colors == true and { true }
        or {}
      opts.fzf_colors = vim.tbl_deep_extend("force", fzf_colors, {
        bg = { "bg", "FzfLuaFzfNormal" },
        gutter = { "bg", "FzfLuaFzfGutter" },
      })
      apply_fzf_opaque_highlights()
      return opts
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-dragon",
    },
    init = function()
      -- :ThemeAdjust to manually re-run the pipeline
      vim.api.nvim_create_user_command("ThemeAdjust", function()
        apply_theme_adjustments()
      end, {})

      -- :FgLightness / :FgSaturation / :FgAdjust — live HSL tuning
      local function set_fg_knob(name, setter, args)
        local val = tonumber(args)
        if not val or val < 0 or val > 100 then
          vim.notify(name .. ": expected a number 0–100", vim.log.levels.ERROR)
          return false
        end
        setter(val)
        return true
      end
      vim.api.nvim_create_user_command("FgLightness", function(opts)
        if set_fg_knob("FgLightness", function(v)
          fg_lightness = v
        end, opts.args) then
          apply_theme_adjustments()
        end
      end, { nargs = 1 })
      vim.api.nvim_create_user_command("FgSaturation", function(opts)
        if set_fg_knob("FgSaturation", function(v)
          fg_saturation = v
        end, opts.args) then
          apply_theme_adjustments()
        end
      end, { nargs = 1 })
      vim.api.nvim_create_user_command("FgAdjust", function(opts)
        local lv, sv = tonumber(opts.fargs[1]), tonumber(opts.fargs[2])
        if not lv or not sv or lv < 0 or lv > 100 or sv < 0 or sv > 100 then
          vim.notify("FgAdjust: expected two numbers 0–100, e.g. :FgAdjust 65 70", vim.log.levels.ERROR)
          return
        end
        fg_lightness, fg_saturation = lv, sv
        apply_theme_adjustments()
      end, { nargs = "+" })

      -- :Sepia <0-100> — live sepia intensity
      vim.api.nvim_create_user_command("Sepia", function(opts)
        if set_fg_knob("Sepia", function(v)
          sepia_amount = v
        end, opts.args) then
          apply_theme_adjustments()
        end
      end, { nargs = 1 })

      -- :BgTransparency <0-100> — live transparency tuning
      vim.api.nvim_create_user_command("BgTransparency", function(opts)
        if set_fg_knob("BgTransparency", function(v)
          bg_transparency = v
        end, opts.args) then
          apply_theme_adjustments()
        end
      end, { nargs = 1 })

      -- :DarkenBackground <0-100> — live bg luminance tuning
      vim.api.nvim_create_user_command("DarkenBackground", function(opts)
        if set_fg_knob("DarkenBackground", function(v)
          darken_background = v
        end, opts.args) then
          apply_theme_adjustments()
        end
      end, { nargs = 1 })

      -- :NormalizeBackground <0-100> — live bg hue neutralization toward gray
      vim.api.nvim_create_user_command("NormalizeBackground", function(opts)
        if
          set_fg_knob("NormalizeBackground", function(v)
            normalize_background = v
          end, opts.args)
        then
          apply_theme_adjustments()
        end
      end, { nargs = 1 })

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          apply_theme_adjustments(true)
          apply_global_punct_matches()
        end,
      })

      vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        pattern = "*",
        callback = apply_global_punct_matches,
      })
    end,
  },
  { "miikanissi/modus-themes.nvim", priority = 1000 },

  {
    "navarasu/onedark.nvim",
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require("onedark").setup({
        style = "warmer",
      })
    end,
  },

  {
    "f4z3r/gruvbox-material.nvim",
    name = "gruvbox-material",
    lazy = false,
    priority = 900,
  },

  {
    "sam4llis/nvim-tundra",
    lazy = false,
    priority = 1000,
  },

  {
    "zootedb0t/citruszest.nvim",
    lazy = false,
    priority = 1000,
  },

  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
  },

  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
  },

  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      colorscheme = "default",
    },
  },

  {
    "webhooked/kanso.nvim",
    lazy = false,
    priority = 1000,
  },

  -- Catppuccin: remap peach (orange) → red for constants/characters.
  -- Number, Float, Boolean intentionally keep their default peach.
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      highlight_overrides = {
        mocha = function(c)
          return {
            Constant = { fg = c.red },
            Character = { fg = c.red },
            ["@constant"] = { fg = c.red },
            ["@constant.builtin"] = { fg = c.red },
            ["@character"] = { fg = c.red },
            ["@character.special"] = { fg = c.red },
            ["@string.special.symbol"] = { fg = c.red },
          }
        end,
      },
    },
  },
}
