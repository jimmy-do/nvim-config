# Handoff — Storm theme (base16-tokyo-night-terminal-storm) customization

**Date:** 2026-07-21
**Branch:** `feat/antigravity-youtube-terminal-tools`
**Repo:** `/Users/jimmy/.config/nvim` (LazyVim + lazy.nvim; `lua/plugins/*.lua` auto-imported)

---

## What the user wants (the actual goals)

1. `base16-tokyo-night-terminal-storm` is the **default** colorscheme, always loaded with
   `bg_transparency = 100`, `fg_lightness = 60`, `fg_saturation = 50`.
2. A set of **hand-tested YAML hex colors baked in as that theme's DEFAULTS** — not
   re-applied on every event. Baking them in means `:FgAdjust`, `:Sepia`, and the bg
   knobs still transform them like any native theme color. **Constant re-application is
   the #1 thing to never do** — it pins the colors and makes the knobs look dead. This
   has been the user's repeated, emphatic correction.
3. YAML **value** color must apply to value strings **including URLs**
   (`server: https://kubernetes.default.svc`). URLs are the tricky case — see below.
4. Indent **scope** guide = maxed cyan `#00ffff`.
5. Periods colorable **globally** (across strings / unquoted values, all filetypes),
   excluding periods inside comments.
6. **Only ONE indent guide lit at a time** (the innermost scope). This is snacks' native
   behavior. (See the indent-ladder issue below.)
7. A **scratch testing file** (`yaml-tone.lua`) that applies colors ONCE on demand via
   `:YamlTone` — no autocmds. User edits hexes there, tests, and when happy, the values
   get transferred into the theme baseline. Testing != permanent application.

---

## Current file state

```
 M dotfiles/macos/ghostty/config.ghostty   (pre-existing user work — DO NOT TOUCH)
 M dotfiles/tmux/tmux.conf                  (prior session: unbind prefix C-o, rebind to floax)
 M lua/plugins/theme.lua                    (the main work)
 M lua/plugins/yaml-tone.lua                (scratch tester, tracked-modified)
?? lua/plugins/indent-ladder.lua            (untracked; just DISABLED, see below)
```

> ⚠️ `theme.lua` and the dotfiles contain the user's own pre-existing uncommitted work.
> **Never `git checkout`/`git restore` these files.** Reverting must be done by hand,
> edit by edit. The user has been burned by this before.

---

## theme.lua — what's implemented (with line numbers as of this writing)

- **`theme_baseline_colors`** (line ~750) + **`apply_theme_baseline_colors()`** (~762),
  called as the FIRST statement of `capture_base()` (~774). This is the core design:
  colors are set ONCE, immediately before base capture, so the pipeline reads them in as
  if the colorscheme shipped them. Downstream knobs then transform them normally.
  Current baked storm values:
  ```lua
  ["@property.yaml"]               = "#717FAB"  -- fields (keys)
  ["@punctuation.delimiter.yaml"]  = "#ff8c1a"  -- colons, commas
  ["@punctuation.special.yaml"]    = "#ff8c1a"  -- list dashes, anchors
  ["@punctuation.bracket"]         = "#f7ff00"  -- [] {}
  ["@string.yaml"]                 = "#00ffff"  -- values
  ["@comment"]                     = "#243745"
  ["Comment"]                      = "#243745"
  ```
- **Indent scope override** to `#00ffff` for storm in
  `apply_active_indent_scope_highlights()` (~894).
- **Global periods**: `STORM_PERIOD = "#ff8c1a"` (line 595). Storm opts into the existing
  `GlobalPunctBlue` matchadd overlay (line 620). The overlay already excludes comments
  (`GlobalCommentReset`, priority 200) and URLs (`GlobalUrlReset`, priority 96). This is a
  window-local `matchadd` — necessarily re-applied per window; that's the pre-existing
  mechanism, not the forbidden "re-apply the whole tone" pattern.
- **URL value fix** (the `server: https://...` case): `GlobalUrlReset` (priority 96)
  paints `https?://\S+` and normally sits ABOVE `@string.yaml`, so URLs took Normal's fg
  (looked like a field). Fix: for storm, after `adjust_all_highlights()` has already run
  the fg pipeline on `@string.yaml`, copy that group's *post-adjust* fg into
  `GlobalUrlReset` (in `run_adjust_all_highlights`, line ~1493). Plain fg copy done at the
  END of the pass — NOT a link (user explicitly rejected a link), NOT a pre-adjust copy
  (that came out darker than the other values).
