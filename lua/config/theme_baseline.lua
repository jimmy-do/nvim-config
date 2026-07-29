-- Per-theme baseline colours, kept in their OWN module so :ThemeReload can
-- re-read them fresh from disk (see apply_theme_baseline_colors in theme.lua).
--
-- Why this lives here and not inline in theme.lua: theme.lua is loaded once at
-- nvim startup and its locals are frozen into closures. Editing a hex in an
-- inline table changes the file but not the running session -- :ThemeReload
-- would keep stamping the startup values. This module is dofile()'d on every
-- baseline apply, so edits here take effect on the next :ThemeReload, no
-- restart. Edit the hexes, save, :ThemeReload.
--
-- These are applied ONCE, immediately before the base capture, so they read in
-- as if the colorscheme shipped them. Everything downstream (:FgAdjust, :Sepia,
-- the bg knobs) then transforms them like any other theme colour.
return {
  -- base16-tokyo-night-terminal-storm deliberately has NO entry here.
  -- 2026-07-28: its hand-tuned yaml key/value ramp, orange delimiters and yellow
  -- brackets were removed at Jimmy's request -- it renders as the stock upstream
  -- base16 scheme now. The full table lives on unchanged as stormv2 below; copy
  -- it back under the base16 name (and re-add that name to is_storm_family() in
  -- theme.lua) to restore the old look.

  -- =========================================================================
  -- stormv2 — the storm copy. Colorscheme: colors/stormv2.lua
  -- =========================================================================
  -- Byte-identical to the table above on purpose: a copy has to OPEN looking
  -- exactly like what it was copied from. Retune here freely; the original
  -- above is untouched. (theme.lua's is_storm_family() gives this name the
  -- same punctuation overlay, cyan indent scope and yaml startup pass.)
  ["stormv2"] = {
    ["@property.yaml"] = "#364b8b", -- fields (keys)
    ["@punctuation.delimiter.yaml"] = "#ff8c1a", -- colons, commas
    ["@punctuation.special.yaml"] = "#ff8c1a", -- list dashes, anchors
    ["@punctuation.bracket"] = "#f7ff00", -- [] {}
    ["@string.yaml"] = "#00ffff", -- values
    ["@comment"] = "#243745",
    ["Comment"] = "#243745",

    -- YAML value shapes (captures live in after/queries/yaml/highlights.scm).
    -- Plain values stay #00ffff above; these are the subsets worth telling
    -- apart in a manifest. Hexes are tokyo-night storm's own palette so they
    -- read as part of the theme rather than bolted on.
    --
    -- Delete any line here and that shape falls back to the cyan above -- the
    -- captures are built to degrade, so this table is the whole opt-in surface.
    ["@type.yaml.enum"] = "#e0af68", -- Deployment, RollingUpdate, ClusterIP
    ["@constant.yaml.env"] = "#f7768e", -- LOG_LEVEL, POSTGRES_HOST
    ["@string.yaml.image"] = "#bb9af7", -- registry.io/api:1.2.3, actions/checkout@v4
    ["@string.yaml.version"] = "#9ece6a", -- apps/v1, 1.2.3
    ["@string.yaml.url"] = "#73daca", -- https://, oci://
    -- Shares the env-constant pink above. They are the only two that reuse a
    -- hex, and they do not co-occur: env NAMES are a k8s manifest thing,
    -- conditions are a workflow thing.
    ["@string.yaml.condition"] = "#f7768e", -- inputs.action == 'plan'
    -- Path was #a9b1d6 "deliberately quiet" — but that IS tokyonight's fg, so
    -- paths read as unstyled text / key-grey (user: "same color as keys").
    -- 2026-07-27: quiet now means DIM URL-TEAL — still recessive, but hued, so
    -- it stays in the locator family instead of impersonating plain text.
    ["@string.yaml.path"] = "#73daca", -- exact url teal: one locator family, ONE colour — no shade pairs
    -- Bare selector words (plan, write, main). Without this entry the class
    -- derived to #c09efe — a near-clone of the image purple above.
    ["@string.yaml.word"] = "#ff9e64", -- tokyonight's own orange
    -- @number.yaml.quantity (512Mi, 30s) is intentionally absent: it inherits
    -- @number, so quantities match plain numbers instead of adding a colour.

    -- Document-root keys only. Nested keys keep @property.yaml above.
    -- Same hue family as the #364b8b nested key, just lifted enough to separate
    -- the manifest skeleton from everything hanging off it. Deliberately NOT a
    -- bright accent -- top-level keys are structure, not something to look at.
    ["@property.yaml.toplevel"] = "#4a67ad",

    -- Middle rung of the key ramp, sitting between the toplevel above and the
    -- #364b8b nested key. Explicit because the derived fallback (see
    -- derive_yaml_baseline in theme.lua) fills this rung from @property, which
    -- in storm is a desaturated grey -- that made the ramp non-monotonic
    -- (bright > grey > dark) instead of a clean three-step fade.
    ["@property.yaml.level2"] = "#40589e",

    -- Shell flags inside `run:` blocks -- -no-color, -out=tfplan, -auto-approve.
    -- These come from the bash parser injected into run: scalars, and defaulted
    -- to the same muted #8b8fab as operators, which is most of the grey in a
    -- workflow file. Scoped to .bash so other languages' parameters are
    -- untouched. Not a yaml group, but it is yaml files where it shows up.
    ["@variable.parameter.bash"] = "#e0af68",

    -- NOTE: {{ }} / [[ ]] braces are NOT set here. They are painted by the
    -- GlobalPunctBracket matchadd overlay in theme.lua, which outranks any
    -- treesitter capture -- setting @punctuation.bracket.helm here looks correct
    -- and does nothing. The knob for those is STORM_BRACKET in theme.lua.
  },

  -- =========================================================================
  -- moonlightv2 — the base16-moonlight copy. Colorscheme: colors/moonlightv2.lua
  -- =========================================================================
  -- Only two things are tuned here; everything else (keys, punctuation, the
  -- ${{ }} tokens) still comes from derive_yaml_baseline in theme.lua, i.e.
  -- moonlight's own palette. Deleting any line falls back to derived.
  --
  -- 1. THE VALUE SIDE GLOWS HARDER. Moonlight's own value hexes are pretty but
  --    pastel, and pastel does not bloom: the ghostty shader
  --    (shaders/macbook-m4max-2056-theme-friendly-sharp.glsl) gates its halo on
  --    HSV saturation smoothstep(0.22, 0.55) and scales emission by the PEAK
  --    channel, not luma. #ffc777 (sat 0.53) and #b994f1 (sat 0.39) sit at or
  --    under the gate, so they rendered flat. Each value below keeps its
  --    moonlight hue and is pushed to sat >= 0.58 with one channel at/near 1.0.
  --    Hue 90-162 is still avoided everywhere -- that is the shader's dead band
  --    around fgHueRef #00b012, where nothing blooms at all.
  --
  -- 2. COMMENTS DROP ~50%. Moonlight's comment is base03 #748cd6, a bright
  --    periwinkle that reads as data. Saturation and lightness are each cut by
  --    half (HSL 224/54/64 -> 224/33/38), hue untouched, so comments stay
  --    recognisably moonlight-blue but sit behind everything else.

  -- EVERY HUE BELOW IS MOONLIGHT'S OWN, UNMOVED. Only HSV saturation moves
  -- (and value to 255 where it was short) so the shader has something to bloom.
  -- Red stays red, orange stays orange. Nothing is reassigned to a new colour.
  --
  -- The saturations sit HALFWAY between moonlight's originals and the full-neon
  -- pass -- toned down on request. Ratchet a single line up or down by editing
  -- its hex; the sat figure in each comment is the current one.
  ["moonlightv2"] = {
    -- --- Values: catch-all and quoted -------------------------------------
    ["@string.yaml"] = "#17ffc9", -- (166) base0B #2df4c0 .82 -> sat .91
    ["@string.yaml.value"] = "#17ffc9", -- (166)
    ["@string.yaml.quoted"] = "#33d2a8", -- (166) same hue, one step back

    -- --- Value shapes ------------------------------------------------------
    ["@type.yaml.enum"] = "#ffc15e", -- (37)  base0A #ffc777 .53 -> sat .63
    ["@string.yaml.word"] = "#04d1f9", -- (190) base0C — the slot urls vacated 2026-07-27; bare selectors (plan, write)
    ["@constant.yaml.env"] = "#ff6b6e", -- (359) base09 #f67f81 .48 -> sat .58
    ["@string.yaml.condition"] = "#ff6b6e", -- (359) shares env, as elsewhere
    -- 2026-07-27 hue respread: strings(166), version(180), url(190) and path
    -- (dim 190) sat inside a 24-degree cyan cluster and read as one colour in a
    -- manifest. Locators moved to the purple family, images to pink (base0F,
    -- previously unused). Same palette, wider spread. Old values, one-line
    -- revert: image #b17df1, version #20ffff, url #02d7f9, path #1e88a0.
    ["@string.yaml.image"] = "#f470ee", -- (303) base0F #ecb2f0 pushed to sat .54
    ["@string.yaml.version"] = "#20ffff", -- (180) base0D #40ffff .75 -> sat .88
    ["@string.yaml.url"] = "#a678ff", -- (260) base0E #b994f1 pushed to sat .53
    -- Path: own full slot, cyan 190 (free since urls moved to purple). NO dim
    -- variants of other classes — shade pairs read as lazy (2026-07-27).
    ["@string.yaml.path"] = "#02d7f9", -- (190) values.yaml, /healthz

    -- --- Scalars: base09, same as env — moonlight's own grouping ----------
    ["@boolean.yaml.kdragon"] = "#ff6b6e", -- (359) true/false/yes/no
    ["@number.yaml.kdragon"] = "#ff6b6e", -- (359) 3, 1.5
    ["@number.yaml.quantity"] = "#ff6b6e", -- (359) 512Mi, 30s

    -- --- Not values, so not glowed ----------------------------------------
    -- null / ~ is absence; it tracks the comment colour, as in every table here.
    ["@constant.builtin.yaml.kdragon"] = "#415281",
    ["@comment"] = "#415281", -- was #748cd6 — sat and lightness both halved
    ["Comment"] = "#415281",
  },

  -- =========================================================================
  -- moonlightv3 — moonlightv2's grouping, taken past the glow gate.
  -- =========================================================================
  -- The palette in colors/moonlightv3.lua cannot make YAML glow on its own:
  -- base16 paints yaml keys and values out of the fg ramp, and the ramp has to
  -- stay dull or the buffer turns into four competing blues. The glow has to
  -- come from THIS table, which is what actually paints yaml here.
  --
  -- Structure follows everforestv2-glow, because that variant already proved
  -- the shape: glow the PUNCTUATION and the VALUES, leave the key ramp and the
  -- comments dull. Colons and list dashes appear on nearly every line, so
  -- lighting the punctuation is what produces glow volume in a config file --
  -- values alone are too sparse to read as "the theme glows".
  --
  -- Every hue below is one Moonlight already owns (166 mint, 180 aqua, 190
  -- cyan, 264/280 purple, 296 magenta, 350/359 red, 37 gold). Nothing is
  -- imported from another theme. Hues are kept spaced apart on purpose:
  -- "everything glows" collapses into one bright smear without it.
  ["moonlightv3"] = {
    -- --- Key ramp ----------------------------------------------------------
    -- Set EXPLICITLY. Leaving these out (as moonlightv2 does) lets toplevel
    -- keys fall through to base16's own near-white #d9ddf3 at sat 0.11, which
    -- puts a white key next to a pale value on the very first line of every
    -- manifest. Three rungs descending by depth, all built from Moonlight's own
    -- blues (base03 #748cd6 / base02 #596399), all kept BELOW the gate on
    -- purpose -- the keys are the dull anchor the glow reads against.
    ["@property.yaml.toplevel"] = "#8b9fe0", -- apiVersion, kind, spec
    ["@property.yaml.level2"] = "#6b7cb8", -- mid rung
    ["@property.yaml"] = "#566490", -- depth 3+, deliberately receding

    -- --- Punctuation: the aqua structure family ---------------------------
    -- base0D #40ffff is Moonlight's signature aqua and already sits at sat
    -- 0.75, so brackets and dashes glow with the theme's own colour, unedited.
    ["@punctuation.bracket"] = "#40ffff", -- (180) sat 0.75  [] {}
    ["@punctuation.special.yaml"] = "#ff5370", -- stock base08, already at ceiling  list dashes
    ["@punctuation.special.doc"] = "#40ffff", -- (180) --- / ...
    -- Colons are on every single line. At full aqua they swamp the file, so
    -- they take the same hue two steps down in value: still past the gate,
    -- still glowing, but the dash wins when both are on a line.
    ["@punctuation.delimiter.yaml"] = "#29cccc", -- (180) sat 0.80 v0.80
    ["@punctuation.special.merge"] = "#ff5370", -- stock base08, already at ceiling  `<<`

    -- --- Values: mint catch-all, hue-spaced from there --------------------
    -- Straight from base16-moonlight's own string slot, brightened. base0B is
    -- #2df4c0; scaled to the channel ceiling that is #2fffc9 -- same hue (164),
    -- same colour, more light. No invented hues, no hue drift off Moonlight.
    ["@string.yaml"] = "#2fffc9", -- stock base0B #2df4c0 -> ceiling
    ["@string.yaml.value"] = "#2fffc9", -- stock base0B #2df4c0 -> ceiling
    ["@string.yaml.quoted"] = "#0dffc0", -- stock #0ce2aa -> ceiling

    -- --- Value shapes ------------------------------------------------------
    -- Every hex below is a real base16-moonlight slot, brightened by scaling to
    -- the channel ceiling (hue and channel ratios untouched -- same colour, more
    -- light). The previous set was hand-mixed near-misses: #ee43fa for base07's
    -- #ef43fa, #ff5471 for base08's #ff5370, #02d7f9 for base0C's #04d1f9. Close
    -- enough to pass a glance, wrong enough that the theme did not match its own
    -- palette. Do not re-mix these by eye -- take the slot and scale it.
    ["@type.yaml.enum"] = "#ffc777", -- stock base0A, already at ceiling  Deployment
     ["@string.yaml.word"] = "#ffc777", -- stock base0A shared with enums — bare selectors
    ["@string.yaml.version"] = "#ff8486", -- stock base09 #f67f81 (ORANGE) -> ceiling  apps/v1, 1.9.x
    ["@constant.yaml.env"] = "#2fffc9", -- stock base0B #2df4c0 -> ceiling  LOG_LEVEL
    ["@string.yaml.condition"] = "#ff8486", -- stock base09 -> ceiling
    ["@string.yaml.image"] = "#c49dff", -- stock base0E #b994f1 -> ceiling
    ["@boolean.yaml.kdragon"] = "#04d6ff", -- stock base0C #04d1f9 -> ceiling  true/false
    ["@number.yaml.kdragon"] = "#40ffff", -- stock base0D, already at ceiling  3, 1.5
    ["@number.yaml.quantity"] = "#40ffff", -- stock base0D, already at ceiling  512Mi
    ["@label.yaml"] = "#ff5370", -- stock base08, already at ceiling  &anchor / *alias
    ["@label"] = "#ff5370", -- stock base08, already at ceiling

    -- --- Locators ----------------------------------------------------------
    ["@string.yaml.url"] = "#fbbdff", -- stock base0F #ecb2f0 -> ceiling  https://
    -- Path keeps the URL slot and stays dimmer: same kind of thing, less weight.
    ["@string.yaml.path"] = "#f9a5ff", -- stock #d990de -> ceiling  values.yaml

    -- --- The dull anchor: absence, prose, and the key ramp ----------------
    -- These are deliberately left below the gate. Glow only reads as glow if
    -- something on screen is NOT glowing, and in YAML the keys and comments are
    -- the only mass large enough to play that role.
    ["@constant.builtin.yaml.kdragon"] = "#748cd6", -- stock base03  null / ~
    ["@comment"] = "#415281",
    ["Comment"] = "#415281",
  },
  -- =========================================================================
  -- icyv2 — the base16-icy copy. Colorscheme: colors/icyv2.lua
  -- =========================================================================
  -- VALUES ONLY, per request (2026-07-28): keys, punctuation, comments and the
  -- null/~ builtin all stay derived from icy's stock monochrome-teal palette —
  -- that dull ramp is the anchor the glow reads against. Five requested glow
  -- colours, all past the shader gate (HSV sat > 0.55) and clear of the green
  -- dead band (hue 90-162; #00ffcb sits at 167.8, just outside):
  --
  --   pink #ff2ee0 (313)   cyan #00ffff (180)   mint #00ffcb (168)
  --   light blue #4dc3ff (200)   orange #ff9e2c (32)
  --
  -- Delete any line and that shape falls back to the derived baseline.
  ["icyv2"] = {
    -- --- Values: mint catch-all (the one exact hex requested) -------------
    ["@string.yaml"] = "#00ffcb",
    ["@string.yaml.value"] = "#00ffcb",
    ["@string.yaml.quoted"] = "#00ffcb", -- exact share: same kind, same colour

    -- --- Value shapes ------------------------------------------------------
    ["@type.yaml.enum"] = "#ff9e2c", -- orange: Deployment, RollingUpdate
    ["@string.yaml.word"] = "#ff9e2c", -- orange: bare selectors (plan, main)
    ["@constant.yaml.env"] = "#00ffff", -- cyan: LOG_LEVEL, POSTGRES_HOST
    ["@string.yaml.condition"] = "#00ffff", -- cyan: shares env, as elsewhere
    ["@string.yaml.version"] = "#00ffff", -- cyan: apps/v1, 1.2.3

    -- --- Locators: one family, one colour ---------------------------------
    ["@string.yaml.url"] = "#4dc3ff", -- light blue: https://, oci://
    ["@string.yaml.path"] = "#4dc3ff",
    ["@string.yaml.image"] = "#4dc3ff",

    -- --- Hot scalars: the bright-ass pink ---------------------------------
    ["@boolean.yaml.kdragon"] = "#ff2ee0", -- true/false/yes/no
    ["@number.yaml.kdragon"] = "#ff2ee0", -- 3, 1.5
    ["@number.yaml.quantity"] = "#ff2ee0", -- 512Mi, 30s
  },

  -- =========================================================================
  -- kanagawa-dragon (added 2026-07-27). Was derive-only: the muted dragon
  -- palette + knobs kept fusing value classes into a pink-violet arc, and
  -- green strings can never bloom (shader hue-excludes 90-162). Every hex is
  -- a NAMED kanagawa palette colour from kanagawa.nvim's colors.lua — nothing
  -- invented. One hue family per kind; exact shares only inside a family.
  ["kanagawa-dragon"] = {
    -- Key ramp: dragonYellow #C4B28A tan, lightness rungs = depth hierarchy
    -- (same structure as everforestv3's tan ramp). Moving keys OFF the derived
    -- pale blue frees the blue/aqua arc for values.
    ["@property.yaml.toplevel"] = "#d5c8a8",
    ["@property.yaml.level2"] = "#C4B28A", -- dragonYellow verbatim
    ["@property.yaml"] = "#a89670",
    ["@punctuation.special.yaml"] = "#957FB8", -- oniViolet: list dashes (violet arc freed by the tan key ramp)
    ["@punctuation.special.merge"] = "#957FB8", -- << merge keys, same machinery
    ["@label.yaml"] = "#957FB8", -- &anchor / *alias
    ["@string.yaml"] = "#7AA89F", -- waveAqua2: hue ~168, just outside the green
    ["@string.yaml.value"] = "#7AA89F", -- exclusion band, so values CAN glow
    ["@string.yaml.quoted"] = "#7AA89F", -- exact share: same kind, same colour
    ["@string.yaml.word"] = "#FFA066", -- surimiOrange: bare selectors
    ["@type.yaml.enum"] = "#7E9CD8", -- crystalBlue: Deployment, ClusterIP (carpYellow would sit on the tan key ramp)
    ["@string.yaml.version"] = "#98BB6C", -- springGreen: low-traffic, native slot
    -- Post-knob, dragon's KEY ramp owns the pale blue-violet arc — oniViolet
    -- landed inside it. Locators (urls, paths, images — an image ref IS a
    -- locator) take sakuraPink as ONE family instead.
    ["@string.yaml.url"] = "#D27E99", -- sakuraPink: locators
    ["@string.yaml.path"] = "#D27E99",
    ["@string.yaml.image"] = "#D27E99",
    ["@number.yaml.kdragon"] = "#FF5D62", -- peachRed: hot scalars
    ["@number.yaml.quantity"] = "#FF5D62",
    ["@constant.yaml.env"] = "#FF5D62", -- exact share, hot-scalar family
    ["@string.yaml.condition"] = "#FF5D62",
    ["@boolean.yaml.kdragon"] = "#98BB6C", -- springGreen, shares with version
    ["YamlExprProp"] = "#FFA066", -- surimiOrange: selector family with words
    ["YamlExprContext"] = "#7E9CD8", -- selector family with enums
    ["@function.call.bash"] = "#7AA89F", -- run: commands read as values
    ["@variable.parameter.bash"] = "#7E9CD8", -- flags, enum family
  },

}
