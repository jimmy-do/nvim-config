# Minimal terminal-native helpers.

# Start a fresh inline Antigravity conversation in this terminal.
# Follow-ups resume the same conversation until Ctrl-C or Ctrl-D.
unalias g 2>/dev/null
g() {
  (
    builtin cd "$HOME/.local/share/gemini-chat" || return 1

    local question agy_rc
    local first_turn=1
    trap 'print; exit 130' INT

    while true; do
      print -n 'You: '
      if ! IFS= read -r question; then
        print
        return 0
      fi

      [[ -n "$question" ]] || continue
      print

      if (( first_turn )); then
        command agy --model 'Gemini 3.5 Flash (High)' --print "$question"
      else
        command agy --continue --model 'Gemini 3.5 Flash (High)' --print "$question"
      fi
      agy_rc=$?

      (( agy_rc == 130 )) && return 130
      if (( agy_rc != 0 )); then
        print -u2 "Antigravity exited with status $agy_rc."
        return "$agy_rc"
      fi

      first_turn=0
      print
    done
  )
}

# Prompt used by the same-session tmux YouTube picker window.
yt-prompt() {
  local query
  print -n 'Search YouTube: '
  IFS= read -r query
  [[ -n "$query" ]] || return 0
  yt "$query"
}

# Combined ChatGPT/Codex and Claude account limits (`usage` / `aiusage`).
source "$HOME/.config/zsh/ai-usage.zsh"
