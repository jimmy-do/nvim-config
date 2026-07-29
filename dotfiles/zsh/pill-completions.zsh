# Completion for the pill / tmux-* colour commands.
#
# Each command exposes a hidden `__complete` subcommand that prints its valid
# first-args (colour/theme names + verbs), read live from starship.toml. So this
# stays a single source of truth: add a pill_*/tmux_* line and it just shows up.
#
# Only the first argument is completed. A raw hex (e.g. `pill 95ff00`) is always
# valid too and simply gets no completion candidates.
_pill_family() {
  # Only complete the first positional arg; shapes/verbs take no second arg here.
  [[ $CURRENT -eq 2 ]] || return 0
  local -a cands
  # ${words[1]} is exactly what was typed (pill / pill2 / tmux-pane / ...),
  # which the scripts key off of via argv[0], so symlinks resolve correctly.
  cands=(${(f)"$(command ${words[1]} __complete 2>/dev/null)"})
  (( ${#cands} )) && compadd -a cands
}
compdef _pill_family pill pill2 tmux-bar tmux-chip tmux-pane tmux-pane-lines \
                     tmux-copy tmux-copymode-color cc-fg cc-fg-dim cc-em
