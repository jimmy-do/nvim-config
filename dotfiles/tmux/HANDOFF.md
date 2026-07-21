# tmux UI/UX — Designer Handoff

You are a top-tier terminal UI/UX designer taking over a **neon-futuristic tmux interface**
that is already ~80% built. Your job is to finish it and push it further.

Read this whole file before changing anything. It encodes constraints that were established
empirically, several of which are counter-intuitive and cost real time to discover. Do not
re-litigate them — verify them if you doubt them, but do not assume they are wrong.

---

## 0. Environment (verified, not assumed)

| | |
|---|---|
| tmux | **3.7b** |
| Terminal | Ghostty, `background = #080808`, `font-thicken-strength = 200` |
| Font | JetBrainsMono Nerd Font — full powerline + PUA glyph set available |
| Shaders | 3 active GLSL (`macbook-m4max-2056-theme-friendly-sharp`, `cursor_tail`, `sonic_boom_cursor`) |

**Config file locations — get these right:**

- tmux config: `~/.config/nvim/dotfiles/tmux/tmux.conf` (`~/.tmux.conf` is a symlink to it)
- Ghostty config **that actually loads**: `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
  - ⚠️ There is a **decoy** at `~/.config/nvim/dotfiles/macos/ghostty/config.ghostty` that Ghostty does **not** read. Verify with `ghostty +show-config` before touching anything Ghostty-related.
- nvim theme: `~/.config/nvim/lua/plugins/theme.lua`
- **colour generator: `~/.local/bin/tmux-color`** — symlinked as `tmux-bar`, `tmux-chip`,
  `tmux-pane`, `tmux-pane-lines`. Read §2 before touching any chrome colour.
- colour palette: `~/.config/starship.toml` (`pill_*` + `tmux_*` tables), shared with the
  prompt's `pill` / `pill2`
- user-facing docs for all of the above: `~/.config/nvim/dotfiles/zsh/keybind-palette.zsh`,
  sections `Theme · tmux` and `Theme · prompt`, surfaced in tmux by **`Prefix /`**. Adding a
  command means adding a `_keys_add` line there too — and adding a new *category* means
  adding its family to the `^(Filesystem|Flags|Theme|Your commands)` regex that appears in
  4 places in that file, or it is miscounted as a key binding instead of a command.

**The shader matters for colour work.** Everything composites through a phosphor shader over
`#080808`, which applies its own gamma. Colours chosen purely on paper sink or bloom. Judge
final values on screen; use maths to pick *candidates*, not verdicts.

---

## 1. The one design rule that must not be broken

> **Hue carries meaning. Brightness carries state.**

tmux signals the active pane by **lighting a border** — that is a *brightness* step, not a hue
step. Every ON/OFF pair in this config sits at roughly **5× luminance separation**.

Compute it, don't eyeball it (sRGB relative luminance):

```python
def L(h):
    h=h.lstrip('#'); c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    c=[(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4) for v in c]
    return .2126*c[0]+.7152*c[1]+.0722*c[2]
```

**This rule was learned the hard way.** An early attempt used `#00ffff` (L=0.787) as the
*inactive* border against `#FFA500` (L=0.482) active. The idle border was 1.6× **brighter**
than the active one — the indicator was inverted and the UI read as broken. If you introduce a
new pair, print both luminances and confirm active > inactive by ~4–6×.

---

## 2. The palette is GENERATED — do not hand-set chrome colours

⚠️ **This is the biggest change since the first draft of this document.** Every coloured
option in the status bar and the pane chrome is now written by a generator, not by hand.
Editing those lines directly works until the next colour switch, then it is silently lost.

**`~/.local/bin/tmux-color`**, invoked under four names (symlinks), each owning one surface:

| Command | Surface | Options it writes |
|---|---|---|
| `tmux-bar` | status bar **body** | `status-format[1]`, `status-right`, `window-status-separator`, `window-status-format` |
| `tmux-chip` | the two **chips** | `status-left`, `window-status-current-style`, `window-status-current-format` |
| `tmux-pane` | pane **titles** | `pane-border-format`, `display-panes-colour`, `display-panes-active-colour`, `clock-mode-colour` |
| `tmux-pane-lines` | pane **dividers** | `pane-border-style`, `pane-active-border-style`, `pane-scrollbars-style` |

Each rewrites **only** the block between its own markers in `tmux.conf`:

```
# >>> tmux-bar-managed >>>   …   # <<< tmux-bar-managed <<<        tmux.conf:106
# >>> tmux-chip-managed >>>  …   # <<< tmux-chip-managed <<<       tmux.conf:118
# >>> tmux-pane-lines-managed >>> … # <<< …-lines-managed <<<      tmux.conf:340
# >>> tmux-pane-managed >>>  …   # <<< tmux-pane-managed <<<       tmux.conf:348
```

