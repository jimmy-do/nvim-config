# HANDOFF — indent-ladder guide animation (RESOLVED 2026-07-23)

**File:** `lua/plugins/indent-ladder.lua`
**Status:** ✅ Working, and verified against RENDERED OUTPUT rather than API probes.

## Final design: soft fill, then endless breathe

1. **Fill** — the guide grows from the cursor row out to both ends of the block
   over `anim.duration` (450ms), with a **6-row gradient trail** at each leading
   edge. Geometry lands on whole lines, so all the smoothness lives in the colour
   channel; a multi-row trail is what makes it read as a fill rather than a
   staircase.
2. **Breathe** — once fully filled, the guide fades all the way DOWN to the dim
   ladder colour (so it reads as fully dark/off, indistinguishable from every
   other guide) and back up to full brightness, forever, for as long as the cursor
   stays in that scope. Full swing, not a subtle shimmer: an early attempt used a
   30%-toward-white pulse and was invisible.

   Brightness axis: `0` = dim ladder colour, `1` = resting lit colour, `>1`
   overshoots toward white. Defaults `breathe_min = 0.0`, `breathe_max = 1.0`,
   `breathe_period = 2600`. The oscillator is `(1+cos)/2`, which starts at exactly
   1 so the breathe eases out of the fill with no jump and both turning points
   ease rather than snap.

There is deliberately **no flash during the fill**. That was tried and rejected:
it read as an ugly strobe, and rows that lit last never flashed at all.

## What actually fixed it

- **One `nvim_set_hl` per frame, not 33.** The trail ramp (`IndentLadderFade0..48`,
  dim → resting) is static and built **once** per `(dim, base)` pair. Only the
  single `IndentLadderGlow` group — shared by every fully-lit row — is rewritten
  per frame. The old per-frame 33-group rebuild (~2000 set_hl/sec) forced a full
  redraw each time and starved the loop; *that* was the "slideshow".
- **Frames are skipped when the rounded colour is unchanged.** During the slow
  breathe this idles most frames out entirely — no set_hl, no extmark touch, no
  redraw — giving exactly one redraw per visually distinct colour. `anim_dirty`
  forces a redraw when a scroll/edit needs one.
- **`hl_mode = "replace"`**, not `"combine"` — combine composited our colour with
  the dim SnacksIndent guide underneath and muted the pulse.
- **The `key == last_key` branch no longer stomps the animation.** `CursorMoved`
  fires on the same tick a scope is entered; it used to redraw at full extent in
  the plain resting colour and fight the timer for the whole run.
