# Handoff: redesign my Starship prompt (quieter + modern)

## Your job
Design a **new visual identity** for my zsh Starship prompt. I want it **toned down and modern** — not another take on the maximalist "pill." Give me a small number of *genuinely distinct, opinionated* directions (rendered so I can see them), then implement the one I pick in `~/.config/starship.toml`. Do not hand me generic minimal-prompt clichés — push for a real point of view.

## The core problem
My whole terminal is themed from one palette + one shape language. My tmux **panes, bar, and chips** all wear rounded powerline caps, ink-knockout text on filled slabs, and chevron wedges — and my **Starship prompt is currently the same widget** (a long horizontal "pill" of colored segments). Prompt and tmux chrome have become indistinguishable. The fix is to make the prompt **quiet and clearly a different object** from the chrome, while still feeling like it belongs to the same machine.

Already rejected as too elementary: bare grey text, mid-dot flow, `╭─ ╰❯` corner rule, bracketed fields, underline accent, single "danger chip," prompt-only caret, and any "just reskin the pill" variant. Clear those from the table and go further.

## What I actually want
- **Restraint as the medium.** Mostly desaturated / low-contrast; spend color deliberately, not everywhere.
- **Modern, considered typography-of-the-terminal** — thoughtful use of glyphs, spacing, weight, box-drawing/Unicode, negative space. Surprise me with structure I haven't seen.
- Clear visual separation from filled-slab powerline chrome (my tmux).
- Legible at a glance for what I check most: cwd, git state, and **kube/terraform context** (I'm a platform/DevOps engineer — Helm, K8s, Terraform, YAML all day). The thing that says "you're pointed at prod" must be unmissable even in an otherwise calm prompt.

## HARD CONSTRAINTS (these are load-bearing — read before designing)
Read `~/.config/starship.toml` fully first; it's heavily commented. Non-negotiables:
1. **No `right_format` / RPROMPT.** Measured: a non-empty RPROMPT makes zsh re-place the right margin on every SIGWINCH, and tmux fires WINCH continuously while dragging a pane divider → stacks duplicate prompts. Keep everything on the left. (So: no right-aligned clock/metadata.)
2. **Two-line prompt** already exists (info line, then caret alone on line 2) with a `$line_break` after `$status`. A two-line design is fine and encouraged.
3. **Transient prompt is wired for zsh by hand** via `zsh/starship-transient.zsh` + a `[profiles] transient = "$character"` block that MUST stay last in the file (it's a TOML table that swallows following top-level keys). Any redesign must keep transience working and keep `[profiles]` last.
4. **Palettes live in `[palettes.*]`** and are shared with tmux via a `pill` script that reads `pill_*` hexes from this same file. If you add colors, don't break the `seg_*` / `pill_*` naming other tools depend on; prefer adding a new palette over mutating the shared one.
5. Prefer `"\uXXXX"` escapes for glyphs in double-quoted strings (bare glyphs have been silently blanked before). Verify any Nerd Font glyph you rely on actually exists.
6. `command_timeout = 2000`, `add_newline = false`. Keep the prompt fast — no slow custom commands.

## Modules currently in play
os, directory, git_branch/state/status, language versions (many), docker_context, conda, pixi, kubernetes, terraform, helm, cmd_duration (min 2s), jobs, status, character. I can drop noisy ones — versions especially. Kube/terraform/helm matter most.

## Deliverables
1. A short design rationale: what the modern direction *is* and why it reads as "prompt, not chrome."
2. **Rendered previews** I can actually look at (an HTML/terminal mock is fine) showing 2–3 distinct directions in real color, including how they degrade (clean repo, dirty repo, prod kube context, failed exit, long path).
3. After I pick: the real edited `~/.config/starship.toml`, honoring every constraint above, plus any palette/transient wiring changes.

## Environment
macOS, zsh, tmux, Ghostty terminal, Nerd Font installed, CRT-ish shader dims output ~0.64 (contrast math in the toml assumes this). Starship ~1.26.