Each block's header comment records its live `bright` / `dim` pair — **read those to learn
the current palette**, since there is no longer a fixed one to table here. Same command set,
same idioms throughout: bare name lists every colour with a live preview, `-` reverts (each
surface keeps its own previous), and a raw `#rrggbb` is accepted alongside palette names.

**One colour in, two out.** You give it BRIGHT; DIM is derived as **48% of it in RGB**.
That ratio is not arbitrary — it is what the hand-tuned pairs already in this config used
(`#FF8500`/`#7a4000` and `#03FC45`/`#017a22` are both 0.48). It is what keeps §1's
luminance rule true automatically for any colour the user picks.

**Dividers take BRIGHT, not DIM.** The window rails and the row-1 scanline are the bar's
structure; at DIM they vanished into `#080808`. This was a deliberate correction — do not
"restore" them to the dim colour.

### Where the colours come from

`~/.config/starship.toml`, the same palette the prompt's `pill` / `pill2` commands read. Two
tables, and the split is load-bearing:

- **`pill_*`** — shared with the prompt. Every entry clears the prompt invariant: black text
  ≥4.5:1 **and** the git logo `#f1502f` ≥2.0:1, both after the shader's ~0.64 dim.
- **`tmux_*`** — tmux only; `pill` / `pill2` never see these. They **fail** that invariant —
  they are the deep-saturation hues where a brand logo lands ~1.1–1.4:1. tmux chrome carries
  no brand logos (the only ink on them is `#080808` text on the two chips and the pane
  title), so they are safe there and only there. Bar of entry: ink ≥3.0:1.

Adding a colour is one line in either table; nothing is hardcoded in the generator. Anything
that clears 4.5 ink / 2.0 git belongs in `pill_*` so all six commands get it.

### Shapes are fixed, colours are not

The generator substitutes **colours only** — never a glyph, a cap, or a cell of padding.
Current shapes (all Powerline **Extra**, verified present in the JetBrainsMono cmap):

| Surface | Glyphs |
|---|---|
| both chips | `` `` U+E0BA / U+E0BC — solid shear |
| window rail | `` U+E0BB — hairline shear, same lean as the chips |
| pane title pill | `` `` U+E0B6 / U+E0B4 — rounded |

Slants on the bar and rounded caps on the pane pill is what keeps the two surfaces
distinguishable when they are set to the same colour. `ARROW` (U+E0B0) is retired but kept
in the source; the session chip wore it until the chips were unified on the shear.

### Colours that are NOT generated

`mode-style` / `copy-mode-match-style` (`#a0ffff`), `message-style` (`#00FF33`), and
`menu-selected-style` (`#FF2E97`) are the user's own deliberate choices, deliberately left
outside every managed block. They were changed once and the user asked for them back.

`#FF8500` was measured as **the brightest fully-saturated value that still reads orange** —
`#FF9100` crosses to hue 34° and reads amber. Treat it as a ceiling if you hand-pick an orange.

---

## 3. Hard tmux constraints — all verified by probe

1. **The built-in arrow cannot have its own colour.** `pane-border-indicators` arrows are drawn
   from `pane-active-border-style`. There is no second colour slot. The only workaround is
   disabling them and drawing your own glyph inside `pane-border-format`, which supports
   `#[fg=]` and `#{?pane_active,,}`. The user has **accepted** the native arrows as-is —
   don't "fix" this again without being asked.

2. **With `pane-border-status top`, tmux draws an arrow on EVERY pane's title bar**, not just
   the active one. Two panes ⇒ two arrows. The arrow means "a pane starts here", *not* "this
   pane is active". The pill carries active state.

3. **With exactly two panes the shared divider is split half/half** (active-side gets
   `pane-active-border-style`). Documented behaviour, not a bug. It is invisible when both
   colours match, and looks broken when they are two equally-bright different hues.

4. **`bg=` works on border styles.** The man page says "attributes are ignored" — that means
   *attributes* (bold, blink), not colours. `pane-active-border-style "fg=…,bg=…"` is legal.

5. **Setting `bg` on `window-status-current-style` fills the ENTIRE cell**, overrunning the
   rounded pill caps and squaring them off. Keep it `bg=default` and let
   `window-status-current-format` paint only between the caps. This regression has happened once.

6. **`pane-status-style` / `pane-status-current-style` do NOT affect pane borders.** Tested with
   loud values; zero effect. Border text colour comes only from the two border styles.

7. **tmux has no uppercase format modifier.** Uppercasing is done with a shell hook —
   `#(echo '#{session_name}' | tr a-z A-Z)`. Nested `#{}` inside `#()` **does** expand at render.

---

## 4. Gotchas that will bite you