- **Edges overshoot the block by `trail` rows, and the drawn range is clamped to
  `from..to`.** Two separate bugs: without the overshoot the ends of the block
  settled at `1/trail` brightness ("not filling all the way"); widening the drawn
  range to make room for the trail lit rows outside the block ("filling past the
  nested chunk"). The gradient trails *behind* the edge, so the range must be
  clamped, not widened.

## YAML list items truncated the block (fixed)

`block_range` scans outward until it hits a line at indent <= the guide column.
A YAML list item puts the dash at the shallower indent but its content one level
deeper:

```yaml
targets:
  - name: alpha      # indent() == 4
    port: 1          # indent() == 6
  - name: beta       # indent() == 4  -> read as a dedent, block ENDED here
```

So with the cursor on `port: 1` (guide column 4) the lit guide covered exactly
that one list entry and died at the next dash — the "bar stops short at the
bottom" symptom. The scan now uses `struct_indent()`, which adds the width of a
leading `- ` to the line's indent.

Only the SCAN uses it. `draw()` still tests the real indent, so the dash rows
stay unpainted — the same place snacks' own dim ladder breaks — rather than
stamping a `│` on top of the dash character.

Verified: cursor on `port: 1` in a 3-entry list now lights all six `port:`/`tls:`
rows across all three entries, dash rows correctly skipped. Plain nested mapping
is unregressed (still stops exactly at the sibling key).

## Shallow comments truncated the block (fixed) — "the second guide is always short"

The real cause of the long-running "doesn't fill all the way at the bottom"
complaint. A comment at a SHALLOWER indent than the block:

```yaml
  request:
    target: example
# ======== SECTION ========    <- indent 0, read as a dedent, block ENDED here
    headers:
      accept: json
```

`block_range` stopped dead at the banner, so the lit guide covered 2 lines while
snacks' dim guide merely gapped that one row and carried on for another six. That
asymmetry is precisely what "the rest fill up just fine, it's always the second
one" describes — column 2 is simply the column the overlay owns at typical YAML
nesting depth, so it is the one whose truncation is visible.

Fix: `block_range` now treats such a comment as **transparent** — like a blank
line, it neither extends the block nor ends it. Comment leader comes from
`vim.bo.commentstring`, so it works per-filetype. A comment at a *deeper* indent
still extends the block normally (the `struct_indent` branch is tested first).

These rows stay unpainted either way, because `draw()` tests the real indent — so
the lit bar gaps in exactly the rows the dim one does.

Verified: block extent went 3..4 → 3..10, gapping only the banner row, still
stopping correctly at the `meta:` sibling.

## THE RULE for blank lines: lit extent == dim extent, exactly

This bit went back and forth twice, so state it plainly:

> **The lit guide covers exactly the rows the DIM guide covers at that column —
> no more, no less.**

Both complaints were the same bug from opposite sides, and both only ever showed
on blank lines:

- Lighting *no* blank line stopped the lit bar one row short of the dim bar.
- Lighting *every* blank line ran it past the end of the dim bar into empty space.

`guide_indent(l)` replicates snacks' rule verbatim (snacks/indent.lua ~line 253):
a blank line's indent is `min(prev_nonblank, next_nonblank)`, plus a shiftwidth if
those two differ and the result is > 0. Snacks draws a guide at column `c` on line
`l` exactly when `c < guide_indent(l)`, so `draw()` now lights a row on precisely
that condition, and `block_range` only extends through a blank while it holds.

Worked example (`helm.yaml` in the scratchpad):

```
  valueFiles:            indent 2
    - values.yaml        indent 4
    - values-prod.yaml   indent 4
                         blank: min(4,2)=2, differ -> +2 = 4  -> guides at cols 0,2
  parameters: []         indent 2
                         blank: min(2,0)=0                     -> NO guides at all
sources:                 indent 0
```

Verified both cursor positions: at column 2 the lit bar covers the first blank and
stops; at column 0 it covers the first blank and excludes the second. Both match
the dim ladder cell for cell.

**Careful if changing this:** "extend past the empty line" and "don't go past the
dim bar" are the SAME rule, not competing ones. Do not special-case either
direction — fix `guide_indent()` so it keeps matching snacks.

## Trailing blank lines were excluded (earlier fix, now subsumed by the rule above)

The scan treats a blank line as *provisional*: it neither extends the block nor
ends it. So a block ending in an empty row — the blank before the next top-level
key, which basically every YAML file has — stopped at the last line with text on
it:

```yaml
destination:
  server: https://…
  namespace: core-api      <- lit guide stopped HERE
                           <- but should run through this empty row
syncPolicy:
```

`block_range` now walks `to` forward and `from` back through any blank lines at
the block's edges. `draw()` already paints blank rows, so they light normally.

Deeper guides with indented content on *both* sides of a blank never showed this
(the blank is interior, so the scan sails past it) — which is exactly why only the
outermost guide looked broken while "the third indent does it fine".

Verified: `destination:` block went 2..5 → 2..6, now running through the empty row
and stopping at `syncPolicy:`. The three earlier cases are unregressed (15 / 6 / 7
lit rows respectively).

## :IndentLadderDebug

Put the cursor where the guide looks wrong and run it. Reports the guide column
(and which guide from the left it is), the block extent, the "visual run" the dim
guide reaches, and **the exact line that terminated the scan in each direction
with its indent** — which is what decides how far the guide reaches. This is what
found the comment bug in one shot after two wrong guesses from screenshots.

## Verification method — use this, not hl-group probes

Measured with a real nvim in a detached tmux session, polling
`tmux capture-pane -p -e` (~290 captures/sec) and parsing SGR into a per-cell
(char, fg) grid. Results:

- **44 distinct rendered states during the 450ms fill** ≈ 100fps actually
  delivered to the terminal.
- Row count grows 1→3→5→7→9→11→13 and **stops at 13** (the block's true extent),
  span 5–17. No overshoot.
- Every row reads full `#00ffff` by t=536ms. Fills all the way.
- Breathe sweeps `#00ffff` (max) → `#444c6a` (the dim guide colour = off) → back,
  with **every intermediate value present**, all 13 rows in lockstep. Trough lands
  at t≈1888ms = fill end + half a period, as designed.
- 681 distinct rendered states over 6.5s covering two full cycles.

Do not declare this working off `nvim_get_hl` values or extmark counts — that is
what produced three false "verified" claims previously.

## Knobs (top of the file)

```lua
local anim = {
  enabled        = true,  -- false = instant snap (good A/B baseline)
  duration       = 450,   -- ms to full extent
  fps            = 120,
  breathe        = true,  -- false = guide just rests once filled
  breathe_min    = 0.0,   -- 0 = dim ladder colour (reads as off)
  breathe_max    = 1.0,   -- 1 = resting lit colour; >1 overshoots toward white
  breathe_period = 2600,  -- ms per full bright -> dark -> bright cycle
  trail          = 6,     -- rows in the soft leading-edge gradient
}
```

## Unrelated changes still in this working tree

- `lua/config/options.lua` — block cursor no longer blinks (`n-v-c-sm:block`).
- `lua/config/theme_baseline.lua` — storm `@property.yaml` → `#364b8b`.
- `lua/plugins/theme.lua` — storm yaml fields/values stamped once per colorscheme
  load from the `ColorScheme` autocmd only (**never** move it into the deferred
  `apply_theme_adjustments` pass list — that would make `:FgAdjust` look dead);
  `:Sepia` now affects `fg` on base16/tokyonight when non-zero.
