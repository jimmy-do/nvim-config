# Minimal terminal-native helpers.

# Searchable, syntax-colored terminal keybind palette (`kk` / `keys`).
source "$HOME/.config/nvim/dotfiles/zsh/keybind-palette.zsh"

# Start a fresh inline Antigravity conversation in this terminal.
# Follow-ups resume the same conversation until Ctrl-C or Ctrl-D.
unalias g 2>/dev/null
g() {
  (
    local workdir="$PWD"
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

      # Print mode cannot display permission prompts, so tools are auto-approved
      # (--dangerously-skip-permissions) and edits auto-applied (--mode accept-edits).
      # The invoking directory is granted as the workspace.
      prompt="You are a concise terminal assistant with full access to the current working directory. You can read, write, and edit files and run terminal commands. Built-in web search is available for current information. Act directly on requests. User message: $question"

      if (( first_turn )); then
        command agy --model 'Gemini 3.5 Flash (High)' \
          --add-dir "$workdir" --mode accept-edits --dangerously-skip-permissions \
          --print "$prompt"
      else
        command agy --continue --model 'Gemini 3.5 Flash (High)' \
          --add-dir "$workdir" --mode accept-edits --dangerously-skip-permissions \
          --print "$prompt"
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

# Keep an empty lower YouTube pane alive until the picker sends it a video.
yt-pane-wait() {
  print 'Waiting for a YouTube selection from the pane above…'
  while true; do
    sleep 3600
  done
}

# Play a selected YouTube video directly as true-color terminal cells. This is
# deliberately tmux-native: no Kitty passthrough payload and no macOS window.
yt-pane-video() {
  local id="$1"
  [[ -n "$id" && "$id" != *[^A-Za-z0-9_-]* ]] || {
    print -u2 'Invalid YouTube video ID.'
    return 1
  }

  command mpv --vo=tct \
    --vo-tct-algo=half-blocks --vo-tct-buffering=frame \
    --macos-app-activation-policy=prohibited \
    --profile=sw-fast --brightness=-30 --really-quiet \
    --ytdl-format='bestvideo[height<=720]+bestaudio/best[height<=720]' \
    "https://www.youtube.com/watch?v=$id"

  print
  print 'Playback stopped. Choose another video above, or press Ctrl-y to close.'
  while true; do
    sleep 3600
  done
}

# Feed results to the persistent fzf instance in the upper YouTube pane.
yt-pane-search() {
  local query="$1" tab=$'\t'
  [[ -n "$query" ]] || return 0

  command yt-dlp "ytsearch12:$query" \
    --flat-playlist \
    --print "%(duration_string)s  %(channel)s  ·  %(title)s${tab}%(id)s" 2>/dev/null
}

# Replace the waiting/player process without disturbing the search pane.
yt-pane-play() {
  local video_pane="$1" id="$2"

  [[ "$video_pane" == %<-> ]] || return 1
  [[ -n "$id" && "$id" != *[^A-Za-z0-9_-]* ]] || return 1

  tmux respawn-pane -k -t "$video_pane" \
    "zsh -f -c 'source /Users/jimmy/.config/nvim/dotfiles/zsh/terminal-tools.zsh; yt-pane-video $id'"
}

# Stop the native mpv window tracked for one tmux window. Verify the command
# before killing so a stale/reused PID can never affect an unrelated process.
yt-pane-stop-external() {
  local window_id="$1" mpv_pid process_command
  [[ "$window_id" == @<-> ]] || return 1

  mpv_pid=$(tmux show-options -w -t "$window_id" -qv @yt_external_pid)
  if [[ "$mpv_pid" == <-> ]]; then
    process_command=$(ps -p "$mpv_pid" -o command= 2>/dev/null)
    if [[ "$process_command" == *'mpv --force-window=yes'* &&
          "$process_command" == *'youtube.com/watch?v='* ]]; then
      kill -TERM "$mpv_pid" 2>/dev/null
    fi
  fi

  tmux set-option -w -t "$window_id" -u @yt_external_pid 2>/dev/null
}

# Open a selected result as a real 1080p window over the current macOS Space.
# Accessory activation avoids pulling the user away from fullscreen Ghostty.
yt-pane-play-external() {
  local video_pane="$1" id="$2" window_id mpv_pid

  [[ "$video_pane" == %<-> ]] || return 1
  [[ -n "$id" && "$id" != *[^A-Za-z0-9_-]* ]] || return 1
  window_id=$(tmux display-message -p -t "$video_pane" '#{window_id}')
  [[ "$window_id" == @<-> ]] || return 1

  yt-pane-stop-external "$window_id"
  nohup mpv --force-window=yes \
    --macos-app-activation-policy=accessory \
    --ontop --ontop-level=system --focus-on=open \
    --autofit-larger=90%x90% \
    --ytdl-format='bestvideo[height<=1080]+bestaudio/best[height<=1080]' \
    "https://www.youtube.com/watch?v=$id" \
    </dev/null >/dev/null 2>&1 &!
  mpv_pid=$!
  tmux set-option -w -t "$window_id" @yt_external_pid "$mpv_pid"
}

# Persistent search UI for the upper YouTube pane. Searches reload in place,
# and Enter starts the selected result below without closing the finder.
yt-pane-picker() {
  local video_pane="$1"
  local search_command play_command external_command tab=$'\t'

  [[ "$video_pane" == %<-> ]] || {
    print -u2 'Missing tmux video pane.'
    return 1
  }

  search_command="sleep 0.35; zsh -f -c 'source /Users/jimmy/.config/nvim/dotfiles/zsh/terminal-tools.zsh; yt-pane-search \"\$1\"' _ {q}"
  play_command="zsh -f -c 'source /Users/jimmy/.config/nvim/dotfiles/zsh/terminal-tools.zsh; yt-pane-play \"\$1\" \"\$2\"' _ '$video_pane' {2}"
  external_command="zsh -f -c 'source /Users/jimmy/.config/nvim/dotfiles/zsh/terminal-tools.zsh; yt-pane-play-external \"\$1\" \"\$2\"' _ '$video_pane' {2}"

  while true; do
    fzf --disabled --height=100% --reverse \
      --delimiter="$tab" --with-nth=1 \
      --prompt='Search YouTube: ' \
      --header='Enter: pixel below · Ctrl-o: 1080p window · Ctrl-y: close' \
      --bind "change:reload($search_command || true)" \
      --bind "enter:execute-silent($play_command)" \
      --bind "ctrl-o:execute-silent($external_command)" </dev/null
    clear
  done
}

# Combined ChatGPT/Codex and Claude account limits (`usage` / `aiusage`).
source "$HOME/.config/zsh/ai-usage.zsh"