- **Commas inside `#[...]` must be escaped `#,`** when the `#[...]` sits inside a `#{?...}`
  conditional, or tmux reads the comma as the branch separator.
  → `#[fg=#FFA500#,bold]`

- **Never paste raw PUA glyphs (`` `` ``) through a shell heredoc.** They get silently
  stripped. This happened **three times**. Always write them as Python escapes —
  `''`, `''` — and **assert against the file after writing**:
  ```python
  assert line.count('')==2 and line.count('')==2, 'CAPS MISSING'
  ```

  Note the damage looks *random*: only BMP private-use codepoints (U+E000-F8FF, i.e. the
  caps) are stripped, while supplementary-plane ones (U+F0000+, the Nerd Font window icons)
  pass through untouched. `tmux-color` defines every cap via `chr()` for this reason.

- **A cap lost from a template is invisible in review.** A shaped chip silently becomes a
  bare slab and nothing errors. This bit once already: the first draft of `tmux-color`
  dropped the caps while transcribing the option lines, and since a missing PUA glyph
  renders as zero-width nothing, the templates *looked* right in every diff. The writer now
  refuses any rewrite that would **lose** glyphs (gaining them is allowed -- that is a
  template fix landing) and reports how many. When editing templates, diff the cap census:
  ```python
  {hex(o): sum(1 for c in src if ord(c)==o)
   for o in (0xe0b0, 0xe0b4, 0xe0b6, 0xe0ba, 0xe0bb, 0xe0bc)}
  ```

- **To prove a change touched colours only**, normalise the hexes and diff the `set` lines.
  This catches accidental shape, padding or width drift that a colour-blind eye misses:
  ```python
  norm = lambda p: sorted(re.sub(r'#[0-9a-fA-F]{6}', '#HEX', l.rstrip())
                          for l in open(p, encoding='utf-8') if l.startswith('set'))
  # difflib.unified_diff(norm(before), norm(after)) must come back empty
  ```

- **`#{T:status-right}` does NOT execute `#()` shell hooks.** It will return blanks and make a
  working config look broken. Never use it to verify. Render properly (§5).

- **`ESC[49m`** (default background) is how tmux ends a background run. A naive colour parser
  that only knows `ESC[0m` will report phantom background leaks.

- **`tmux-continuum` prepends itself to `status-right`** at load. Expected. Currently appears
  exactly once — check for stacking if you rewrite that option.

---

## 5. How to verify — use this, don't guess

`capture-pane` captures *pane contents*, not borders or the status bar. To see chrome, run an
**inner tmux inside an outer tmux pane**, then capture the outer pane:

```bash
tmux -L outer new-session -d -x 118 -y 10 -s h
tmux -L outer set -g status off
tmux -L outer send-keys -t h "clear; tmux -L inner new-session -s demo" Enter
# copy the LIVE option values across, so you test what is really set:
for o in status-left status-right pane-border-format pane-border-style …; do
  tmux -L inner set -g "$o" "$(tmux show -gv $o)"
done
tmux -L outer capture-pane -p -e -t h   # -e keeps escape sequences
```

Parse the escapes to map fg/bg **per cell**. That is how every claim in this document was
established. Always `kill-server` both scratch sockets afterwards.

Also: `tmux -L test new-session -d && tmux -L test source-file <conf>` to confirm the file
parses **before** touching the user's live server.

---

## 6. Known drift — good first tasks

Four of the rows that used to sit here are **gone, not fixed**: `display-panes-colour`,
`display-panes-active-colour`, `clock-mode-colour` and `pane-scrollbars-style` are now
generated by `tmux-pane` / `tmux-pane-lines` (§2), so they track the chosen colour and
cannot drift again. What is left is everything still hand-set, line numbers current as of
this edit:

| File:line | Current | Problem |
|---|---|---|
| `theme.lua:73` | `WIN_DIVIDER = "#2ff5ff"` | Comment claims it is synced to `pane-active-border-style`, which is now whatever `tmux-pane-lines` last wrote. **Stale by construction — decide: read the live value, or keep nvim splits independent and fix the comment.** |
| `tmux.conf:279,282` | `popup-border-style`, `menu-border-style` `#22949f` | old dim cyan |
| `tmux.conf:396` | `copy-mode-mark-style bg=#2ff5ff` | old cyan |
| `tmux.conf:430` | `@floax-border-color #22949f` | old dim cyan |
| `tmux.conf:159` | sesh fzf `#0d3238/#2ff5ff/#ACFF00` | `#ACFF00` is otherwise dead; `#0d3238` is orphaned |

The obvious next generator is **popups/menus** — `popup-border-style`, `menu-border-style`,
`@floax-border-color` and the sesh fzf `--color` string, as a `tmux-popup` command. It is the
last cluster of hand-set chrome big enough to be worth a block.