- **`colorscheme = "base16-tokyo-night-terminal-storm"`** in the LazyVim spec (~1619) and
  a `colorscheme_defaults["base16-tokyo-night-terminal-storm"]` entry (~1866) with
  `bg_transparency 100`, `fg_lightness 60`, `fg_saturation 50`, etc.
- **`:ThemeReload`** command (~1630) — reloads the colorscheme from scratch and recaptures
  a pristine base. This is the "get back to theme defaults" escape hatch after testing.

### Testing loop
1. Edit hexes in `lua/plugins/yaml-tone.lua` (top `colors` table + `scope_color`).
2. `:source %` then `:YamlTone` — applies once, stamps over the knobs by design.
3. `:ThemeReload` to return to the baked-in theme defaults.
4. When a set looks right, move those hexes into `theme_baseline_colors` in `theme.lua`.

---

## indent-ladder.lua — REPURPOSED to a single ENCLOSING guide (RESOLVED)

`indent-ladder.lua` is an **untracked** custom plugin. It originally lit EVERY enclosing
level as a graded ladder (multiple guides) — that was the "random guides lit" bug.

**Resolution (2026-07-21):** rewritten to light exactly ONE guide — the one immediately
enclosing the cursor (`col = current_indent − shiftwidth`). Rule the user asked for:
shallow cursor → furthest-left guide (col 0) lights; one level deeper → next guide right;
never more than one. It is now `enabled = true`.

Why a custom overlay at all: **snacks' own scope highlight was the actual bug.** It lit
the guide at `scope.indent` (the *inside* column of the block) and drew NOTHING on leaf
`key: value` lines — so it was consistently one level too deep and usually invisible.
Fix has two parts:
- `lua/plugins/indent.lua`: `indent.scope.enabled = false` (stop snacks drawing the wrong
  column). Snacks still paints all the DIM guides (`SnacksIndent` `#444b6a`).
- `indent-ladder.lua`: overlay recolours just the single enclosing column, using the
  `SnacksIndentScope` hl group (theme.lua pins it to `#00ffff` on storm) at priority 250.

Verified headless (attach UI → set cursor → dump `indent_ladder` extmarks): exactly one
lit column per position — indent 2→col 0, 4→col 2, 6→col 4, 8→col 6; leaf lines now light
(snacks lit nothing before); top-level lines light nothing. Colour resolves to `#00ffff`.
**A full nvim restart is still needed** to drop any prior process's registered autocmds.

---

## ✅ RESOLVED — indent guide behavior (2026-07-21)

The "bright cyan guide at the far-left column plus dim guides" was **snacks' own scope
highlight lighting the wrong column** (see the indent-ladder section above for the full
diagnosis + fix). The user's rule — exactly ONE guide lit, the enclosing one, furthest-
left when shallow and moving right as you nest deeper — is now implemented and verified
headless. Requires a full nvim restart to take effect.

## ⚠️ Still unverified in a live GUI session

The URL-value color match and the baked baseline
under the knobs. The user has generally refused to run verification steps, so lean on the
headless nvim harness to confirm before claiming anything is fixed.

---

## Hard-won lessons (please read before editing)

- **Never re-apply the yaml tone on buffer/window/theme events.** Bake into the baseline
  (set once before `capture_base()`), let the knobs transform it. Re-applying = knobs look
  dead. This is the user's single most-repeated instruction.
- **Scope changes to storm ONLY.** Do not make edits global across colorschemes.
- **Never `git checkout` the modified files** — they hold the user's own uncommitted work.
- **`nvim_set_hl` replaces the whole definition** (drops `italic` etc. unless re-specified)
  and errors on invalid hex (e.g. 5-digit `#00000`); a `pcall` will swallow that silently.
- **Highlight priority scale:** matchadd overlays 95/96/200 < treesitter 100 < LSP
  semantic tokens 125. A URL/period overlay can outrank a treesitter capture.
- **Separate nvim processes don't share highlight state** — confirm which pane/process a
  buffer lives in before iterating on it.
- **Don't guess-edit.** The user has explicitly asked for diagnosis by running the config
  (headless nvim works well here), not speculative changes.

---

## Quick reference — storm palette (base16-tokyo-night-terminal-storm)

base00 `#24283b` · base01 `#1a1b26` · base02 `#343a52` · base03 `#444b6a` (comments) ·
base04/05 `#787c99` (fg/properties) · base06 `#cbccd1` · base07 `#d5d6db` ·
base08 `#f7768e` · base09 `#ff9e64` · base0A `#e0af68` · base0B `#41a6b5` (strings) ·
base0C `#7dcfff` (cyan) · base0D `#7aa2f7` · base0E `#bb9af7` · base0F `#d18616` (punct)
