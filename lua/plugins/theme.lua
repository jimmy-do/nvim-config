-- ── Tuning knobs ─────────────────────────────────────────────────────────────
local sepia_amount = 0 -- -100..100, bipolar warm/cool. 0 = off, positive = sepia (warm), negative = anti-sepia (cool)
local bg_transparency = 100 -- 0 = opaque, 50 = default (0.20 base + 1.00 extra for core groups), 100 = fully transparent
local bg_brightness = 0 -- 0-100, sepia-aware bg brightness. 0 = dark, 50 = original, 100 = brighter
local fg_lightness = 50 -- 0-100, HSL L channel. 50 = original, <50 = darker, >50 = brighter
local fg_saturation = 40 -- 0-100, HSL S channel. 50 = original, 0 = grayscale, 100 = max vivid
local normalize_background = 0 -- 0-100, bg saturation toward neutral gray (same luminance). 0 = original hue, 100 = fully neutral
local chrome_darken = 50 -- 0 = pure black, 50 = original theme bg, 100 = fully transparent
local gruvbox_red_saturation = 100 -- gruvbox only: 100 = vivid GruvboxRed (if/end/keywords), lower = muted toward gray
local gruvbox_orange_saturation = 100 -- gruvbox only: 100 = vivid GruvboxOrange (Values/nindent/builtins), lower = muted toward gray
local gruvbox_yellow_saturation = 100 -- gruvbox only: 100 = vivid GruvboxYellow (@lsp.type.type / types), lower = muted toward gray
local gruvbox_green_saturation = 100 -- gruvbox only: 100 = vivid GruvboxGreen (String / @string), lower = muted toward gray
local gruvbox_fg1_lightness = 100 -- gruvbox only: white-font brightness. 100 = peak #ebdbb2, lower = dimmer cream (hue locked). Applied to Normal + GruvboxFg1.
local kanagawa_dragon_bracket_lightness = 50 -- kanagawa-dragon only: HSL L of the bracket color. 50 = original (#ded3b4), <50 = darker, >50 = brighter (warm ceiling). :DragonBracketLightness
local retrobox_string_lightness = 50 -- retrobox only: @string.yaml / @string.yaml.value.yaml / @string.helm lightness. 50 = original String.

-- Chrome groups: tab bar (top), NeoTree title (side), status line (bottom).
-- Controlled exclusively by chrome_darken. Other color knobs must not touch
-- their fg/bg/sp, otherwise changing FgAdjust/Sepia/bg knobs shifts the title
-- and tab bar even though chrome_darken is supposed to own that surface.
local chrome_groups = {
	"^TabLine",
	"^TabLineFill$",
	"^TabLineSel$",
	"^BufferLine",
	"^BufferLineFill$",
	"^WinBar$",
	"^WinBarNC$",
	"^StatusLine",
	"^NeoTreeTitleBar$",
}

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

-- The color used as the "behind nvim" reference when simulating transparency
-- via bg color blending. Default is pure black — matches Ghostty's default bg
-- and most terminals when nvim's bg is set to nil.
local TERMINAL_BG = "#000000"

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

-- Lualine accent pill groups use "colored bg + dark fg" design.
-- bg_brightness must NOT touch their bg — darkening the pill bg
-- makes the dark fg invisible. Protected from bg_brightness only;
-- sepia and normalize still apply normally.
local bg_brightness_protected_groups = {
	"^lualine_a_",
	"^lualine_z_",
}

-- Editor gutter / indent guide fg/sp is structural UI, not body text. Keep these
-- colorscheme-native across every theme and restore linked groups after the
-- pipeline so links like MiniIndentscopeSymbol -> GruvboxGray do not drift.
local editor_static_fg_groups = {
	"^LineNr",
	"^CursorLineNr$",
	"^NonText$",
	"^Whitespace$",
	"^SnacksIndent",
	"^IblIndent",
	"^IblWhitespace",
	"^IblScope",
	"^IndentBlankline",
	"^MiniIndentscope",
	"^BlinkIndent",
}

-- Groups excluded from the HSL text knobs only (fg_lightness, fg_saturation).
-- These still receive sepia and BG adjustments. FgAdjust is just the combined
-- lightness/saturation command, so this keeps statusline/lualine chrome stable
-- without blocking the other knobs from affecting that area.
local fg_hsl_protected_groups = {
	"^TabLine",
	"^TabLineFill",
	"^TabLineSel",
	"^BufferLine",
	"^BufferLineFill",
	"^WinBar",
	"^WinBarNC",
	"^StatusLine",
	"^StatusLineNC",
	"^lualine_",
	"^MiniStatusline",
}

-- Comment groups are left ENTIRELY alone by the global fg knobs (sepia,
-- fg_lightness, fg_saturation) — not just saturation. They keep their
-- colorscheme-native fg so they never blend into the background as the knobs are
-- turned. Per-theme comment adjusters may be added later; for now comments are
-- globally exempt.
local comment_protected_groups = {
	"^Comment$",
	"^SpecialComment$",
	"^@comment",
	"^@lsp%.type%.comment",
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
	-- Saturation in HSL: hue/lightness preserved, chroma scaled.
	if saturation_level ~= 50 then
		if saturation_level < 50 then
			s = s * (saturation_level / 50)
		else
			s = s + (100 - s) * ((saturation_level - 50) / 50)
		end
	end
	s = math.max(0, math.min(100, s))
	if lightness_level < 50 then
		-- Dim via HSL lightness scaling: hue and saturation are preserved, so warm
		-- gruvbox cream just gets darker (toward black) without losing its tint.
		l = math.max(0, math.min(100, l * (lightness_level / 50)))
		return rgb_to_hex(hsl_to_rgb(h, s, l))
	elseif lightness_level > 50 then
		-- Brighten toward a WARM ceiling, not pure white. Lifting HSL L all the way
		-- to 100 (the old behavior) collapses chroma — every hue converges to white
		-- — which wipes gruvbox's warm sepia cream. Cream (#ebdbb2) is already light
		-- (L≈81), so there's little headroom: we cap the lift at L=90 and boost
		-- saturation as we rise, keeping the warm tint intact. At max the cream gets
		-- brighter (e.g. ~#fff0cb) instead of washing out to #ffffff.
		local t = (lightness_level - 50) / 50 -- 0.0 (at 50) .. 1.0 (at 100)
		local l2 = l + (90 - l) * t
		if l2 < l then -- never dim in the brighten branch (cream already above 90)
			l2 = l
		end
		s = math.min(100, s * (1 + 0.8 * t))
		return rgb_to_hex(hsl_to_rgb(h, s, l2))
	end
	-- lightness_level == 50: lightness untouched (saturation may still differ).
	return rgb_to_hex(hsl_to_rgb(h, s, l))
end

-- Scale a color's HSL saturation by keep% (100 = unchanged, 0 = grayscale). Hue/Lightness preserved.
local function desaturate_hex(hex, keep)
	local r, g, b = hex_to_rgb(hex)
	local h, s, l = rgb_to_hsl(r, g, b)
	s = s * (math.max(0, math.min(100, keep)) / 100)
	return rgb_to_hex(hsl_to_rgb(h, s, l))
end

-- Lift fg's HSL Lightness to min_lightness if below that floor; H and S unchanged.
-- bg_hex is accepted for interface consistency but lightness floor is sufficient here.
local function ensure_readable_fg(fg_hex, _bg_hex, min_lightness)
	local r, g, b = hex_to_rgb(fg_hex)
	local h, s, l = rgb_to_hsl(r, g, b)
	if l < min_lightness then
		l = min_lightness
		return rgb_to_hex(hsl_to_rgb(h, s, l))
	end
	return fg_hex
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

local function bg_brightness_adjust(hex, level)
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

local function blend_to_terminal(hex, alpha)
	local r, g, b = hex_to_rgb(hex)
	local tr, tg, tb = hex_to_rgb(TERMINAL_BG)
	return rgb_to_hex(r + (tr - r) * alpha, g + (tg - g) * alpha, b + (tb - b) * alpha)
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

local function relative_luminance(hex)
	local function channel(v)
		v = v / 255
		if v <= 0.03928 then
			return v / 12.92
		end
		return ((v + 0.055) / 1.055) ^ 2.4
	end

	local r, g, b = hex_to_rgb(hex)
	return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

local function contrast_ratio(a, b)
	local la = relative_luminance(a)
	local lb = relative_luminance(b)
	if la < lb then
		la, lb = lb, la
	end
	return (la + 0.05) / (lb + 0.05)
end

local function readable_text_color(bg)
	return contrast_ratio(bg, "#000000") >= contrast_ratio(bg, "#ffffff") and "#000000" or "#ffffff"
end

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function clear_bg_attrs(hl)
	hl.bg = nil
	hl.ctermbg = nil
	hl.reverse = false
	if type(hl.cterm) == "table" then
		hl.cterm.reverse = false
	end
end

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
local function fzf_preview_search_bg(preview_bg)
	local candidates = {
		"#ffffff",
		"#000000",
		"#ffd75f",
		"#00d7ff",
		"#ff5faf",
		"#5fff87",
	}
	local best = candidates[1]
	local best_score = -1
	for _, candidate in ipairs(candidates) do
		local text = readable_text_color(candidate)
		local score = contrast_ratio(candidate, preview_bg) + contrast_ratio(candidate, text)
		if score > best_score then
			best = candidate
			best_score = score
		end
	end
	return best
end

local function apply_fzf_opaque_highlights()
	local bg = opaque_ui_bg()
	local search_bg = fzf_preview_search_bg(bg)
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
	vim.api.nvim_set_hl(0, "FzfLuaPreviewSearch", {
		bg = search_bg,
		fg = readable_text_color(search_bg),
		bold = true,
		blend = 0,
	})
	vim.api.nvim_set_hl(0, "FzfLuaPreviewMatch", {
		bg = "#ffd75f",
		fg = "#1f1f1f",
		bold = true,
		blend = 0,
	})
end

local KANAGAWA_DRAGON_BRACKET = "#ded3b4" -- base bracket color, before the lightness knob
local RETROBOX_BRACKET = "#d6c19c" -- muted tan for retrobox double brackets
local ONEDARK_DARK_ORIGINAL_PURPLE = "#d55fde"
local ONEDARK_DARK_SOFT_PURPLE = "#5194CB"

-- ── Global period / bracket overlays (all filetypes) ─────────────────────────
local function apply_global_punct_highlights()
	local theme = vim.g.colors_name or ""
	local full_punct_overlay = theme:match("^kanagawa") or theme:match("^gruvbox")
	local bracket_overlay = full_punct_overlay or theme == "retrobox"
	if not bracket_overlay then
		pcall(vim.api.nvim_set_hl, 0, "GlobalPunctBlue", {})
		pcall(vim.api.nvim_set_hl, 0, "GlobalPunctBracket", {})
		pcall(vim.api.nvim_set_hl, 0, "GlobalUrlReset", {})
		pcall(vim.api.nvim_set_hl, 0, "GlobalCommentReset", {})
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
	-- {{ }} / [[ ]] brackets ride on their own group so Dragon can recolor them
	-- (see apply_kanagawa_dragon_fixed_fg) without touching periods, which stay blue.
	-- Retrobox opts into only these double-bracket overlays with a muted tan that
	-- fits retrobox. Periods and other punctuation are not matched there.
	local bracket_fg = theme == "retrobox" and RETROBOX_BRACKET or PUNCT_BLUE
	vim.api.nvim_set_hl(0, "GlobalPunctBracket", { fg = bracket_fg })
	vim.api.nvim_set_hl(0, "GlobalUrlReset", { fg = url_fg })
	-- Periods / brackets / URLs inside comments must NOT pick up the blue period
	-- overlay — comments are left alone globally. GlobalCommentReset repaints the
	-- comment region (leader → EOL) back to the colorscheme-native comment fg at a
	-- higher priority than those overlays (see apply_global_punct_matches). It
	-- LINKS to Comment rather than copying its fg: copying captured a transient
	-- pre-pipeline value (greenish #7b8d6d instead of the final gray #737c73) and
	-- painted YAML comments green. A live link always resolves to Comment's current
	-- color, and is the per-theme hook for tweaking comments later.
	vim.api.nvim_set_hl(0, "GlobalCommentReset", { link = "Comment" })
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
	local full_punct_overlay = theme:match("^kanagawa") or theme:match("^gruvbox")
	local bracket_overlay = full_punct_overlay or theme == "retrobox"
	if not bracket_overlay then
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
	-- All periods at priority 95; full URLs override back to normal at 96.
	-- Retrobox intentionally skips these and only colors the double brackets below.
	if full_punct_overlay then
		add("GlobalPunctBlue", [[\v\.]], 95)
		add("GlobalUrlReset", [[\vhttps?://\S+]], 96)
	end
	-- {{ }} and [[ ]] — double-curly (Helm/Jinja) and double-square (Lua/Markdown/Neorg)
	add("GlobalPunctBracket", [[\v\{\{|\}\}]], 95)
	add("GlobalPunctBracket", [=[\v\[\[|\]\]]=], 95)
	-- Comment-region reset at priority 200 (above treesitter 100 and LSP semantic
	-- tokens 125, and above the period/bracket/url overlays at 95/96):
	-- repaint the comment leader → EOL back to the native comment color so nothing
	-- inside a comment is recolored by the global overlays. The leader is derived
	-- from the buffer's commentstring and must sit at line start or follow
	-- whitespace, so a '#' / '--' inside a string isn't treated as a comment.
	local leaders = {}
	local function add_leader(l)
		l = (l or ""):gsub("%s+$", "")
		if l ~= "" then
			leaders[l] = true
		end
	end
	add_leader((vim.bo.commentstring or ""):gsub("%%s.*$", ""))
	-- Helm's commentstring is the Go-template {{/* %s */}} form, so add '#' to also
	-- neutralize the YAML '#' comments that dominate Helm values/templates.
	if vim.bo.filetype == "helm" then
		add_leader("#")
	end
	for leader in pairs(leaders) do
		local esc = vim.fn.escape(leader, [[\.*$^~[]])
		add("GlobalCommentReset", [[\(^\|\s\)\zs]] .. esc .. [[.*$]], 200)
	end
	vim.w.global_punct_match_ids = ids
end

local function clear_onedark_dark_helm_trim_matches()
	if type(vim.w.onedark_dark_helm_trim_match_ids) == "table" then
		for _, id in ipairs(vim.w.onedark_dark_helm_trim_match_ids) do
			pcall(vim.fn.matchdelete, id)
		end
	end
	vim.w.onedark_dark_helm_trim_match_ids = nil
end

local function apply_onedark_dark_helm_trim_matches()
	clear_onedark_dark_helm_trim_matches()
	if vim.g.colors_name ~= "onedark_dark" or vim.bo.filetype ~= "helm" then
		return
	end
	vim.api.nvim_set_hl(0, "OneDarkDarkHelmTrimDelimiter", { link = "Delimiter" })
	local ids = {}
	local function add(pattern)
		local ok, id = pcall(vim.fn.matchadd, "OneDarkDarkHelmTrimDelimiter", pattern, 130)
		if ok then
			table.insert(ids, id)
		end
	end
	add([[\v\{\{\zs-]])
	add([[\v-\ze\}\}]])
	vim.w.onedark_dark_helm_trim_match_ids = ids
end

-- ── Main highlight post-processor ────────────────────────────────────────────
local adjust_base_highlights
local adjust_base_name
local adjust_base_editor_static_colors
local adjust_base_retrobox_string_fg

local retrobox_string_lightness_group_patterns = {
	"^String$",
	"^@string",
	"^@lsp%.type%.string",
}

local function read_highlights()
	local ok, all = pcall(vim.api.nvim_get_hl, 0, {})
	return ok and type(all) == "table" and all or {}
end

local function capture_base()
	adjust_base_name = vim.g.colors_name or ""
	adjust_base_highlights = read_highlights()
	adjust_base_editor_static_colors = {}
	adjust_base_retrobox_string_fg = nil
	if adjust_base_name == "retrobox" then
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "String", link = false })
		if ok and type(hl) == "table" and hl.fg then
			adjust_base_retrobox_string_fg = color_to_hex(hl.fg)
		end
	end
	for group in pairs(adjust_base_highlights) do
		if matches(group, editor_static_fg_groups) then
			local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
			if ok and type(hl) == "table" then
				local colors = {}
				if hl.fg then
					colors.fg = color_to_hex(hl.fg)
				end
				if hl.sp then
					colors.sp = color_to_hex(hl.sp)
				end
				if colors.fg or colors.sp then
					adjust_base_editor_static_colors[group] = colors
				end
			end
		end
	end
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

local function apply_editor_static_colors()
	if type(adjust_base_editor_static_colors) ~= "table" then
		return
	end
	for group, colors in pairs(adjust_base_editor_static_colors) do
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
		local adj = {}
		if ok and type(hl) == "table" then
			for k, v in pairs(hl) do
				adj[k] = v
			end
		end
		if colors.fg then
			adj.fg = colors.fg
		end
		if colors.sp then
			adj.sp = colors.sp
		end
		pcall(vim.api.nvim_set_hl, 0, group, adj)
	end
end

local function apply_retrobox_string_lightness()
	if vim.g.colors_name ~= "retrobox" then
		return
	end
	local source = adjust_base_retrobox_string_fg
	if not source then
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "String", link = false })
		if ok and type(hl) == "table" and hl.fg then
			source = color_to_hex(hl.fg)
		end
	end
	if not source then
		return
	end
	local fg = adjust_fg_hsl(source, retrobox_string_lightness, 50)
	for group in pairs(read_highlights()) do
		if matches(group, retrobox_string_lightness_group_patterns) then
			local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
			local adj = {}
			if ok and type(hl) == "table" then
				for k, v in pairs(hl) do
					adj[k] = v
				end
			end
			adj.fg = fg
			pcall(vim.api.nvim_set_hl, 0, group, adj)
		end
	end
	-- These language-specific captures are not always present in nvim_get_hl({}),
	-- but :Inspect reports them as linked to String. Set them directly so they
	-- follow this knob as soon as their parser/filetype appears.
	for _, group in ipairs({
		"@string.helm",
		"@string.yaml",
		"@string.yaml.value.yaml",
		"@string.terraform",
		"@lsp.type.string.terraform",
		"@string.python",
		"@string.documentation.python",
	}) do
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
		local adj = {}
		if ok and type(hl) == "table" then
			for k, v in pairs(hl) do
				adj[k] = v
			end
		end
		adj.fg = fg
		pcall(vim.api.nvim_set_hl, 0, group, adj)
	end
end

local function apply_onedark_dark_purple_overrides()
	if vim.g.colors_name ~= "onedark_dark" then
		return
	end
	for group, hl in pairs(read_highlights()) do
		if not hl.link then
			local adj
			local changed = false
			for _, key in ipairs({ "fg", "bg", "sp" }) do
				if normalize_hex(hl[key]) == ONEDARK_DARK_ORIGINAL_PURPLE then
					adj = adj or vim.deepcopy(hl)
					adj[key] = ONEDARK_DARK_SOFT_PURPLE
					changed = true
				end
			end
			if changed then
				pcall(vim.api.nvim_set_hl, 0, group, adj)
			end
		end
	end
end

-- ── Single source of truth for all theme transformations ─────────────────────
-- Every highlight group passes through this pipeline on each run:
--   bg:  normalize_background → sepia → bg_brightness → transparency blend
--   fg:  sepia → HSL (lightness + saturation)
--        editor_static/comment groups skip all fg transforms.
--        chrome groups skip all color transforms except chrome_darken bg handling.
--   sp:  sepia
-- transparent_bg_groups get bg blended toward TERMINAL_BG (or nil at t=1).
-- opaque_groups get bg forced to fallback_opaque_bg with blend=0.
-- All historical per-theme "manually fix tab/winbar bg" patches have been
-- removed — this pipeline handles them uniformly via transparent_bg_groups.
local function adjust_all_highlights()
	local fallback_opaque_bg = bg_brightness_adjust(
		sepia_hex(normalize_bg_adjust(opaque_ui_bg(), normalize_background), sepia_amount / 100),
		bg_brightness
	)

	for group, hl in pairs(get_highlights()) do
		if not hl.link then
			local adj = {}
			local changed = false

			for k, v in pairs(hl) do
				adj[k] = v
			end

			-- Pipeline per channel:
			--   bg:  normalize_background → sepia → bg_brightness → transparency
			--   fg:  sepia → fg_lightness/fg_saturation HSL
			--   sp:  sepia only
			local editor_static_fg = matches(group, editor_static_fg_groups)
			local fg_hsl_protected = matches(group, fg_hsl_protected_groups)
			-- Comments skip the ENTIRE fg pipeline (sepia + HSL lightness/saturation),
			-- so they stay at their colorscheme-native color regardless of the knobs.
			local comment_fg = matches(group, comment_protected_groups)
			local chrome_group = matches(group, chrome_groups)
			for _, key in ipairs({ "fg", "bg", "sp" }) do
				local hex = normalize_hex(adj[key])
				if hex then
					if key == "bg" and not chrome_group and normalize_background ~= 0 then
						hex = normalize_bg_adjust(hex, normalize_background)
						adj[key] = hex
					end
					if
						not (
							chrome_group
							or (editor_static_fg and (key == "fg" or key == "sp"))
							or (comment_fg and key == "fg")
						)
					then
						adj[key] = sepia_hex(hex, sepia_amount / 100)
					end
					if key == "bg" and not chrome_group and bg_brightness ~= 50 then
						if not matches(group, bg_brightness_protected_groups) then
							adj[key] = bg_brightness_adjust(adj[key], bg_brightness)
						end
					end
					if
						key == "fg"
						and not (chrome_group or editor_static_fg or fg_hsl_protected or comment_fg)
						and (fg_lightness ~= 50 or fg_saturation ~= 50)
					then
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

			-- Transparency / chrome
			if matches(group, opaque_groups) then
				adj.bg = adj.bg or fallback_opaque_bg
				adj.blend = 0
				changed = true
			elseif chrome_group then
				-- chrome_darken owns the bg for these groups entirely; bg_transparency is skipped.
				-- Exception: pill groups with "colored bg + dark fg" design keep their theme-native bg.
				if adj.bg then
					if chrome_darken < 50 then
						local factor = (50 - chrome_darken) / 50
						local r, g, b = hex_to_rgb(adj.bg)
						adj.bg = rgb_to_hex(r * (1 - factor), g * (1 - factor), b * (1 - factor))
					elseif chrome_darken > 50 then
						local factor = (chrome_darken - 50) / 50
						if factor >= 1 then
							adj.bg = nil
						else
							adj.bg = blend_to_terminal(adj.bg, factor)
							adj.blend = math.floor(factor * 100 + 0.5)
						end
					end
					-- chrome_darken == 50: leave adj.bg as-is (theme default after pipeline)
				end
				if chrome_darken >= 100 then
					clear_bg_attrs(adj)
				end
				changed = true
			elseif adj.bg then
				-- Lualine pill groups (a/z): skip transparency entirely. They already
				-- have explicit theme-distinct bg colors; any blend toward terminal_bg
				-- can wash them out, especially on themes (catppuccin) where the pill
				-- bg is already close to the editor bg. Bypassing here keeps pill
				-- color identity intact across all themes.
				if matches(group, bg_brightness_protected_groups) then
					changed = true
				else
					local base_transp, extra_transp_val = resolve_transparency()
					local t = base_transp
					local is_habamax = vim.g.colors_name == "habamax"
					if
						matches(group, transparent_bg_groups)
						or (is_habamax and matches(group, habamax_extra_transparent))
					then
						t = math.min(t + extra_transp_val, 1)
					end
					if t >= 1 then
						-- Fully transparent: nil out bg entirely
						clear_bg_attrs(adj)
					elseif t > 0 then
						-- Simulate gradient transparency by blending bg toward TERMINAL_BG
						adj.bg = blend_to_terminal(adj.bg, t)
						-- Also set blend for float groups that actually respect it (Pmenu border, etc.)
						adj.blend = math.max(adj.blend or 0, math.floor(t * 100 + 0.5))
					end
					changed = true
				end
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

-- ── Habamax-specific overrides ───────────────────────────────────────────────
local function apply_habamax_overrides()
	if vim.g.colors_name ~= "habamax" then
		return
	end
	-- Black thin separator bar between Neo-tree and editor
	pcall(vim.api.nvim_set_hl, 0, "WinSeparator", { fg = "#000000", bg = "#000000" })
end

-- ── Soft-white fg overrides for kanagawa and gruvbox ─────────────────────────
-- Overrides NeoTree fg groups to a neutral cool gray-white (#c5c9c5) for both
-- kanagawa and gruvbox variants — both themes' default NeoTree fg colors clash
-- with the editor's body text in production-quality dev setups.
-- Runs deferred at 300ms so it wins after NeoTree resets its own groups on load.
local KANAGAWA_SOFT_WHITE = "#c5c9c5"
local CREAM_SEPIA_WHITE = "#ebdbb2"
local gruvbox_green_touched = {}

local function gruvbox_pipeline_fg(hex)
	local out = sepia_hex(hex, sepia_amount / 100)
	if fg_lightness ~= 50 or fg_saturation ~= 50 then
		out = adjust_fg_hsl(out, fg_lightness, fg_saturation)
	end
	return out
end

-- Mute gruvbox's vivid red/orange accents (GruvboxRed: if/end/keywords,
-- GruvboxOrange: Values/nindent/builtins). All such tokens link to these named
-- groups, so adjusting their fg recolors every linked token at once. gruvbox only.
-- Targets are recomputed from gruvbox's palette on every pass so deferred calls
-- remain idempotent when multiple knobs are turned quickly.
local function apply_gruvbox_accent_adjust()
	if vim.g.colors_name ~= "gruvbox" then
		return
	end
	local ok, gb = pcall(require, "gruvbox")
	if not ok or type(gb.palette) ~= "table" then
		return
	end
	if gb.palette.bright_red then
		pcall(vim.api.nvim_set_hl, 0, "GruvboxRed", {
			fg = gruvbox_pipeline_fg(desaturate_hex(gb.palette.bright_red, gruvbox_red_saturation)),
		})
	end
	if gb.palette.bright_orange then
		pcall(vim.api.nvim_set_hl, 0, "GruvboxOrange", {
			fg = gruvbox_pipeline_fg(desaturate_hex(gb.palette.bright_orange, gruvbox_orange_saturation)),
		})
	end
	if gb.palette.bright_yellow then
		pcall(vim.api.nvim_set_hl, 0, "GruvboxYellow", {
			fg = gruvbox_pipeline_fg(desaturate_hex(gb.palette.bright_yellow, gruvbox_yellow_saturation)),
		})
	end
	do
		-- YAML strings resolve through String, shell injections often resolve through
		-- @function.call.bash/GruvboxGreen, and some plugin groups set colors.green
		-- directly. Derive the source from the palette plus the global fg pipeline
		-- instead of current String, because several deferred accent passes can run
		-- after one knob change. Reading the already-mutated String compounds green.
		local source = gb.palette.bright_green and gruvbox_pipeline_fg(gb.palette.bright_green)
		if source then
			local h, s, l = rgb_to_hsl(hex_to_rgb(source))
			local target = gruvbox_green_saturation == 100 and source
				or rgb_to_hex(hsl_to_rgb(h, s, l * (gruvbox_green_saturation / 100)))
			for group in pairs(read_highlights()) do
				local ok_hl, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
				if
					ok_hl
					and type(hl) == "table"
					and not matches(group, editor_static_fg_groups)
					and (normalize_hex(hl.fg) == source or gruvbox_green_touched[group])
				then
					local adj = {}
					for k, v in pairs(hl) do
						adj[k] = v
					end
					adj.fg = target
					pcall(vim.api.nvim_set_hl, 0, group, adj)
					gruvbox_green_touched[group] = gruvbox_green_saturation ~= 100 or nil
				end
			end
		end
	end
	do
		-- THE WHITE FONT knob. #EBDBB2 (gruvbox's canonical fg cream) is the PEAK:
		--   100 = exactly #ebdbb2 (brightest), lower = a DIMMER version that keeps —
		--   in fact deepens — the warm cream. Never brighter than #ebdbb2, never white.
		--
		-- Dimming is done in HSL by lowering ONLY lightness while hue and saturation
		-- stay fixed. Proportional RGB scaling (the previous approach) shrank the
		-- warm R-B gap as it darkened, so the cream faded to gray — the exact bug
		-- being fixed. Holding saturation instead makes the warm gap GROW as it
		-- dims (e.g. 80 -> #dabc70 golden cream, 60 -> #c59c33 amber), so the sepia
		-- tone is always clearly visible and never grays out.
		--
		-- Applied to Normal, GruvboxFg1 and GlobalUrlReset: Normal is plain prose
		-- (README text with no treesitter parser), GruvboxFg1 is what @variable /
		-- @markup / @lsp.type.variable link to, and GlobalUrlReset is the soft-white
		-- URL overlay (https?://… painted by matchadd) — all three are "white font"
		-- so they track this one knob. Setting only GruvboxFg1 (the original
		-- behavior) left prose and URLs at full brightness, splitting the white font
		-- into different shades. Colored syntax (keywords, strings, etc.) is never
		-- touched.
		local h, s, l = rgb_to_hsl(hex_to_rgb(CREAM_SEPIA_WHITE))
		local cream = rgb_to_hex(hsl_to_rgb(h, s, l * (gruvbox_fg1_lightness / 100)))
		for _, group in ipairs({ "Normal", "GruvboxFg1", "GlobalUrlReset" }) do
			local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
			if ok then
				local adj = {}
				for k, v in pairs(hl) do
					adj[k] = v
				end
				adj.fg = cream -- keep bg/sp/attrs (Normal carries the editor bg)
				pcall(vim.api.nvim_set_hl, 0, group, adj)
			end
		end
	end
end

local function apply_retrobox_variable_white()
	if vim.g.colors_name ~= "retrobox" then
		return
	end
	local groups = {
		"@variable",
		"@variable.terraform",
		"@lsp.type.variable",
		"@lsp.type.variable.terraform",
	}
	for _, group in ipairs(groups) do
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
		local adj = {}
		if ok and type(hl) == "table" then
			for k, v in pairs(hl) do
				adj[k] = v
			end
		end
		adj.fg = CREAM_SEPIA_WHITE
		pcall(vim.api.nvim_set_hl, 0, group, adj)
	end
end

local function apply_soft_white_overrides()
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

-- ── Kanagawa Dragon: fixed foreground overrides (post-pipeline) ──────────────
-- A few Dragon groups need an exact fg that must survive the global fg pipeline
-- (sepia / HSL lightness + saturation), which would otherwise shift these colors.
-- They are re-applied after every pipeline pass so the pipeline never gets the
-- last word:
--   • WinSeparator / line numbers / indent guides → Dragon's native soft gray
--     (#625e5a = palette.dragonBlack6 = theme.ui.nontext, the color kanagawa
--     assigns to LineNr / NonText). Reverts the pipeline's brighten/saturate so
--     the separator, line numbers, and indent guides read as the stock soft gray.
--   • brackets → a warm cream (#ded3b4 base) run through the
--     kanagawa_dragon_bracket_lightness knob: @punctuation.bracket for generic
--     ()[]{} via treesitter, and GlobalPunctBracket for the {{ }} / [[ ]] matchadd
--     overlay (the latter is what the blue Helm braces actually use).
-- Each group's fg is overridden in place, keeping whatever bg/blend the pipeline
-- already gave it — only the color changes. Dragon only; every other colorscheme,
-- plus the wave / lotus variants, is left untouched.
local KANAGAWA_DRAGON_LINE_GRAY = "#625e5a"

-- Groups pinned to Dragon's soft gray. SnacksIndent natively links to NonText;
-- setting it explicitly breaks that link so the indent guides stop following the
-- pipeline-brightened NonText.
local KANAGAWA_DRAGON_GRAY_GROUPS = {
	"WinSeparator",
	"VertSplit",
	"LineNr",
	"LineNrAbove",
	"LineNrBelow",
	"SnacksIndent",
}

-- Bracket groups, all sharing the lightness-tuned bracket color. The {{ }} / [[ ]]
-- braces are drawn by the GlobalPunctBracket matchadd overlay
-- (apply_global_punct_matches), which paints over treesitter at priority 95 — so
-- recoloring that group, not @punctuation.bracket.helm, is what changes the Helm
-- template braces. @punctuation.bracket still covers plain ()[]{}.
local KANAGAWA_DRAGON_BRACKET_GROUPS = {
	"@punctuation.bracket",
	"GlobalPunctBracket",
}

local function active_kanagawa_variant()
	local name = vim.g.colors_name or ""
	if not name:match("^kanagawa") then
		return nil
	end
	local ok, kanagawa = pcall(require, "kanagawa")
	-- kanagawa records the currently-loaded variant in _CURRENT_THEME. config.theme
	-- is only the setup default ("dragon" here) and does NOT change when switching
	-- to wave/lotus, so it must not be used for variant detection.
	if ok and kanagawa._CURRENT_THEME then
		return kanagawa._CURRENT_THEME
	end
	local suffix = name:match("^kanagawa%-(.+)$")
	if suffix then
		return suffix
	end
	if ok and kanagawa.config and kanagawa.config.theme then
		return kanagawa.config.theme
	end
	return nil
end

local function apply_kanagawa_dragon_fixed_fg()
	if active_kanagawa_variant() ~= "dragon" then
		return
	end
	-- Override fg in place, keeping each group's existing bg/blend/attrs.
	local function set_fg(group, fg)
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
		local adj = {}
		if ok and type(hl) == "table" then
			for k, v in pairs(hl) do
				adj[k] = v
			end
		end
		adj.fg = fg
		pcall(vim.api.nvim_set_hl, 0, group, adj)
	end
	for _, group in ipairs(KANAGAWA_DRAGON_GRAY_GROUPS) do
		set_fg(group, KANAGAWA_DRAGON_LINE_GRAY)
	end
	-- Bracket color tuned by its own lightness knob (saturation locked at 50 =
	-- original, so only lightness moves and the warm hue is preserved).
	local bracket = adjust_fg_hsl(KANAGAWA_DRAGON_BRACKET, kanagawa_dragon_bracket_lightness, 50)
	for _, group in ipairs(KANAGAWA_DRAGON_BRACKET_GROUPS) do
		set_fg(group, bracket)
	end
end

-- Ensures chrome fg colors remain visible when chrome bg has been darkened or
-- made transparent. Only touches groups matching chrome_groups; never alters
-- editor body fg. Lifts HSL Lightness to a floor — color identity (hue) is
-- preserved so NORMAL stays yellow-ish, INSERT stays green-ish, etc.
local function apply_chrome_readability_fix()
	local min_lightness
	if chrome_darken < 50 then
		-- Linear: 75 at chrome_darken=0, approaches 50 at chrome_darken=50 (no-op)
		min_lightness = 75 - chrome_darken * 0.5
	elseif chrome_darken > 50 then
		-- Transparent zone: bg is gone, terminal (near-black) shows through
		min_lightness = 70
	else
		return -- chrome_darken == 50: theme default, no fix needed
	end

	for group, hl in pairs(read_highlights()) do
		if not hl.link and matches(group, chrome_groups) then
			local fg_hex = hl.fg and normalize_hex(hl.fg)
			if fg_hex then
				local new_fg = ensure_readable_fg(fg_hex, nil, min_lightness)
				if new_fg ~= fg_hex then
					local adj = {}
					for k, v in pairs(hl) do
						adj[k] = v
					end
					adj.fg = new_fg
					pcall(vim.api.nvim_set_hl, 0, group, adj)
				end
			end
		end
	end
end

-- Multiple deferred passes (immediate → schedule → 50ms → 200ms) intentionally
-- catch highlights set late by plugins (bufferline, lualine, neo-tree, etc.).
-- This is verbose but necessary — do NOT collapse to a single call.
local function apply_theme_adjustments(refresh_base)
	apply_global_punct_highlights()
	if refresh_base or adjust_base_name ~= (vim.g.colors_name or "") then
		capture_base()
	end
	local function run_adjust_all_highlights()
		adjust_all_highlights()
		apply_chrome_readability_fix()
		apply_editor_static_colors()
		apply_retrobox_string_lightness()
		apply_retrobox_variable_white()
	end
	run_adjust_all_highlights()
	vim.schedule(run_adjust_all_highlights)
	vim.defer_fn(run_adjust_all_highlights, 50)
	vim.defer_fn(run_adjust_all_highlights, 200)
	vim.defer_fn(apply_fzf_opaque_highlights, 250)
	vim.defer_fn(apply_habamax_overrides, 250)
	vim.defer_fn(apply_soft_white_overrides, 300)
	vim.defer_fn(apply_kanagawa_dragon_fixed_fg, 300)
	vim.defer_fn(apply_kanagawa_dragon_fixed_fg, 600)
	vim.defer_fn(apply_chrome_readability_fix, 350)
	vim.defer_fn(apply_chrome_readability_fix, 600)
	vim.defer_fn(apply_gruvbox_accent_adjust, 300)
	apply_onedark_dark_purple_overrides()
	vim.defer_fn(apply_onedark_dark_purple_overrides, 300)
	vim.defer_fn(apply_onedark_dark_purple_overrides, 650)
	vim.defer_fn(apply_editor_static_colors, 325)
	vim.defer_fn(apply_editor_static_colors, 650)
	vim.defer_fn(apply_retrobox_string_lightness, 325)
	vim.defer_fn(apply_retrobox_string_lightness, 650)
	vim.defer_fn(apply_retrobox_variable_white, 325)
	vim.defer_fn(apply_retrobox_variable_white, 650)
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
					Comment = { fg = colors.theme.syn.comment },
					-- NeoTreeDirectoryName is also patched via apply_soft_white_overrides at 300ms
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
				cursor = "FzfLuaPreviewMatch",
				search = "FzfLuaPreviewMatch",
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
			colorscheme = "gruvbox",
		},
		init = function()
			-- :ThemeAdjust to manually re-run the pipeline
			vim.api.nvim_create_user_command("ThemeAdjust", function()
				apply_theme_adjustments()
			end, {})

			-- :FgLightness / :FgSaturation / :FgAdjust — live HSL tuning
			local function set_fg_knob(name, setter, args, lo, hi)
				lo, hi = lo or 0, hi or 100
				local val = tonumber(args)
				if not val or val < lo or val > hi then
					vim.notify(name .. (": expected a number %d–%d"):format(lo, hi), vim.log.levels.ERROR)
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

			-- :DragonBracketLightness <0-100> — kanagawa-dragon only. Lightness of the
			-- bracket color (50 = original #ded3b4, <50 darker, >50 brighter).
			vim.api.nvim_create_user_command("DragonBracketLightness", function(opts)
				if
					set_fg_knob("DragonBracketLightness", function(v)
						kanagawa_dragon_bracket_lightness = v
					end, opts.args)
				then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })

			-- :RetroboxStringLightness <0-100> - retrobox only. Lightness for String,
			-- @string*, and @lsp.type.string* captures. 50 = original retrobox String.
			vim.api.nvim_create_user_command("RetroboxStringLightness", function(opts)
				if
					set_fg_knob("RetroboxStringLightness", function(v)
						retrobox_string_lightness = v
					end, opts.args)
				then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })

			-- :Sepia <-100..100> — bipolar warm/cool. 0 = neutral/off, positive = sepia
			-- (warm), negative = anti-sepia (cool). Negative extrapolates away from the
			-- sepia point via the same sepia_hex math, de-warming toward neutral/cool.
			vim.api.nvim_create_user_command("Sepia", function(opts)
				if set_fg_knob("Sepia", function(v)
					sepia_amount = v
				end, opts.args, -100, 100) then
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

			-- :BgBrightness <0-100> — live sepia-aware bg brightness tuning.
			-- 0 = fully dark, 50 = original sepia-adjusted bg, 100 = brighter ceiling.
			local function set_bg_brightness(opts, command_name)
				if set_fg_knob(command_name, function(v)
					bg_brightness = v
				end, opts.args) then
					apply_theme_adjustments()
				end
			end
			vim.api.nvim_create_user_command("BgBrightness", function(opts)
				set_bg_brightness(opts, "BgBrightness")
			end, { nargs = 1 })
			-- Backward-compatible alias for the old command name.
			vim.api.nvim_create_user_command("DarkenBackground", function(opts)
				set_bg_brightness(opts, "DarkenBackground")
			end, { nargs = 1 })

			-- :ChromeDarken <0-100> — 0 = black, 50 = theme default, 100 = transparent
			vim.api.nvim_create_user_command("ChromeDarken", function(opts)
				if set_fg_knob("ChromeDarken", function(v)
					chrome_darken = v
				end, opts.args) then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })

			-- :NormalizeBackground <0-100> — live bg hue neutralization toward gray
			vim.api.nvim_create_user_command("NormalizeBackground", function(opts)
				if set_fg_knob("NormalizeBackground", function(v)
					normalize_background = v
				end, opts.args) then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })

			-- :GruvboxRed / :GruvboxOrange <0-100> — gruvbox only, mute the vivid red/orange accents
			vim.api.nvim_create_user_command("GruvboxRed", function(opts)
				if set_fg_knob("GruvboxRed", function(v)
					gruvbox_red_saturation = v
				end, opts.args) then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })
			vim.api.nvim_create_user_command("GruvboxOrange", function(opts)
				if set_fg_knob("GruvboxOrange", function(v)
					gruvbox_orange_saturation = v
				end, opts.args) then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })
			vim.api.nvim_create_user_command("GruvboxYellow", function(opts)
				if set_fg_knob("GruvboxYellow", function(v)
					gruvbox_yellow_saturation = v
				end, opts.args) then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })
			vim.api.nvim_create_user_command("GruvboxGreen", function(opts)
				if set_fg_knob("GruvboxGreen", function(v)
					gruvbox_green_saturation = v
				end, opts.args) then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })
			vim.api.nvim_create_user_command("GruvboxFg1", function(opts)
				if set_fg_knob("GruvboxFg1", function(v)
					gruvbox_fg1_lightness = v
				end, opts.args) then
					apply_theme_adjustments()
				end
			end, { nargs = 1 })

			-- Per-colorscheme knob defaults applied automatically on ColorScheme event.
			-- These OVERWRITE any manual :BgTransparency / :BgBrightness values on theme switch.
			-- Themes without an entry below still get the global background/chrome
			-- defaults, but no foreground, sepia, or accent adjustments.
			local global_theme_defaults = {
				bg_transparency = 100,
				bg_brightness = 0,
				chrome_darken = 100,
				fg_lightness = 50,
				fg_saturation = 50,
				sepia_amount = 0,
				normalize_background = 0,
				gruvbox_red_saturation = 100,
				gruvbox_orange_saturation = 100,
				gruvbox_yellow_saturation = 100,
				gruvbox_green_saturation = 100,
				gruvbox_fg1_lightness = 100,
				kanagawa_dragon_bracket_lightness = 50,
				retrobox_string_lightness = 50,
			}

			local function apply_knob_defaults(defaults)
				bg_transparency = defaults.bg_transparency
				bg_brightness = defaults.bg_brightness or defaults.darken_background
				chrome_darken = defaults.chrome_darken
				fg_lightness = defaults.fg_lightness
				fg_saturation = defaults.fg_saturation
				sepia_amount = defaults.sepia_amount
				normalize_background = defaults.normalize_background
				gruvbox_red_saturation = defaults.gruvbox_red_saturation
				gruvbox_orange_saturation = defaults.gruvbox_orange_saturation
				gruvbox_yellow_saturation = defaults.gruvbox_yellow_saturation
				gruvbox_green_saturation = defaults.gruvbox_green_saturation
				gruvbox_fg1_lightness = defaults.gruvbox_fg1_lightness
				kanagawa_dragon_bracket_lightness = defaults.kanagawa_dragon_bracket_lightness
				retrobox_string_lightness = defaults.retrobox_string_lightness
			end

			-- To preserve manual values across theme switches, remove the relevant entry below.
			local colorscheme_defaults = {
				["kanagawa-dragon"] = {
					-- Raw Kanagawa Dragon values match Ghostty's Kanagawa Dragon color pool.
					bg_transparency = 100,
					bg_brightness = 0,
					chrome_darken = 100,
					sepia_amount = -38,
					fg_saturation = 55,
					fg_lightness = 75,
					normalize_background = 0,
					gruvbox_red_saturation = 100,
					gruvbox_orange_saturation = 100,
					gruvbox_yellow_saturation = 100,
					gruvbox_green_saturation = 100,
					gruvbox_fg1_lightness = 100,
					kanagawa_dragon_bracket_lightness = 46,
				},
				["gruvbox"] = {
					bg_transparency = 100,
					bg_brightness = 0,
					fg_lightness = 70,
					fg_saturation = 50,
					sepia_amount = 15,
					gruvbox_red_saturation = 100,
					gruvbox_orange_saturation = 100,
					gruvbox_yellow_saturation = 100,
					gruvbox_green_saturation = 100,
					chrome_darken = 100,
					gruvbox_fg1_lightness = 99,
					normalize_background = 0,
					kanagawa_dragon_bracket_lightness = 50,
				},
				["base16-gruvbox-material-dark-soft"] = {
					fg_lightness = 50,
					fg_saturation = 51,
				},
				["base16-gruvbox-material-dark-medium"] = {
					fg_lightness = 50,
					fg_saturation = 51,
				},
				["base16-gruvbox-material-dark-hard"] = {
					fg_lightness = 50,
					fg_saturation = 51,
				},
				["retrobox"] = {
					bg_transparency = 100,
					bg_brightness = 0,
					chrome_darken = 100,
					fg_lightness = 70,
					fg_saturation = 50,
					sepia_amount = 5,
					retrobox_string_lightness = 59,
				},
				["catppuccin-mocha"] = {
					bg_transparency = 100,
					bg_brightness = 0,
					chrome_darken = 100,
					sepia_amount = 25,
					fg_saturation = 29,
					fg_lightness = 37,
					normalize_background = 0,
					kanagawa_dragon_bracket_lightness = 50,
				},
			}

			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "*",
				callback = function()
					local key = vim.g.colors_name or ""
					-- kanagawa.nvim sets colors_name = "kanagawa" for all variants.
					-- Resolve the actual variant via its config to get the correct lookup key.
					if key == "kanagawa" then
						local ok, kanagawa = pcall(require, "kanagawa")
						if ok and kanagawa.config and kanagawa.config.theme then
							key = "kanagawa-" .. kanagawa.config.theme
						end
					end
					if key:match("^catppuccin") then
						key = "catppuccin-mocha"
					end
					local defaults = colorscheme_defaults[key]
					apply_knob_defaults(vim.tbl_extend("force", global_theme_defaults, defaults or {}))
					apply_theme_adjustments(true)
					apply_global_punct_matches()
					apply_onedark_dark_purple_overrides()
					apply_onedark_dark_helm_trim_matches()
					apply_retrobox_string_lightness()
				end,
			})

			vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType" }, {
				pattern = "*",
				callback = function()
					apply_global_punct_matches()
					apply_onedark_dark_purple_overrides()
					apply_onedark_dark_helm_trim_matches()
					apply_retrobox_string_lightness()
				end,
			})

			-- Re-run the pipeline after all plugins finish initializing on startup.
			-- Lualine sets its highlight groups late during lazy loading, after the
			-- ColorScheme deferred passes have already completed, so the statusline
			-- pills look unstyled until the theme is manually reselected. VimEnter
			-- fires once everything is loaded; the extra defer gives lualine time to
			-- finalize its groups before we overwrite them.
			-- Re-apply the active colorscheme on VimEnter: this triggers a fresh
			-- ColorScheme event with all plugins fully loaded, so lualine rebuilds
			-- cleanly and the statusline matches what `<leader>th` produces. It also
			-- fixes kanagawa specifically — LazyVim's opt loads plain "kanagawa"
			-- (wave default) rather than the configured variant, so we resolve to
			-- kanagawa-<variant> below before re-applying.
			vim.api.nvim_create_autocmd("VimEnter", {
				once = true,
				callback = function()
					vim.defer_fn(function()
						local target = vim.g.colors_name or ""
						-- kanagawa: re-applying "kanagawa" leaves it on the wave default,
						-- so resolve to the configured variant (dragon/wave/lotus).
						if target == "kanagawa" then
							local ok, kanagawa = pcall(require, "kanagawa")
							if ok and kanagawa.config and kanagawa.config.theme then
								target = "kanagawa-" .. kanagawa.config.theme
							end
						end
						if target ~= "" then
							pcall(vim.cmd.colorscheme, target)
						end
					end, 200)
				end,
			})
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		optional = true,
		opts = function(_, opts)
			-- Make lualine's middle sections (b/c, and their x/y mirrors) transparent
			-- so they inherit StatusLine's bg, which follows bg_brightness. Only
			-- the a/z pills keep an explicit colored bg. Built from whatever theme
			-- lualine's "auto" would resolve for the active colorscheme, and rebuilt
			-- on ColorScheme so pill colors track the active theme.
			local function transparent_middle_theme()
				local lok, loader = pcall(require, "lualine.utils.loader")
				if not lok then
					return nil
				end
				-- Try the exact colors_name first, then fall back to the base plugin
				-- name. Themes like catppuccin register their lualine theme as
				-- "catppuccin" but set colors_name to "catppuccin-mocha"/"-latte"/etc.
				-- Without this fallback, the lualine theme load silently fails for
				-- every catppuccin flavour and both pills render with default/broken
				-- colors that look transparent against the bg.
				local candidates = { vim.g.colors_name or "" }
				local base = (vim.g.colors_name or ""):match("^([^-]+)")
				if base and base ~= vim.g.colors_name then
					table.insert(candidates, base)
				end
				local theme
				for _, name in ipairs(candidates) do
					local ok, t = pcall(loader.load_theme, name)
					if ok and type(t) == "table" then
						theme = t
						break
					end
				end
				if type(theme) ~= "table" then
					return nil
				end
				for _, mode in pairs(theme) do
					if type(mode) == "table" then
						if mode.b then
							mode.b.bg = nil
						end
						if mode.c then
							mode.c.bg = nil
						end
						if mode.x then
							mode.x.bg = nil
						end
						if mode.y then
							mode.y.bg = nil
						end
					end
				end
				return theme
			end

			local built = transparent_middle_theme()
			if built then
				opts.options = opts.options or {}
				opts.options.theme = built
			end

			-- Re-run lualine.setup with the freshly-built theme. create_highlight_groups
			-- alone doesn't work on cold start because lualine has already cached the
			-- (broken) theme internally — only a full setup call replaces it.
			local function rebuild_lualine()
				local t = transparent_middle_theme()
				if not t then
					return
				end
				local lok, lualine = pcall(require, "lualine")
				if not lok then
					return
				end
				local cur = lualine.get_config and lualine.get_config() or {}
				cur.options = cur.options or {}
				cur.options.theme = t
				pcall(lualine.setup, cur)
			end

			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = function()
					vim.schedule(rebuild_lualine)
				end,
			})

			-- Initial load: transparent_middle_theme() ran at opts construction with
			-- vim.g.colors_name="", so lualine has a junk cached theme. VimEnter
			-- fires after the colorscheme is applied — at that point we can rebuild
			-- with the correct theme and force lualine to swap it in.
			vim.api.nvim_create_autocmd("VimEnter", {
				once = true,
				callback = function()
					vim.defer_fn(rebuild_lualine, 100)
					vim.defer_fn(rebuild_lualine, 500)
					vim.defer_fn(rebuild_lualine, 1200)
				end,
			})
		end,
	},
	{ "miikanissi/modus-themes.nvim", priority = 1000 },

	{
		"navarasu/onedark.nvim",
		priority = 1000,
		config = function()
			require("onedark").setup({
				style = "warmer",
			})
		end,
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

	{
		"sainnhe/sonokai",
		lazy = false,
		priority = 1000,
	},

	{
		"savq/melange-nvim",
		lazy = false,
		priority = 1000,
	},

	{
		"kepano/flexoki-neovim",
		name = "flexoki",
		lazy = false,
		priority = 1000,
	},

	{
		"EdenEast/nightfox.nvim",
		lazy = false,
		priority = 1000,
	},

	{
		"olimorris/onedarkpro.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			colors = {
				onedark_dark = {
					purple = "#5194CB",
				},
			},
		},
	},

	{
		"junegunn/seoul256.vim",
		lazy = false,
		priority = 1000,
	},

	{
		"phha/zenburn.nvim",
		lazy = false,
		priority = 1000,
	},
	{ "RRethy/base16-nvim", lazy = false, priority = 1000 },

	-- Catppuccin: remap peach/orange → red for constants/characters.
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
