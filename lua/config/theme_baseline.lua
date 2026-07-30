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
  -- base16 scheme now. That tuning lived on in a copy called stormv2, which was
  -- itself deleted 2026-07-29; nothing in the storm family remains.

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
    -- No key ramp here on purpose: v2's keys come from derive_yaml_baseline in
    -- theme.lua, i.e. moonlight's own fg ramp. (A light-blue ramp was added here
    -- 2026-07-29 and removed the same day -- v2 was never meant to change.)

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
    -- Set EXPLICITLY. Leaving these out lets toplevel keys fall through to
    -- base16's own near-white #d9ddf3 at sat 0.11, which puts a white key next
    -- to a pale value on the very first line of every manifest. Three rungs
    -- descending by depth on one hue.
    --
    -- All built from Moonlight's own blues (base03 #748cd6 / base02 #596399),
    -- all kept BELOW the gate on purpose -- the keys are the dull anchor the
    -- glow reads against.
    --
    -- 2026-07-29: a full-saturation green ramp (#00ff00 base) was tried here and
    -- reverted the same day. Do not retry it.
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
    -- 2026-07-29: version/condition were #ff8486 -- base09 #f67f81 scaled to the
    -- ceiling, which turned an orange into a PINK at hue 359, nine degrees off
    -- the base08 #ff5370 on dashes and anchors. Two pinks that close read as one
    -- colour rendered twice, not as two classes. They now take base0E, the purple
    -- slot images vacated the same day. One-line revert: #ff8486.
    ["@string.yaml.version"] = "#c49dff", -- (265) stock base0E #b994f1 -> ceiling  apps/v1, 1.9.x
    ["@constant.yaml.env"] = "#2fffc9", -- stock base0B #2df4c0 -> ceiling  LOG_LEVEL
    ["@string.yaml.condition"] = "#c49dff", -- (265) shares version, as elsewhere
    -- Image was #c49dff (stock base0E #b994f1 scaled up). That is a lavender,
    -- not a pink, and next to the #fbbdff url it read as the dim half of a
    -- shade pair -- the exact objection the path line below already records.
    -- 2026-07-29: images now take the bright pink outright, so the locator
    -- family is ONE pink (url + image) and ONE cyan (path). One-line revert to
    -- the lavender: #c49dff.
    ["@string.yaml.image"] = "#fbbdff", -- stock base0F, shared with url
    ["@boolean.yaml.kdragon"] = "#04d6ff", -- stock base0C #04d1f9 -> ceiling  true/false
    ["@number.yaml.kdragon"] = "#40ffff", -- stock base0D, already at ceiling  3, 1.5
    ["@number.yaml.quantity"] = "#40ffff", -- stock base0D, already at ceiling  512Mi
    ["@label.yaml"] = "#ff5370", -- stock base08, already at ceiling  &anchor / *alias
    ["@label"] = "#ff5370", -- stock base08, already at ceiling

    -- --- Locators ----------------------------------------------------------
    ["@string.yaml.url"] = "#fbbdff", -- stock base0F #ecb2f0 -> ceiling  https://
    -- Path was #f9a5ff: the URL pink one step down in weight. On screen that read
    -- as two pinks a hair apart, not as a hierarchy -- a repoURL and the helm path
    -- three lines below it looked like the same colour twice (2026-07-29). Paths
    -- are now cyan, so the locator family is ONE pink and ONE cyan instead of a
    -- shade pair. Same objection moonlightv2 already records: shade pairs read as
    -- lazy. Old value, one-line revert: #f9a5ff.
    ["@string.yaml.path"] = "#00ffff", -- values.yaml, /healthz

    -- --- The dull anchor: absence, prose, and the key ramp ----------------
    -- These are deliberately left below the gate. Glow only reads as glow if
    -- something on screen is NOT glowing, and in YAML the keys and comments are
    -- the only mass large enough to play that role.
    ["@constant.builtin.yaml.kdragon"] = "#748cd6", -- stock base03  null / ~
    ["@comment"] = "#415281",
    ["Comment"] = "#415281",
  },
  -- =========================================================================
  -- moonlightv4 — v3's palette, assigned by ROLE instead of by SHAPE.
  -- Colorscheme: colors/moonlightv4.lua (read its header for the full rationale)
  -- =========================================================================
  -- Built 2026-07-29 from a measured comparison against gruvbox. gruvbox gives
  -- one colour per ROLE and reuses it everywhere -- its yaml image/url/path are
  -- all #d3869b, its quoted and unquoted strings are the same green. v3 gave one
  -- colour per SHAPE, which produced 9 value colours, several pairs the eye
  -- cannot separate, and literals sharing hexes with punctuation.
  --
  -- SIX value families here, one structure family, and every hex is a Moonlight
  -- slot. The families are 32+ degrees apart, so nothing reads as a shade pair:
  --
  --   mint   164  #2fffc9   DATA        strings, quoted or not          sat 0.82
  --   gold    42  #ffce5e   TYPE        enums, bare selectors           sat 0.63
  --   purple 264  #9e5eff   SCALAR      numbers, booleans, quantities   sat 0.63
  --   pink   296  #f45eff   LOCATOR     urls, paths, images             sat 0.63
  --   cyan   180  #40ffff   EXTERNAL    versions, env vars, conditions  sat 0.75
  --   blue   224  #5e89ff   ABSENCE     null / ~                        sat 0.63
  --   red    350  #ff5370   STRUCTURE   ALL punctuation: dashes, colons,
  --                                     brackets, anchors, aliases, merges
  --
  -- 2026-07-29 revision (three separate requests, all applied here):
  --   1. The green key ramp is reverted to v3's Moonlight blues.
  --   2. `-` and `:` are the SAME colour, base08 red -- there is no receding
  --      slate punctuation family any more.
  --   3. EVERY value family must clear the shader's HSV-sat 0.55 gate. gold
  --      (0.533), purple (0.384), pink (0.259) and null (0.46) all failed it and
  --      were re-cut: hue held to the decimal, black point pulled down to raise
  --      saturation. Same colours, actually blooming.
  --
  -- WHAT MOVED FROM V3, AND WHY EACH ONE MOVED:
  --
  --   quoted        #0dffc0 -> mint. Quoting is not a semantic difference, so it
  --                 is not a colour difference. gruvbox: quoted == unquoted.
  --   scalars       number/quantity were #40ffff -- the SAME hex as brackets and
  --                 `---`, i.e. a literal painted as structure -- and boolean was
  --                 #04d6ff, ten degrees off the numbers it is not the same thing
  --                 as. All three now share purple, the Constant role gruvbox
  --                 puts numbers, booleans and constants in together.
  --   locators      path was #00ffff, which put it in a four-way cyan pileup with
  --                 numbers, colons and booleans. url/image/path are one family
  --                 now, exactly as gruvbox has them.
  --   version       was #ff8486, a red. Red is the keyword/structure colour, so a
  --                 version string read as structure. Moved to cyan, which is
  --                 free now that scalars are purple.
  --   env           was #2fffc9, byte-identical to strings, so LOG_LEVEL was
  --                 indistinguishable from any other value. Joined version and
  --                 conditions: the family is "values that come from outside this
  --                 file", which is the one thing those three share.
  --   brackets      were #40ffff aqua while dashes were red, splitting structure
  --                 across two families. All structure is red now.
  --   colons        were #29cccc aqua in v3; v4 briefly dropped them to slate and
  --                 they are now base08 red, the same as every other punctuation
  --                 mark (2026-07-29 request). Glow volume is back.
  --
  -- The key ramp is v3's ramp, copied verbatim. v4 changes value logic, not keys.
  ["moonlightv4"] = {
    -- --- Key ramp: v3's ramp, copied verbatim ------------------------------
    -- 2026-07-29: the green ramp (#00ff00 base) is REVERTED. Back to v3's own
    -- Moonlight blues (base03 #748cd6 / base02 #596399), all below the glow gate
    -- on purpose -- keys are the dull anchor the glowing values read against.
    -- Green also sat inside the shader's hue 90-162 dead band, so it could never
    -- bloom; that was not the objection, but it is why green is not a candidate.
    --
    -- Only level2 is load-bearing: apply_yaml_key_ramp recomputes the other two
    -- rungs from it (120% / 115% / 110% HSL lightness, bold on toplevel), so the
    -- toplevel and bare hexes are overwritten on every reload. Written out anyway
    -- so this table shows what lands on screen. Retune level2, rescale the rest.
    ["@property.yaml.toplevel"] = "#8b9fe0", -- apiVersion, kind, spec
    ["@property.yaml.level2"] = "#6b7cb8", -- THE BASE (same as v3)
    ["@property.yaml"] = "#566490", -- depth 3+, deliberately receding

    -- --- STRUCTURE: one family, base08 red --------------------------------
    -- Dashes, anchors, aliases, merge keys and brackets are all "this is the
    -- shape of the document, not its content". gruvbox puts every one of them on
    -- one colour (its orange #fe8019); Moonlight's equivalent is base08.
    ["@punctuation.special.yaml"] = "#ff5370", -- list dashes
    ["@punctuation.special.doc"] = "#ff5370", -- --- / ...
    ["@punctuation.special.merge"] = "#ff5370", -- `<<`
    ["@punctuation.bracket"] = "#ff5370", -- [] {}  (was aqua in v3)
    ["@label.yaml"] = "#ff5370", -- &anchor / *alias
    ["@label"] = "#ff5370",

    -- --- Colons join STRUCTURE ---------------------------------------------
    -- 2026-07-29, per request: ALL punctuation is one colour. A colon is not a
    -- different kind of thing from a list dash, so `-` and `:` are both base08
    -- red #ff5370 (sat 0.675, hue 350 -- past the gate, so both glow). This
    -- reverses the "colons recede to slate" call in the v4 header note; that note
    -- is kept there as the record of the trade, not as current behaviour.
    ["@punctuation.delimiter.yaml"] = "#ff5370", -- was #566490 slate

    -- --- DATA: mint, base0B scaled to ceiling -----------------------------
    ["@string.yaml"] = "#2fffc9",
    ["@string.yaml.value"] = "#2fffc9",
    ["@string.yaml.quoted"] = "#2fffc9", -- exact share: quoting is not a role

    -- --- TYPE: gold, base0A pushed past the gate --------------------------
    -- 2026-07-29: base0A #ffc777 measures HSV sat 0.533 -- under the shader's
    -- 0.55 floor, so it never bloomed. Hue 41.6 is held exactly and the black
    -- point is pulled down instead (min channel 0x77 -> 0x5e), which buys
    -- saturation without touching the colour. One-line revert: #ffc777.
    ["@type.yaml.enum"] = "#ffce5e", -- (41.6) sat 0.63  Deployment, ClusterIP
    ["@string.yaml.word"] = "#ffce5e", -- (41.6) bare selectors: plan, write, main

    -- --- SCALAR: purple, base0E pushed past the gate ----------------------
    -- #c49dff measured sat 0.384, badly under the gate -- the whole scalar family
    -- was dead on screen. Hue 264 held exactly, black point pulled to 0x5e.
    -- One-line revert: #c49dff.
    ["@boolean.yaml.kdragon"] = "#9e5eff", -- (264) sat 0.63  true/false/yes/no
    ["@number.yaml.kdragon"] = "#9e5eff", -- (264) 3, 1.5
    ["@number.yaml.quantity"] = "#9e5eff", -- (264) 512Mi, 30s

    -- --- LOCATOR: pink, base0F pushed past the gate -----------------------
    -- #fbbdff measured sat 0.259, the worst offender in v4 -- a pastel, not a
    -- neon. Hue 296 held exactly, black point pulled to 0x5e. Still 32 degrees
    -- off purple, so the two families stay separable. One-line revert: #fbbdff.
    ["@string.yaml.url"] = "#f45eff", -- (296) sat 0.63  https://, oci://
    ["@string.yaml.path"] = "#f45eff", -- (296) values.yaml, /healthz
    ["@string.yaml.image"] = "#f45eff", -- (296) registry.io/api:1.2.3

    -- --- EXTERNAL: cyan, base0D (already at ceiling) ----------------------
    ["@string.yaml.version"] = "#40ffff", -- apps/v1, 1.9.x
    ["@constant.yaml.env"] = "#40ffff", -- LOG_LEVEL, POSTGRES_HOST
    ["@string.yaml.condition"] = "#40ffff", -- ${{ }} conditions

    -- --- Absence ----------------------------------------------------------
    -- null / ~ is a VALUE, so per the 2026-07-29 "all values glow" request it is
    -- no longer parked on the dull side with the comments. It keeps the periwinkle
    -- hue (224) it had as stock base03 #748cd6 -- so absence still tracks the key
    -- ramp's family rather than joining a data family -- with the black point
    -- pulled to 0x5e to clear the 0.55 gate. One-line revert: #748cd6.
    ["@constant.builtin.yaml.kdragon"] = "#5e89ff", -- (224) sat 0.63  null / ~
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