⚠️ **`mode-style`, `copy-mode-match-style` (`#a0ffff`) and `message-style` (`#00FF33`) are the
user's own deliberate choices. They were changed once and the user asked for them back. Leave
them alone unless explicitly told otherwise.**

---

## 7. Unbuilt ideas the user has seen and not yet rejected

- `monitor-activity` -- **TRIED, AND DELIBERATELY OFF AGAIN.** Do not re-propose
  it without reading this. The flag means "emitted any output since you last
  looked", clears only by visiting, and on this machine background windows run
  agents, logs and builds -- so it is set on most windows most of the time and
  cannot tell "finished" from "still scrolling". Every window wore a permanent
  marker. Two attempts to soften it (promote the label to BRIGHT; shrink to a
  one-cell dot) failed identically: the event is not rare, so no amount of
  restraint in the drawing makes it informative. `monitor-silence` is the same
  failure inverted -- an idle shell is silent forever. `monitor-bell` stays ON: a
  bell is emitted deliberately by a program that decided you need to know.
  Two further traps found while doing this:
    - `window-status-activity-style` and `window-status-bell-style` ship as
      `reverse`, applied ON TOP of `window-status-format`. A dim label became a
      filled slab with knockout text -- identical to the active chip. Invisible
      until `monitor-activity` is on, because nothing ever set the flag before.
    - Switching monitoring off does NOT clear flags already set. Gate any marker
      on `#{monitor-activity}` as well as the flag or stale markers persist with
      nothing able to clear them.
- ~~Zoom state as a glyph in the window label~~ -- **BUILT**, but **NOT with the
  glyph this section used to recommend.** `U+26F6` is *not mapped in JetBrainsMono
  Nerd Font* -- verified by reading the cmap directly (11,756 codepoints; U+26F6
  absent). It would have shipped as a blank box in every zoomed window label. The
  build uses **`U+F065`** (expand). Alternates confirmed present: `U+F066`
  compress, `U+EB81`, `U+F0294`, `U+F04DE`, `U+F0B2`. Check the cmap before
  proposing a glyph -- the obvious search result was wrong here.
- ~~Powerline slant separators instead of `╱`~~ — **BUILT.** Font coverage was confirmed by
  reading the JetBrainsMono cmap directly: all 31 Powerline Extra glyphs are mapped. Both
  chips now wear the solid shear, the window rail the hairline one (§2). The `╱` rails in
  `status-right` were deliberately LEFT alone — they separate values, not chips, and a chip
  edge there would imply a boundary that is not one.
- ~~Second status row only shows a scanline outside resize mode~~ -- **BUILT.**
  Row 1 is transient now: five branches, in priority order -- resize table ->
  prefix pending (key hints, so you stop reaching for `prefix /`) -> copy mode
  (scroll position + keys) -> zoomed -> else the scanline, unchanged. Verified by
  expanding the format against a scratch session in each state rather than by eye.

---

## 7b. Still open

- **Prod-context inversion is built** (`kube-context`): a context matching
  prod/prd/production/live flips to void-on-`#FF8500` instead of taking a new hue.
  The same trick is available for `main`/`master` on the git branch and has not
  been done.
- **`theme.lua`'s `WIN_DIVIDER` is still `#2ff5ff`**, a retired cyan. Its comment
  no longer claims to be synced to `pane-active-border-style`, but the value is an
  open decision: leave nvim independent, or have it read the published `@ui-dim`.
- **`tmux-color` is untracked.** 332 lines, the source of truth for four surfaces,
  living only in `~/.local/bin`. The repo holds its output, not the generator.

---

## 8. Working style — the user is direct and iterates fast

- **Apply changes; don't stack up preview rounds.** One round of options is fine. He interrupted
  a preview run with "you done?" after two turns of galleries with zero files touched.
- **Back up before editing** — he asks. `git show HEAD:<path>` plus a timestamped copy.
  Backups live in `~/.claude/jobs/*/tmp/backups/`.
- **Apply live AND write the file.** `tmux set -g …` for instant feedback (runtime settings
  vanish on reload), then persist to `tmux.conf`.
- **Do not commit** to his dotfiles repo without asking. The repo has unrelated uncommitted work.
- He will tell you plainly when something is wrong. Own the mistake, state the root cause, fix
  it — don't over-apologise.

---

## 9. Your standing brief

Make it feel like an **instrument**, not a colour scheme. The interface should be calm at rest
and flash informative when state changes. Every hue must earn its place by meaning something;
every ON/OFF pair must obey the luminance rule. When you change a colour, grep for its other
uses first — this config's biggest recurring failure mode is a palette that moves in one place
and leaves ghosts everywhere else.
