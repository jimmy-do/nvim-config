# Minimal terminal-native helpers.

# Start a fresh inline Antigravity conversation in this terminal.
# Follow-ups resume the same conversation until Ctrl-C or Ctrl-D.
unalias g 2>/dev/null
g() {
  (
    builtin cd "$HOME/.local/share/gemini-chat" || return 1

    local question agy_rc prompt
    local pending_question="$*"
    local first_turn=1
    trap 'print; exit 130' INT

    while true; do
      if [[ -n "$pending_question" ]]; then
        question="$pending_question"
        pending_question=''
      else
        print -n 'You: '
        if ! IFS= read -r question; then
          print
          return 0
        fi
      fi

      [[ -n "$question" ]] || continue
      print

      # Print mode cannot display tool permission prompts. Keep this casual chat
      # tool-free so it answers inline instead of trying to act on the machine.
      prompt="Quick-chat mode. Reply directly using only your own reasoning. Do not call tools, run commands, browse, inspect or modify files, or use MCP. User message: $question"

      if (( first_turn )); then
        command agy --model 'Gemini 3.5 Flash (High)' --print "$prompt"
      else
        command agy --continue --model 'Gemini 3.5 Flash (High)' --print "$prompt"
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

# Let one-shot prompts contain zsh glob characters such as ? and * unquoted.
alias g='noglob g'

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
