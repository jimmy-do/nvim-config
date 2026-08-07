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
    ["@string.yaml"] = "#17ffc9", -- (166)

    -- --- Value shapes ------------------------------------------------------
    ["@type.yaml"] = "#ffc15e", -- (37)  base0A #ffc777 .53 -> sat .63
    ["@string.special.symbol.yaml"] = "#04d1f9", -- (190) base0C — the slot urls vacated 2026-07-27; bare selectors (plan, write)
    ["@constant.macro.yaml"] = "#ff6b6e", -- (359) base09 #f67f81 .48 -> sat .58
    ["@string.special.condition.yaml"] = "#ff6b6e", -- (359) shares env, as elsewhere
    -- 2026-07-27 hue respread: strings(166), version(180), url(190) and path
    -- (dim 190) sat inside a 24-degree cyan cluster and read as one colour in a
    -- manifest. Locators moved to the purple family, images to pink (base0F,
    -- previously unused). Same palette, wider spread. Old values, one-line
    -- revert: image #b17df1, version #20ffff, url #02d7f9, path #1e88a0.
    ["@string.special.image.yaml"] = "#f470ee", -- (303) base0F #ecb2f0 pushed to sat .54
    -- Path: own full slot, cyan 190 (free since urls moved to purple). NO dim
    -- variants of other classes — shade pairs read as lazy (2026-07-27).
    ["@string.special.path.yaml"] = "#02d7f9", -- (190) values.yaml, /healthz

    -- --- Scalars: base09, same as env — moonlight's own grouping ----------
    ["@number.yaml"] = "#ff6b6e", -- (359) 3, 1.5
    ["@number.quantity.yaml"] = "#ff6b6e", -- (359) 512Mi, 30s

    -- --- Not values, so not glowed ----------------------------------------
    -- null / ~ is absence; it tracks the comment colour, as in every table here.
    ["@constant.builtin.yaml"] = "#415281",
    ["@comment"] = "#415281", -- was #748cd6 — sat and lightness both halved
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
  --   2. `-` and `:` are copied from v3 verbatim: dash base08 red #ff5370, colon
  --      aqua #29cccc. They are NOT the same colour (a later request corrected an
  --      "all punctuation is one red" pass). The slate colon is still gone.
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
  --   colons        v4 briefly dropped them to slate, then briefly to base08 red;
  --                 both were rejected. They are v3's #29cccc aqua again -- the
  --                 only punctuation mark NOT in the red structure family, and the
  --                 one exception v3's own split earned (2026-07-29 request).
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
    ["YamlKeyD1"] = "#8b9fe0", -- apiVersion, kind, spec
    ["YamlKeyD2"] = "#6b7cb8", -- THE BASE (same as v3)
    ["@property.yaml"] = "#566490", -- depth 3+, deliberately receding

    -- --- STRUCTURE: one family, base08 red --------------------------------
    -- Dashes, anchors, aliases, merge keys and brackets are all "this is the
    -- shape of the document, not its content". gruvbox puts every one of them on
    -- one colour (its orange #fe8019); Moonlight's equivalent is base08.
    ["@punctuation.special.yaml"] = "#ff5370", -- list dashes
    ["@punctuation.special.document.yaml"] = "#ff5370", -- --- / ...
    ["@operator.yaml"] = "#ff5370", -- `<<`
    ["@punctuation.bracket"] = "#ff5370", -- [] {}  (was aqua in v3)
    ["@label.yaml"] = "#ff5370", -- &anchor / *alias
    ["@label"] = "#ff5370",

    -- --- Colons: v3's colon colour, copied verbatim -------------------------
    -- 2026-07-29, per request: take v3's `-` and `:` marks exactly as v3 sets
    -- them, and v3 does NOT put both on one colour. The dash keeps base08 red
    -- #ff5370 (above), the colon takes v3's aqua two steps down in value --
    -- #29cccc, hue 180, sat 0.80, still past the gate so it still glows, but the
    -- dash wins when both are on a line. This replaces the brief "all punctuation
    -- is one red" call; that note is kept above as the record of the trade.
    ["@punctuation.delimiter.yaml"] = "#29cccc", -- (180) v3's colon, verbatim

    -- --- DATA: mint, base0B scaled to ceiling -----------------------------
    ["@string.yaml"] = "#2fffc9", -- plain AND quoted: one class since the migration

    -- --- TYPE: gold, base0A pushed past the gate --------------------------
    -- 2026-07-29: base0A #ffc777 measures HSV sat 0.533 -- under the shader's
    -- 0.55 floor, so it never bloomed. Hue 41.6 is held exactly and the black
    -- point is pulled down instead (min channel 0x77 -> 0x5e), which buys
    -- saturation without touching the colour. One-line revert: #ffc777.
    ["@type.yaml"] = "#ffce5e", -- (41.6) sat 0.63  Deployment, ClusterIP
    ["@string.special.symbol.yaml"] = "#ffce5e", -- (41.6) bare selectors: plan, write, main

    -- --- SCALAR: purple, base0E pushed past the gate ----------------------
    -- #c49dff measured sat 0.384, badly under the gate -- the whole scalar family
    -- was dead on screen. Hue 264 held exactly, black point pulled to 0x5e.
    -- One-line revert: #c49dff.
    ["@number.yaml"] = "#9e5eff", -- (264) 3, 1.5
    ["@number.quantity.yaml"] = "#9e5eff", -- (264) 512Mi, 30s

    -- --- LOCATOR: pink, base0F pushed past the gate -----------------------
    -- #fbbdff measured sat 0.259, the worst offender in v4 -- a pastel, not a
    -- neon. Hue 296 held exactly, black point pulled to 0x5e. Still 32 degrees
    -- off purple, so the two families stay separable. One-line revert: #fbbdff.
    ["@string.special.path.yaml"] = "#f45eff", -- (296) values.yaml, /healthz
    ["@string.special.image.yaml"] = "#f45eff", -- (296) registry.io/api:1.2.3

    -- --- EXTERNAL: cyan, base0D (already at ceiling) ----------------------
    ["@constant.macro.yaml"] = "#40ffff", -- LOG_LEVEL, POSTGRES_HOST
    ["@string.special.condition.yaml"] = "#40ffff", -- ${{ }} conditions

    -- --- Absence ----------------------------------------------------------
    -- null / ~ is a VALUE, so per the 2026-07-29 "all values glow" request it is
    -- no longer parked on the dull side with the comments. It keeps the periwinkle
    -- hue (224) it had as stock base03 #748cd6 -- so absence still tracks the key
    -- ramp's family rather than joining a data family -- with the black point
    -- pulled to 0x5e to clear the 0.55 gate. One-line revert: #748cd6.
    ["@constant.builtin.yaml"] = "#5e89ff", -- (224) sat 0.63  null / ~
    ["@comment"] = "#415281",
    ["Comment"] = "#415281",
  },

  -- =========================================================================
  -- moonlightv5 — v4's role logic, re-paired around a cyan leader.
  -- Colorscheme: colors/moonlightv5.lua
  -- =========================================================================
  -- Built 2026-07-29. v4 chose its six family colours by staying inside
  -- Moonlight's slots; v5 chooses them from a named shortlist and hangs the same
  -- six roles off them. Frozen from v4 per request: the `-` dash, the `:` colon,
  -- and the entire key ramp. Only value families moved.
  --
  --   cyan   180  #00ffff   DATA        strings, quoted or not     sat 1.00  LEADER
  --   gold    42  #ffc777   TYPE        enums, bare selectors      sat 0.53
  --   blue   216  #3d8bff   LOCATOR     urls, paths, images        sat 0.76
  --   purple 270  #b06eff   EXTERNAL    versions, env vars, conds  sat 0.57
  --   pink   322  #ff6ec7   SCALAR      numbers, booleans, qtys    sat 0.57
  --   red    350  #ff5370   STRUCTURE   dashes, brackets, anchors  sat 0.67
  --   aqua   180  #29cccc   the colon, alone (v3's, frozen)        sat 0.80
  --
  -- WHY THIS PAIRING AND NOT ANOTHER
  --   leader      cyan takes STRINGS, the largest painted mass in any yaml file.
  --               A leader colour that only lands on versions or paths is not
  --               leading anything. This is the one structural difference from
  --               v4, where cyan was the small EXTERNAL family and mint was data.
  --   colon       #29cccc is cyan's own hue two steps down in value. That is a
  --               shade pair on paper, but the colon is punctuation and it is
  --               frozen by request; the value gap does the separating, exactly
  --               as v3 already ran cyan paths next to it.
  --   gold        kept at the exact requested hex. Note it measures HSV sat 0.533,
  --               a hair UNDER the shader's 0.55 bloom gate, so enums glow less
  --               than everything else here. That is the cost of the exact hex;
  --               v4's re-cut at the same hue is a one-line swap: #ffce5e.
  --   blue        locators. Links reading as blue needs no defence, and it is the
  --               only family that can sit 36 degrees off cyan without collapsing
  --               into it, because they never appear on the same token.
  --   pink        soft, not hot: #ff6ec7 is a rose, but cut to sat 0.57 so it
  --               still clears the gate. A softer pink (#ff8fd4, sat 0.44) cannot
  --               bloom at all, and glow was the stated preference.
  --   purple      the leftover slot, and the right one: version/env/condition are
  --               "comes from outside this file", and purple sits 48 degrees off
  --               pink and 54 off blue, so all three stay separable.
  --
  -- Hue spacing, in order: 180 / 216 / 270 / 322 / 350 / 42. Smallest gap is 28
  -- (pink -> red), and red is punctuation only, so no two VALUE families are
  -- closer than 36 degrees. No shade pairs.
  ["moonlightv5"] = {
    -- --- Key ramp: frozen, v3's/v4's ramp verbatim -------------------------
    -- Only level2 is load-bearing: apply_yaml_key_ramp recomputes the other two
    -- rungs from it (120% / 115% / 110% HSL lightness, bold on toplevel).
    ["YamlKeyD1"] = "#8b9fe0", -- apiVersion, kind, spec
    ["YamlKeyD2"] = "#6b7cb8", -- THE BASE
    ["@property.yaml"] = "#566490", -- depth 3+, deliberately receding

    -- --- STRUCTURE: one family, base08 red (frozen from v4) ----------------
    ["@punctuation.special.yaml"] = "#ff5370", -- list dashes
    ["@punctuation.special.document.yaml"] = "#ff5370", -- --- / ...
    ["@operator.yaml"] = "#ff5370", -- `<<`
    ["@punctuation.bracket"] = "#ff5370", -- [] {}
    ["@label.yaml"] = "#ff5370", -- &anchor / *alias
    ["@label"] = "#ff5370",

    -- --- Colons: v3's aqua, frozen ----------------------------------------
    ["@punctuation.delimiter.yaml"] = "#29cccc", -- (180) sat 0.80 v0.80

    -- --- DATA: the leader ---------------------------------------------------
    ["@string.yaml"] = "#00ffff", -- (180) sat 1.00
    ["@string.yaml"] = "#00ffff",

    -- --- TYPE: gold, the exact requested hex -------------------------------
    -- Under the 0.55 bloom gate by 0.017. Swap to #ffce5e (same hue) to glow.
    ["@type.yaml"] = "#ffc777", -- (41.6) Deployment, ClusterIP
    ["@string.special.symbol.yaml"] = "#ffc777", -- (41.6) bare selectors: plan, write, main

    -- --- SCALAR: soft pink, cut to clear the gate --------------------------
    ["@number.yaml"] = "#ff6ec7", -- (322) 3, 1.5
    ["@number.quantity.yaml"] = "#ff6ec7", -- (322) 512Mi, 30s

    -- --- LOCATOR: standard blue -------------------------------------------
    ["@string.special.path.yaml"] = "#3d8bff", -- (216) values.yaml, /healthz
    ["@string.special.image.yaml"] = "#3d8bff", -- (216) registry.io/api:1.2.3

    -- --- EXTERNAL: purple --------------------------------------------------
    ["@constant.macro.yaml"] = "#b06eff", -- (270) LOG_LEVEL, POSTGRES_HOST
    ["@string.special.condition.yaml"] = "#b06eff", -- (270) ${{ }} conditions

    -- --- Absence -----------------------------------------------------------
    -- null / ~ stays on the dull side here. v4's periwinkle #5e89ff sits 8
    -- degrees off this theme's locator blue, which is the shade pair v4's own
    -- header spends four paragraphs killing. Absence is not data; it recedes.
    ["@constant.builtin.yaml"] = "#748cd6", -- stock base03  null / ~
    ["@comment"] = "#415281",
    ["Comment"] = "#415281",
  },

  -- =========================================================================
  -- moonlightv7 — v6's colours, re-paired one-colour-per-role.
  -- Colorscheme: colors/moonlightv7.lua
  -- =========================================================================
  -- Built 2026-07-29. v6 stays frozen as the snapshot it is; this is the same
  -- palette with the FAMILIES made consistent, so :HlColor recolours a role here
  -- instead of an arbitrary slice of one. Read the header of colors/moonlightv7.lua
  -- for why lilac took the locators and why every `.yaml` row below is doubled.
  --
  --   DATA      #00e676  green   strings, quoted or not
  --   LOCATOR   #d98cff  lilac   urls, paths, images
  --   SCALAR    #40ffff  cyan    numbers, quantities
  --   BOOLEAN   #ff6a00  orange  true / false / yes / no
  --   EXTERNAL  #ff527d  rose    versions, conditions, env vars
  --   TYPE      #ffc777  gold    enums, bare selector words
  --   STRUCTURE #ff5370  red     dashes, doc markers, anchors, colons
  ["moonlightv7"] = {
    -- --- Key ramp: moonlight's, verbatim (same as v3/v4/v5/v6) --------------
    ["YamlKeyD2"] = "#6b7cb8", -- THE BASE (ramps to #8896c6)
    ["YamlKeyD1"] = "#8b9fe0", -- recomputed by the ramp
    ["@property.yaml"] = "#566490", -- recomputed by the ramp

    -- --- STRUCTURE: one family, and the colon joins it ----------------------
    -- The colon moving off cyan onto the dash mark's red is a 2026-07-29
    -- request, and it is the single intentional difference from v6's look.
    -- One-line revert to v6's cyan colon: #00d5ff.
    ["@punctuation.delimiter.yaml"] = "#ff5370", -- the `:`
    ["@punctuation.special.yaml"] = "#ff5370", -- list dashes
    ["@punctuation.special.document.yaml"] = "#ff5370", -- --- / ...
    ["@operator.yaml"] = "#ff5370", -- `<<`
    ["@label.yaml"] = "#ff5370", -- &anchor / *alias
    ["@label"] = "#ff5370",
    ["@punctuation.bracket.yaml"] = "#a3ace1", -- base05: brackets stay neutral

    -- --- DATA: tron green ---------------------------------------------------
    ["@string.yaml"] = "#00e676",
    ["@string.yaml"] = "#00e676",

    -- --- LOCATOR: one family, was three colours in v6 -----------------------
    ["@string.special.url.yaml"] = "#d98cff", -- https://, oci://
    ["@string.special.path.yaml"] = "#d98cff",
    ["@string.special.image.yaml"] = "#d98cff",

    -- --- SCALAR -------------------------------------------------------------
    ["@number.yaml"] = "#40ffff", -- 3, 1.5
    ["@number.quantity.yaml"] = "#40ffff", -- 512Mi, 30s

    -- --- BOOLEAN: its own family, because a switch is not data --------------
    ["@boolean.yaml"] = "#ff6a00", -- true/false/yes/no

    -- --- EXTERNAL: comes from outside this file -----------------------------
    ["@string.special.version.yaml"] = "#ff527d", -- apps/v1, 1.9.x
    ["@string.special.condition.yaml"] = "#ff527d",
    ["@constant.macro.yaml"] = "#ff527d", -- LOG_LEVEL, POSTGRES_HOST

    -- --- TYPE ---------------------------------------------------------------
    ["@type.yaml"] = "#ffc777", -- Deployment, ClusterIP
    ["@string.special.symbol.yaml"] = "#ffc777",

    -- --- ${{ }} internals: each mapped to a family above --------------------
    ["YamlExprSigil"] = "#d98cff", -- the ${{ }} marker: "from elsewhere"
    ["YamlExprBrace"] = "#a3ace1",
    ["YamlExprContext"] = "#ffc777", -- github, env, secrets = TYPE
    ["YamlExprProp"] = "#ff527d", -- EXTERNAL
    ["YamlExprDot"] = "#a3b3e4",
    ["YamlExprFunc"] = "#ff5370", -- STRUCTURE
    ["YamlExprNum"] = "#40ffff", -- SCALAR
    ["YamlExprStr"] = "#00e676", -- DATA
    ["YamlExprOp"] = "#ecb2f0",

    -- --- Embedded bash (run: blocks) ----------------------------------------
    ["@function.call.bash"] = "#00e676", -- commands read as values
    ["@variable.parameter.bash"] = "#ffc777", -- flags are selectors = TYPE

    -- --- Absence ------------------------------------------------------------
    ["@constant.builtin.yaml"] = "#748cd6", -- null / ~
    ["@comment"] = "#415281",
    ["Comment"] = "#415281",
  },

  -- =========================================================================
  -- ever-glow — everforest with the yaml values pushed into glow range.
  -- Colorscheme: colors/ever-glow.lua
  -- =========================================================================
  -- Built 2026-07-29 from the live everforest `:hi` dump. Every value family
  -- keeps its everforest HUE and its everforest ROLE; only saturation and value
  -- move (+35% HSV sat, +6% val). This is a sparkle pass, not a re-pairing —
  -- families that shared a colour under everforest still share it here.
  --
  --   role        everforest   ever-glow   hue    new sat
  --   strings     #94e07f      #81ed63     107    0.58   (green: see the shader
  --   bool/vers   #94e07f      #81ed63     107    0.58    note in the colors file)
  --   enums       #5ddef1      #2ce4ff     188    0.83
  --   locators    #ebc678      #f9c455      41     0.66
  --   scalars     #ff7c97      #ff4e73     348    0.69
  --   words       #ff9177      #ff6a47     12     0.72
  --   structure   #eb87e8      #f96af5     302    0.57
  --   colon       #539cdb      #268ee8     208    0.84
  --   doc/bracket #75b9ce      #5bbcda     194    0.58
  --
  -- Delete any line and that group falls back to everforest's derived value, so
  -- this table is also the diff: what is here is exactly what changed.
  ["ever-glow"] = {
    -- --- Key ramp -----------------------------------------------------------
    -- Only level2 is load-bearing; apply_yaml_key_ramp derives toplevel /
    -- @property.yaml / d3..d8 from it at 120/115/110% HSL lightness.
    --
    -- KEYS ARE MOONLIGHT'S RAMP, VERBATIM (2026-07-29, third cut). The history
    -- matters because two obvious answers are both wrong here:
    --   cyan #62c1e0  everforest's own key lifted — but it lands at hue 194, six
    --                 degrees off the boosted enums (#2ce4ff/188). Shade pair.
    --   tan  #c2b089  reads well on paper, but tan is hue 41 and the locators
    --                 (#f9c455) are already hue 41. Same collision, new hue.
    --   grey #8fa093  no collision, but Jimmy's call was "needs to be more blue".
    -- So the ramp is moonlightv3/v4/v5/v6's key base, unchanged: periwinkle at
    -- hue 224, sat 0.31. It clears the enums by 36 degrees, and its saturation is
    -- low enough that the blue-family punctuation (the colon #268ee8 at 208, null
    -- #3889d5 at 209) reads as punctuation rather than as more keys.
    ["YamlKeyD2"] = "#6b7cb8", -- THE BASE (moonlight's, ramps to #8896c6)
    ["YamlKeyD1"] = "#8b9fe0", -- recomputed by the ramp
    ["@property.yaml"] = "#566490", -- recomputed by the ramp

    -- --- STRUCTURE ----------------------------------------------------------
    ["@punctuation.special.yaml"] = "#f96af5", -- list dashes
    ["@operator.yaml"] = "#f96af5", -- `<<`
    ["@label.yaml"] = "#f96af5", -- &anchor / *alias
    ["@label"] = "#f96af5",

    -- --- Punctuation --------------------------------------------------------
    ["@punctuation.delimiter.yaml"] = "#268ee8", -- the colon
    ["@punctuation.special.document.yaml"] = "#5bbcda", -- --- / ...
    ["@punctuation.bracket.yaml"] = "#5bbcda", -- [] {} inside yaml

    -- --- DATA: green, everforest's signature --------------------------------
    ["@string.yaml"] = "#81ed63",
    ["@string.yaml"] = "#81ed63",

    -- --- TYPE ---------------------------------------------------------------
    ["@type.yaml"] = "#2ce4ff", -- Deployment, ClusterIP
    ["@string.special.symbol.yaml"] = "#ff6a47", -- bare selectors: plan, write, main

    -- --- SCALAR -------------------------------------------------------------
    ["@number.yaml"] = "#ff4e73", -- 3, 1.5
    ["@number.quantity.yaml"] = "#ff4e73", -- 512Mi, 30s
    -- exactly as everforest had it)

    -- --- LOCATOR: one family, one colour ------------------------------------
    ["@string.special.path.yaml"] = "#f9c455", -- values.yaml, /healthz
    ["@string.special.image.yaml"] = "#f9c455", -- registry.io/api:1.2.3

    -- --- EXTERNAL -----------------------------------------------------------
    ["@constant.macro.yaml"] = "#ff4e73", -- LOG_LEVEL, POSTGRES_HOST
    ["@string.special.condition.yaml"] = "#ff4e73", -- ${{ }} conditions

    -- --- ${{ }} expression internals ----------------------------------------
    ["YamlExprSigil"] = "#f556ef",
    ["YamlExprBrace"] = "#5bbcda",
    ["YamlExprContext"] = "#2ce4ff", -- github, env, secrets — enum family
    ["YamlExprProp"] = "#ff6a47", -- word family
    ["YamlExprDot"] = "#268ee8",
    ["YamlExprFunc"] = "#81ed63",
    ["YamlExprOp"] = "#f96af5",
    ["YamlExprNum"] = "#ff4e73",
    ["YamlExprStr"] = "#81ed63",

    -- --- Embedded bash (run: blocks) ----------------------------------------
    ["@function.call.bash"] = "#81ed63", -- commands read as values
    ["@variable.parameter.bash"] = "#2ce4ff", -- flags, enum family

    -- --- Absence: NOT boosted ----------------------------------------------
    -- everforest's #3889d5 verbatim. The +35% pass put this at #0175e2, which
    -- made null the loudest token on screen — absence is not data and should
    -- never out-shout a value.
    ["@constant.builtin.yaml"] = "#3889d5", -- null / ~
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
    ["@string.yaml"] = "#00ffcb",

    -- --- Value shapes ------------------------------------------------------
    ["@type.yaml"] = "#ff9e2c", -- orange: Deployment, RollingUpdate
    ["@string.special.symbol.yaml"] = "#ff9e2c", -- orange: bare selectors (plan, main)
    ["@constant.macro.yaml"] = "#00ffff", -- cyan: LOG_LEVEL, POSTGRES_HOST
    ["@string.special.condition.yaml"] = "#00ffff", -- cyan: shares env, as elsewhere

    -- --- Locators: one family, one colour ---------------------------------
    ["@string.special.path.yaml"] = "#4dc3ff",
    ["@string.special.image.yaml"] = "#4dc3ff",

    -- --- Hot scalars: the bright-ass pink ---------------------------------
    ["@number.yaml"] = "#ff2ee0", -- 3, 1.5
    ["@number.quantity.yaml"] = "#ff2ee0", -- 512Mi, 30s
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
    ["YamlKeyD1"] = "#d5c8a8",
    ["YamlKeyD2"] = "#C4B28A", -- dragonYellow verbatim
    ["@property.yaml"] = "#a89670",
    ["@punctuation.special.yaml"] = "#957FB8", -- oniViolet: list dashes (violet arc freed by the tan key ramp)
    ["@operator.yaml"] = "#957FB8", -- << merge keys, same machinery
    ["@label.yaml"] = "#957FB8", -- &anchor / *alias
    ["@string.yaml"] = "#7AA89F", -- waveAqua2: hue ~168, just outside the green
    ["@string.yaml"] = "#7AA89F", -- exclusion band, so values CAN glow
    ["@string.special.symbol.yaml"] = "#FFA066", -- surimiOrange: bare selectors
    ["@type.yaml"] = "#7E9CD8", -- crystalBlue: Deployment, ClusterIP (carpYellow would sit on the tan key ramp)
    -- Post-knob, dragon's KEY ramp owns the pale blue-violet arc — oniViolet
    -- landed inside it. Locators (urls, paths, images — an image ref IS a
    -- locator) take sakuraPink as ONE family instead.
    ["@string.special.path.yaml"] = "#D27E99",
    ["@string.special.image.yaml"] = "#D27E99",
    ["@number.yaml"] = "#FF5D62", -- peachRed: hot scalars
    ["@number.quantity.yaml"] = "#FF5D62",
    ["@constant.macro.yaml"] = "#FF5D62", -- exact share, hot-scalar family
    ["@string.special.condition.yaml"] = "#FF5D62",
    ["YamlExprProp"] = "#FFA066", -- surimiOrange: selector family with words
    ["YamlExprContext"] = "#7E9CD8", -- selector family with enums
    ["@function.call.bash"] = "#7AA89F", -- run: commands read as values
    ["@variable.parameter.bash"] = "#7E9CD8", -- flags, enum family
  },

  -- =========================================================================
  -- evergarden-fall / -spring / -winter (2026-07-30). Colorschemes:
  -- colors/evergarden-<season>.lua, palettes in lua/config/evergarden_seasons.lua.
  -- =========================================================================
  -- Stock evergarden has NO entry here and never will — it is Jimmy's, as-is.
  --
  -- ONE STRUCTURE, THREE TEMPERATURES. Every season assigns the same nine
  -- families in the same roles, so a manifest reads identically in all three and
  -- only the temperature changes:
  --
  --   keys      inside the shader's green dead band (90-162) — calm, structural,
  --             never blooming. This is the ONLY family there, on purpose.
  --   colon     a pale, near-white tint of the season. Bright by lightness, not
  --             by saturation, so it separates key from value without adding a
  --             ninth glowing thing to the line. Overrides the derived rule that
  --             sinks delimiters BELOW the dimmest key rung (see
  --             derive_yaml_baseline) — that rule is right for 400 themes and
  --             wrong for the one Jimmy asked to have a bright colon.
  --   values    all eight families outside the band at HSV sat >= 0.55 with a
  --             channel at/near 1.0, i.e. past the bloom gate. With
  --             :YamlValueBold on and yaml_value_brightness 40 these are what
  --             the eye lands on.
  --   null/~    absence, and comment-dim in every season. Never boosted.
  --
  -- Only @property.yaml is load-bearing on the key side: apply_yaml_key_ramp
  -- rebuilds D1..D8 off it at 120/115/110..85% lightness, which is the
  -- depth-by-colour ladder. The D1/D2 hexes below are what it lands on, kept
  -- for readability.
  --
  -- FALL — ember & harvest. Lichen keys, gold strings, and ONE cold family (the
  -- autumn sky) so the warm half has something to push against. No purple: the
  -- first cut put the locators on plum, which is a colour autumn does not own.
  ["evergarden-fall"] = {
    -- THE BASE, and the only load-bearing key hex: apply_yaml_key_ramp rebuilds
    -- D1..D8 off it. It is BRIGHT and SATURATED on purpose — that is what buys
    -- the stock-evergarden move Jimmy asked for, near-white at the top rung
    -- falling to deep colour at depth 8. The first cut used a mid-lightness,
    -- low-saturation moss (#9fc98f, L 68 / S 28): the ladder had nowhere to
    -- climb (D1 only reached L 82) and nothing to darken INTO, so eight rungs
    -- rendered as one grey-green. Hue stays in the shader's dead band (90-162),
    -- so a bright key still does not bloom.
    ["@property.yaml"] = "#a9f27d", -- lichen, hue 94 / L 72 / S 82
    ["YamlKeyD1"] = "#dcfbc9", -- recomputed by the ramp (near-white)
    ["YamlKeyD2"] = "#cbf9b0", -- recomputed by the ramp

    ["@punctuation.delimiter.yaml"] = "#f2ffd9", -- the colon: pale lichen-white
    ["@punctuation.special.document.yaml"] = "#b8985c", -- --- / ...
    ["@punctuation.bracket.yaml"] = "#b8985c", -- [] {}

    ["@punctuation.special.yaml"] = "#e8623c", -- list dashes: rust
    ["@operator.yaml"] = "#e8623c", -- `<<`
    ["@label.yaml"] = "#e8623c", -- &anchor / *alias
    ["@label"] = "#e8623c",

    ["@string.yaml"] = "#ffc247", -- values: harvest gold
    ["@type.yaml"] = "#ff8a3d", -- Deployment, ClusterIP: ember
    ["@string.special.symbol.yaml"] = "#ff5e9e", -- bare selectors: rosehip
    ["@string.special.url.yaml"] = "#61caff", -- locators: autumn sky (sat .62, past the gate)
    ["@string.special.path.yaml"] = "#61caff",
    ["@string.special.image.yaml"] = "#61caff",
    ["@number.yaml"] = "#ff4f5e", -- 3, 1.5: crimson
    ["@number.quantity.yaml"] = "#ff4f5e", -- 512Mi, 30s
    ["@constant.macro.yaml"] = "#ff4f5e", -- LOG_LEVEL, POSTGRES_HOST
    ["@string.special.condition.yaml"] = "#ff4f5e",
    ["@string.special.version.yaml"] = "#3ecfae", -- v1, apps/v1: smoke teal.
    -- Was dry olive (#b8d94a) for one cut and pulled straight back out: dimmed by
    -- the value knob it landed on #93ae3b, which is the key ramp's own green at
    -- depth 6. A high-traffic value family cannot wear a key colour (see the #1
    -- invariant in derive_yaml_baseline), so versions take the cold slot.
    ["@boolean.yaml"] = "#ff9e2c", -- true / false: amber
    ["@constant.builtin.yaml"] = "#4c4a3f", -- null / ~ : absence

    ["YamlExprSigil"] = "#ff9e2c",
    ["YamlExprBrace"] = "#b8985c",
    ["YamlExprContext"] = "#ff8a3d",
    ["YamlExprProp"] = "#ff5e9e",
    ["YamlExprDot"] = "#f2ffd9",
    ["YamlExprFunc"] = "#3ecfae",
    ["YamlExprOp"] = "#e8623c",
    ["YamlExprStr"] = "#ffc247",
    ["YamlExprNum"] = "#ff4f5e",

    ["@function.call.bash"] = "#ffc247", -- commands read as values
    ["@variable.parameter.bash"] = "#ff8a3d", -- flags, enum family
  },

  -- SPRING — bloom. Leaf keys over a mint catch-all (hue 167, just past the dead
  -- band, so spring is the only season whose strings actually burn green), with
  -- the warm half as pollen, apricot, coral and tulip. No purple here either.
  ["evergarden-spring"] = {
    ["@property.yaml"] = "#8dfa9e", -- new leaf, hue 128 / L 77 / S 92
    ["YamlKeyD1"] = "#d3fdda", -- recomputed by the ramp
    ["YamlKeyD2"] = "#c2fccc",

    ["@punctuation.delimiter.yaml"] = "#ffe3f2", -- the colon: pale blossom
    ["@punctuation.special.document.yaml"] = "#7fb6d9",
    ["@punctuation.bracket.yaml"] = "#7fb6d9",

    ["@punctuation.special.yaml"] = "#ff5ec4",
    ["@operator.yaml"] = "#ff5ec4",
    ["@label.yaml"] = "#ff5ec4",
    ["@label"] = "#ff5ec4",

    ["@string.yaml"] = "#3fffcc", -- values: mint
    ["@type.yaml"] = "#66d9ff", -- sky
    ["@string.special.symbol.yaml"] = "#ffd24d", -- pollen gold
    ["@string.special.url.yaml"] = "#ff7a5e", -- locators: coral
    ["@string.special.path.yaml"] = "#ff7a5e",
    ["@string.special.image.yaml"] = "#ff7a5e",
    ["@number.yaml"] = "#ff5f7a", -- tulip
    ["@number.quantity.yaml"] = "#ff5f7a",
    ["@constant.macro.yaml"] = "#ff5f7a",
    ["@string.special.condition.yaml"] = "#ff5f7a",
    ["@string.special.version.yaml"] = "#ffa04d", -- apricot
    ["@boolean.yaml"] = "#b6ff3d", -- hue 85: sparkles, the band starts at 90
    ["@constant.builtin.yaml"] = "#47594b",

    ["YamlExprSigil"] = "#ff7ad6",
    ["YamlExprBrace"] = "#7fb6d9",
    ["YamlExprContext"] = "#66d9ff",
    ["YamlExprProp"] = "#ffd24d",
    ["YamlExprDot"] = "#ffe3f2",
    ["YamlExprFunc"] = "#ffa04d",
    ["YamlExprOp"] = "#ff5ec4",
    ["YamlExprStr"] = "#3fffcc",
    ["YamlExprNum"] = "#ff5f7a",

    ["@function.call.bash"] = "#3fffcc",
    ["@variable.parameter.bash"] = "#66d9ff",
  },

  -- WINTER — ice. Nothing warm on screen: the eight value families walk the cold
  -- half of the wheel from aurora mint (172) round to winterberry (355), and the
  -- locators that used to be lantern amber are violet. Orange belongs to fall.
  ["evergarden-winter"] = {
    ["@property.yaml"] = "#7ff5aa", -- pine-mint, hue 142 / L 73 / S 85 (still in band).
    -- Hue 142, not the 160 of the first cut: at 160 the ramp sat ~17 delta-E from
    -- the aurora-mint enums, i.e. right on the "values never wear a key colour"
    -- bar. Walking the key base 18 degrees deeper into the band buys the
    -- clearance back without leaving the no-bloom zone.
    ["YamlKeyD1"] = "#cbfbdc", -- recomputed by the ramp
    ["YamlKeyD2"] = "#b6f9cd",

    ["@punctuation.delimiter.yaml"] = "#d9f4ff", -- the colon: pale ice
    ["@punctuation.special.document.yaml"] = "#6f93a8",
    ["@punctuation.bracket.yaml"] = "#6f93a8",

    ["@punctuation.special.yaml"] = "#ff5ea8", -- berry
    ["@operator.yaml"] = "#ff5ea8",
    ["@label.yaml"] = "#ff5ea8",
    ["@label"] = "#ff5ea8",

    ["@string.yaml"] = "#4de0ff", -- values: glacier
    ["@type.yaml"] = "#4dffe0", -- aurora mint
    ["@string.special.symbol.yaml"] = "#ff61e1", -- magenta (sat .62, past the gate)
    ["@string.special.url.yaml"] = "#9861ff", -- locators: violet (was orange), sat .62
    ["@string.special.path.yaml"] = "#9861ff",
    ["@string.special.image.yaml"] = "#9861ff",
    ["@number.yaml"] = "#ff5f6e", -- winterberry
    ["@number.quantity.yaml"] = "#ff5f6e",
    ["@constant.macro.yaml"] = "#ff5f6e",
    ["@string.special.condition.yaml"] = "#ff5f6e",
    ["@string.special.version.yaml"] = "#6194ff", -- frost blue (sat .62)
    ["@boolean.yaml"] = "#d161ff", -- orchid (sat .62)
    ["@constant.builtin.yaml"] = "#4a5a66",

    ["YamlExprSigil"] = "#ff7ac0",
    ["YamlExprBrace"] = "#6f93a8",
    ["YamlExprContext"] = "#4dffe0",
    ["YamlExprProp"] = "#ff61e1",
    ["YamlExprDot"] = "#d9f4ff",
    ["YamlExprFunc"] = "#6194ff",
    ["YamlExprOp"] = "#ff5ea8",
    ["YamlExprStr"] = "#4de0ff",
    ["YamlExprNum"] = "#ff5f6e",

    ["@function.call.bash"] = "#4de0ff",
    ["@variable.parameter.bash"] = "#4dffe0",
  },

}
