# Rich, searchable terminal reference used by `keys`.
# Fields: category, key/command, purpose, example, useful context.
_keys_add() {
  print -r -- "$1"$'\t'"$2"$'\t'"$3"$'\t'"$4"$'\t'"$5"
}

# Semantic ANSI roles. These use terminal palette indexes, so Ghostty remains
# the source of the actual colors while every screen keeps the same grammar.
typeset -g _KEYS_SGR_TITLE=$'\e[1;36m'
typeset -g _KEYS_SGR_COMMAND=$'\e[1;32m'
typeset -g _KEYS_SGR_ARGUMENT=$'\e[1;35m'
typeset -g _KEYS_SGR_FLAG=$'\e[1;33m'
typeset -g _KEYS_SGR_HOME=$'\e[1;31m'
typeset -g _KEYS_SGR_PATH=$'\e[1;34m'
typeset -g _KEYS_SGR_SEPARATOR=$'\e[1;37m'
typeset -g _KEYS_SGR_RESET=$'\e[0m'

_keys_data() {
  _keys_add 'Filesystem · navigation' 'cd -' 'Return to the previous directory.' 'cd ~/Downloads; cd -' 'Great for bouncing between two projects.'
  _keys_add 'Filesystem · navigation' 'cd .. / ../..' 'Move up one or multiple directory levels.' 'cd ../..' 'Zsh tab completion can expand paths before you commit.'
  _keys_add 'Filesystem · navigation' 'cd ~ / cd' 'Jump directly to your home directory.' 'cd' 'A bare cd and cd ~ are equivalent.'
  _keys_add 'Filesystem · navigation' 'pushd DIR' 'Visit a directory and save where you came from.' 'pushd ~/Projects/my-app' 'Use dirs to inspect the directory stack.'
  _keys_add 'Filesystem · navigation' 'popd' 'Return to the last directory saved by pushd.' 'popd' 'Useful in scripts and multi-project sessions.'
  _keys_add 'Filesystem · navigation' 'dirs -v' 'Show the numbered directory stack.' 'dirs -v; cd ~2' 'In Zsh, ~2 refers to stack entry 2.'
  _keys_add 'Filesystem · navigation' 'Alt-c' 'Fuzzy-find a directory and cd into it.' 'Press Alt-c, type part of a folder, Enter' 'Provided by your loaded fzf shell bindings.'
  _keys_add 'Filesystem · navigation' 'Ctrl-t' 'Fuzzy-find a path and insert it at the cursor.' 'open <Ctrl-t>' 'Compose commands around files without typing paths.'
  _keys_add 'Filesystem · navigation' 'Tab / Shift-Tab' 'Complete a path or cycle completion choices.' 'cd ~/Pro<Tab>' 'Completion works for commands, flags, paths, and aliases.'

  _keys_add 'Filesystem · actions' 'open .' 'Open the current directory in Finder.' 'open .' 'macOS open uses the registered default application.'
  _keys_add 'Filesystem · actions' 'open FILE' 'Open a file in its default macOS application.' 'open report.pdf' 'Use open -a App FILE to choose a specific application.'
  _keys_add 'Filesystem · actions' 'open -R FILE' 'Reveal and select a file in Finder.' 'open -R ./build/output.log' 'Handy when you need to drag, share, or inspect metadata.'
  _keys_add 'Filesystem · actions' 'rg --files | fzf' 'Generate a fast, ignore-aware path list, narrow it interactively by filename, and print the selected path.' 'open "$(rg --files | fzf)"' 'rg --files honors ignore rules; fzf returns the selected line. Quote command substitution so paths containing spaces remain one argument.'
  _keys_add 'Filesystem · actions' 'rg TEXT' 'Search recursively inside file contents.' 'rg -n "TODO|FIXME"' 'Add -i for case-insensitive search and -g for globs.'
  _keys_add 'Filesystem · actions' 'fd NAME' 'Find files and directories by fuzzy name pattern.' 'fd invoice ~/Documents' 'Use -t f for files or -t d for directories.'
  _keys_add 'Filesystem · actions' 'mkdir -p PATH' 'Create a directory and any missing parents.' 'mkdir -p notes/2026/july' 'Safe when the directory already exists.'
  _keys_add 'Filesystem · actions' 'cp -R SRC DEST' 'Copy a directory tree.' 'cp -R templates/site ./new-site' 'Use cp -i when you want overwrite confirmation.'
  _keys_add 'Filesystem · actions' 'mv SRC DEST' 'Move or rename a path.' 'mv draft.md final.md' 'Moving within one filesystem is normally instant.'
  _keys_add 'Filesystem · actions' 'trash FILE' 'Move a path to macOS Trash when trash is installed.' 'trash old-download.zip' 'Prefer recoverable deletion over rm for personal files.'
  _keys_add 'Filesystem · actions' 'du -sh PATH' 'Show the total disk usage of a path.' 'du -sh ~/Downloads/*' 'Use dust or ncdu for an interactive overview if installed.'

  _keys_add 'Flags · search' 'rg -n -i -g GLOB' 'Show line numbers; ignore case; restrict searched paths with a glob.' 'rg -n -i -g "*.zsh" "bind-key" ~/.config' 'Repeat -g to combine filters; prefix a glob with ! to exclude it.'
  _keys_add 'Flags · search' 'rg -C N -l --hidden' 'Show N context lines; list matching files only; include hidden paths.' 'rg -C 2 -l --hidden "Prefix E" ~/.config' '--hidden still respects ignore files; use -g "!.git/**" to suppress Git metadata.'
  _keys_add 'Flags · search' 'rg -S -F -w' 'Use smart case; treat the pattern literally; require whole-word matches.' 'rg -n -S -F -w "resize-pane" ~/.config' '-F disables regular expressions, which is useful for punctuation-heavy text.'
  _keys_add 'Flags · search' 'fd -t f -H -E GLOB' 'Return files only; include hidden paths; exclude a name or glob.' 'fd -t f -H -E .git "config" ~/.config' 'Use -t d for directories; repeat -E for multiple exclusions.'
  _keys_add 'Flags · search' 'fd -d N -e EXT' 'Limit recursion to N levels; return only files with an extension.' 'fd -d 3 -e zsh . ~/.config' 'The extension is written without a leading dot.'

  _keys_add 'Flags · files' 'open -R PATH / -a APP PATH' 'Reveal a path in Finder; open a path with a specific application.' 'open -a "Preview" ~/Downloads/report.pdf' '-R selects the item in Finder instead of opening the file itself.'
  _keys_add 'Flags · files' 'cp -R -i / cp -n' 'Copy directories recursively and ask before overwrite; or never overwrite.' 'cp -R -i templates/site ./new-site' '-i is interactive; -n silently preserves an existing destination.'
  _keys_add 'Flags · files' 'du -sh / du -d N' 'Summarize one human-readable total; or limit reported directory depth.' 'du -d 1 -h ~/Downloads' '-s suppresses child entries, so do not combine it when you want a depth breakdown.'
  _keys_add 'Flags · files' 'eza --long --all --git' 'Use long rows; include hidden entries; add Git status columns.' 'eza --icons --long --all --git ~/.config' 'Your la wrapper already supplies these flags plus icons and color.'
  _keys_add 'Flags · files' 'eza --tree --level=N --git-ignore' 'Render a tree; cap its depth; omit Git-ignored paths.' 'eza --tree --level=3 --git --git-ignore .' 'Your lt, ltt, and lttt wrappers set levels 2, 3, and 4 respectively.'

  _keys_add 'Flags · infrastructure' 'kubectl get pods -A -o wide' 'Query every namespace and add node, IP, and other wide columns.' 'kubectl get pods -A -o wide' 'Replace wide with yaml or json when structured output is more useful.'
  _keys_add 'Flags · infrastructure' 'kubectl -n NS --context NAME' 'Target one namespace and explicitly choose a kubeconfig context.' 'kubectl --context staging -n payments get pods' 'Explicit targeting reduces the chance of operating on the wrong cluster.'
  _keys_add 'Flags · infrastructure' 'kubectl logs -f --tail=N --previous' 'Follow logs; start with the last N lines; read the prior container instance.' 'kubectl logs -f --tail=100 api-0' '--previous is for a restarted container and usually is not combined with -f.'
  _keys_add 'Flags · infrastructure' 'terraform -chdir=DIR plan' 'Run Terraform as though it started inside DIR.' 'terraform -chdir=infrastructure/dev plan' '-chdir must appear before the Terraform subcommand.'
  _keys_add 'Flags · infrastructure' 'terraform plan -out=FILE -var KEY=VALUE' 'Save an exact plan and set an input variable for that run.' 'terraform plan -out=tfplan -var "environment=dev"' 'Apply the reviewed file with terraform apply tfplan to avoid recalculating it.'
  _keys_add 'Flags · infrastructure' 'terraform apply -auto-approve' 'Apply without the interactive approval prompt.' 'terraform apply -auto-approve tfplan' 'Destructive-risk flag: use only after reviewing a saved plan in the correct workspace.'
  _keys_add 'Flags · infrastructure' 'git log --oneline --graph --decorate' 'Compact commits; draw branch topology; show branch and tag names.' 'git log --oneline --graph --decorate --all' 'Your gl alias supplies the first three flags; --all includes every local ref.'

  _keys_add 'Shell · editing' 'Ctrl-a / Ctrl-e' 'Move to the beginning / end of the command line.' 'Ctrl-a, type sudo, Space' 'Inside tmux, use Prefix Ctrl-a to send Ctrl-a through; Ctrl-e remains direct.'
  _keys_add 'Shell · editing' 'Alt-b / Alt-f' 'Move backward / forward by one word.' 'Hold Alt and tap b or f' 'More precise than repeatedly pressing arrow keys.'
  _keys_add 'Shell · editing' 'Ctrl-b / Ctrl-f' 'Move backward / forward by one character.' 'Ctrl-b, edit, Ctrl-e' 'Inside tmux, Ctrl-b is free because your prefix is Ctrl-a.'
  _keys_add 'Shell · editing' 'Ctrl-w' 'Delete the word behind the cursor.' 'git checkout feature/wrong → Ctrl-w' 'Deleted text enters the kill ring.'
  _keys_add 'Shell · editing' 'Alt-d' 'Delete the word ahead of the cursor.' 'Alt-b, Alt-d' 'Pairs nicely with Alt-b/Alt-f movement.'
  _keys_add 'Shell · editing' 'Ctrl-u' 'Delete from the cursor to the beginning.' 'Ctrl-u' 'This is explicitly configured in your Zsh setup.'
  _keys_add 'Shell · editing' 'Ctrl-k' 'Delete from the cursor to the end.' 'Ctrl-a, Ctrl-k' 'tmux claims Ctrl-k for pane navigation, so this is available outside tmux or when forwarded.'
  _keys_add 'Shell · editing' 'Ctrl-y' 'Paste the most recently killed shell text.' 'Ctrl-w, move, Ctrl-y' 'In tmux, your global Ctrl-y takes priority for YouTube.'
  _keys_add 'Shell · editing' 'Ctrl-o / Ctrl-x Ctrl-e' 'Edit the current command in your configured editor.' 'Type a long command, press Ctrl-o' 'Both bindings invoke edit-command-line in your config.'
  _keys_add 'Shell · editing' 'Ctrl-_' 'Undo the most recent shell-line edit.' 'Ctrl-w, then Ctrl-_' 'Often produced as Ctrl-/ depending on the terminal.'

  _keys_add 'Shell · history' 'Ctrl-r' 'Fuzzy-search backward through command history.' 'Ctrl-r, type kubectl logs' 'Type fragments from anywhere in the old command.'
  _keys_add 'Shell · history' 'Ctrl-p / Ctrl-n' 'Move to the previous / next history entry.' 'Ctrl-p, edit, Enter' 'Useful without leaving the keyboard home row.'
  _keys_add 'Shell · history' 'Up / Down' 'Navigate backward / forward through history.' 'Up, Up, edit, Enter' 'Your familiar fallback for sequential history.'
  _keys_add 'Shell · history' '!!' 'Expand to the entire previous command.' 'sudo !!' 'Use carefully: expansion happens before execution.'
  _keys_add 'Shell · history' '!$' 'Expand to the previous command’s final argument.' 'mkdir project; cd !$' 'Alt-. also inserts the last argument interactively.'
  _keys_add 'Shell · history' 'Alt-.' 'Insert the last argument from prior commands.' 'open Alt-.' 'Press repeatedly to walk farther back through history.'
  _keys_add 'Shell · history' 'fc' 'Open the previous command in your editor, then run it.' 'fc' 'Useful for repairing multi-line or complicated commands.'

  _keys_add 'Shell · control' 'Ctrl-c' 'Interrupt the foreground process or cancel the line.' 'Press Ctrl-c during a stuck command' 'Sends SIGINT; well-behaved programs clean up and exit.'
  _keys_add 'Shell · control' 'Ctrl-z' 'Suspend the foreground process.' 'Ctrl-z; bg' 'Resume with fg in front or bg in the background.'
  _keys_add 'Shell · control' 'Ctrl-d' 'Send EOF, or exit an empty interactive shell.' 'Ctrl-d at an empty prompt' 'In many interactive programs this means finished input.'
  _keys_add 'Shell · control' 'Ctrl-l' 'Clear and redraw the terminal display.' 'Ctrl-l' 'tmux claims Ctrl-l for pane navigation; use Prefix Ctrl-l while attached.'
  _keys_add 'Shell · control' 'jobs / fg / bg' 'Inspect and resume suspended shell jobs.' 'jobs; fg %1' 'Job numbers are scoped to the current shell.'
  _keys_add 'Shell · control' 'command &' 'Launch a command as a background job.' 'long-task &' 'Use wait, jobs, fg, or disown to manage it.'

  _keys_add 'Vim-style · search' '/pattern' 'Search forward in less, man pages, and tmux copy mode.' '/error' 'Press Enter to begin searching from the current position.'
  _keys_add 'Vim-style · search' '?pattern' 'Search backward in less, man pages, and tmux copy mode.' '?BEGIN' 'Especially useful in long logs and manual pages.'
  _keys_add 'Vim-style · search' 'n / N' 'Repeat the search in the same / opposite direction.' 'Type /timeout, Enter, then n n N' 'Direction is relative to the original / or ? search.'
  _keys_add 'Vim-style · movement' 'h j k l' 'Move left, down, up, and right in tmux vi copy mode.' '5j' 'Counts repeat motions; j/k also move linewise in less and man.'
  _keys_add 'Vim-style · movement' 'w / b / e' 'Move by word in tmux vi copy mode.' '3w' 'Jump to the next start / previous start / next end.'
  _keys_add 'Vim-style · movement' '0 / ^ / $' 'Move to line start / first text / line end in tmux copy mode.' '^' 'These are vi motions within captured pane history.'
  _keys_add 'Vim-style · movement' 'g / G' 'Jump to the beginning / end in less, man, or tmux copy mode.' 'G' 'A fast way to reach the newest output at the bottom.'
  _keys_add 'Vim-style · movement' 'Ctrl-d / Ctrl-u' 'Move down / up by half a screen.' 'Ctrl-d' 'Works in less, man, and tmux vi copy mode.'
  _keys_add 'Vim-style · movement' 'Space / b' 'Move down / up by one screen in less and man.' 'man tmux' 'Inside the viewer, Space pages down and b pages up; Ctrl-f/Ctrl-b are equivalents.'
  _keys_add 'Vim-style · viewers' 'q' 'Quit less, man, help, or tmux copy mode.' 'man rg; q' 'Many terminal viewers deliberately share this key.'
  _keys_add 'Vim-style · viewers' 'F' 'Follow appended output in less.' 'journalctl | less' 'Inside less, F follows appended output; Ctrl-c returns to navigation.'

  _keys_add 'tmux · windows' 'Cmd-Shift-h / Cmd-l' 'Move to the previous / next tmux window.' 'Cmd-Shift-h' 'Ghostty sends your custom User0/User1 sequences.'
  _keys_add 'tmux · windows' 'Cmd-;' 'Jump to the last-used tmux window.' 'Cmd-;' 'Ghostty sends the custom User2 sequence; no prefix is needed.'
  _keys_add 'tmux · windows' 'Alt-h / Alt-l / Alt-;' 'Previous / next / last tmux window fallbacks.' 'Alt-l' 'Useful on keyboards or terminals without the Cmd mappings.'
  _keys_add 'tmux · windows' 'Prefix c' 'Create a new window in the current pane directory.' 'Ctrl-a, then c' 'Your prefix is Ctrl-a, not the tmux default Ctrl-b.'
  _keys_add 'tmux · windows' 'Prefix w' 'Open the searchable session/window tree.' 'Ctrl-a, then w' 'Your tree uses zoomed full-window mode.'
  _keys_add 'tmux · windows' 'Prefix S' 'Open the tmux session chooser.' 'Ctrl-a, then Shift-s' 'Moved from lowercase s so it is harder to open accidentally.'
  _keys_add 'tmux · windows' 'Prefix &' 'Kill the current window after confirmation.' 'Ctrl-a, then &' 'The process and every pane in that window will close.'
  _keys_add 'tmux · windows' 'Prefix ,' 'Rename the current window.' 'Ctrl-a, then ,' 'Useful for keeping a long-running workspace legible.'
  _keys_add 'tmux · windows' 'Prefix 1…9' 'Jump directly to a numbered tmux window.' 'Ctrl-a, then 3' 'Your windows and panes start at index 1.'

  _keys_add 'tmux · panes' 'Ctrl-h/j/k/l' 'Move directly between tmux panes.' 'Ctrl-j' 'tmux forwards these keys into detected Vim-like or fzf processes instead of switching panes.'
  _keys_add 'tmux · panes' 'Prefix h/j/k/l' 'Select the pane left / down / up / right.' 'Ctrl-a, then h' 'Direct pane navigation independent of the running app.'
  _keys_add 'tmux · panes' 'Prefix | / Prefix -' 'Split horizontally / vertically in the current directory.' 'Ctrl-a, then |' 'Your custom splits replace tmux’s quote and percent keys.'
  _keys_add 'tmux · panes' 'Prefix H/J/K/L' 'Resize five cells toward the chosen direction.' 'Ctrl-a, then hold L' 'These bindings are repeatable.'
  _keys_add 'tmux · panes' 'Prefix R' 'Enter persistent pane-resize mode.' 'Ctrl-a, then Shift-r; tap or hold h/j/k/l' 'No more prefix presses: lowercase moves 1 cell, uppercase moves 5.'
  _keys_add 'tmux · panes' 'Esc / q / Enter' 'Leave persistent pane-resize mode.' 'Press q when the pane looks right' 'These cancel keys apply after entering resize mode with Prefix R.'
  _keys_add 'tmux · panes' 'Prefix ;' 'Jump back to the last-used pane.' 'Ctrl-a, then ;' 'Handy for toggling between two panes.'
  _keys_add 'tmux · panes' 'Prefix x' 'Kill the current pane after confirmation.' 'Ctrl-a, then x' 'Use exit when you prefer the shell to close itself normally.'
  _keys_add 'tmux · panes' 'Prefix q' 'Display pane numbers; press one to select it.' 'Ctrl-a, then q, then 2' 'Fast when the target pane is visually obvious.'
  _keys_add 'tmux · panes' 'Prefix f' 'Fuzzy-search visible text across every tmux pane, then jump to the selected match.' 'Ctrl-a, then f; type part of an error or command' 'Search spans panes in every window and session; the preview shows the selected pane’s recent history.'
  _keys_add 'tmux · panes' 'Prefix E' 'Spread panes evenly across the current layout.' 'Ctrl-a, then Shift-e' 'Your preferred reset before using Prefix z; avoids fiddly manual resizing.'
  _keys_add 'tmux · panes' 'Prefix z' 'Zoom or restore the active pane.' 'Ctrl-a, then z' 'Pairs naturally with Prefix E: normalize first, then focus.'

  _keys_add 'tmux · copy' 'Prefix [' 'Enter tmux’s vi-style scroll/copy mode.' 'Ctrl-a, then [' 'Now use /, ?, n, N, movement keys, and page motions.'
  _keys_add 'tmux · copy' '/ / ?' 'Search forward / backward through captured pane history.' '/exception' 'Repeat matches with n/N using vi copy-mode behavior.'
  _keys_add 'tmux · copy' 'u / d' 'Scroll up / down by one full page.' 'u' 'Custom copy-mode-vi bindings; enter copy mode first with Prefix [.'
  _keys_add 'tmux · copy' 'v → y' 'Begin a selection, then copy it and leave copy mode.' 'v, move with j/k, y' 'These are your explicit copy-mode-vi bindings.'
  _keys_add 'tmux · copy' 'Space / Enter' 'Default alternate selection and copy keys.' 'Space, move, Enter' 'Your custom v/y pair is usually more natural for Vim users.'
  _keys_add 'tmux · copy' 'Escape' 'Cancel selection or leave copy mode.' 'Escape' 'Explicitly configured in your tmux copy-mode table.'
  _keys_add 'tmux · copy' 'Prefix ]' 'Paste tmux’s most recently copied buffer.' 'Ctrl-a, then ]' 'tmux buffers are separate from the macOS clipboard by default.'

  _keys_add 'tmux · tools' 'Ctrl-y' 'Toggle your custom YouTube search/player column.' 'Ctrl-y' 'Global binding: no tmux prefix is needed.'
  _keys_add 'tmux · tools' 'Prefix m' 'Open your terminal Messages client in a popup.' 'Ctrl-a, then m' 'Popup opens at 90% width and height.'
  _keys_add 'tmux · tools' 'Prefix r' 'Reload the tmux configuration.' 'Ctrl-a, then r' 'Your binding shows a confirmation message afterward.'
  _keys_add 'tmux · tools' 'Prefix /' 'Open this keybind palette in a tmux popup.' 'Ctrl-a, then /' 'Custom binding; the popup closes automatically when the palette exits.'
  _keys_add 'tmux · tools' 'Prefix I' 'Install declared TPM plugins.' 'Ctrl-a, then Shift-i' 'Standard TPM binding once TPM is loaded.'
  _keys_add 'tmux · tools' 'Prefix Ctrl-s / Ctrl-r' 'Save / restore a tmux environment with resurrect.' 'Ctrl-a, then Ctrl-s' 'Your continuum plugin also autosaves every five minutes.'
  _keys_add 'tmux · tools' 'Prefix s' 'Save the current tmux environment with Resurrect.' 'Ctrl-a, then s' 'Convenient custom alias for Resurrect’s standard Prefix Ctrl-s save.'

  _keys_add 'Theme · tmux' 'tmux-bar [COLOR]' 'Recolor the top status bar body: kube context, git branch, clock, dividers, the rule, and inactive windows.' 'tmux-bar synth_orange' 'Bare tmux-bar lists every color with a live preview bar; tmux-bar - returns to the previous one. Takes a raw #rrggbb too.'
  _keys_add 'Theme · tmux' 'tmux-chip [COLOR]' 'Recolor the two chips only: the session name slab and the active-window pill.' 'tmux-chip synth_orange' 'Kept separate from tmux-bar so the chips can pop off a quieter bar. Sizes and powerline caps never change, only the color.'
  _keys_add 'Theme · tmux' 'tmux-pane [COLOR]' 'Recolor pane titles: the title pill, the Prefix-q pane numbers, and the clock.' 'tmux-pane electric_blue' 'Titles are deliberately separate from the dividers, so a lit pill can sit on a quiet border. Dividers are tmux-pane-lines.'
  _keys_add 'Theme · tmux' 'tmux-pane-lines [COLOR]' 'Recolor the pane dividers: both border rules and the copy-mode scrollbar.' 'tmux-pane-lines ice_cyan' 'The active pane is signalled by brightness, so the lit/unlit pair is generated for you: the color, and the same hue at 48%.'
  _keys_add 'Theme · prompt' 'pill [COLOR]' 'Repaint the starship prompt pill in one color from cap to cap, with brand logos.' 'pill turquoise' 'pill sep <shape> switches chevron, bar, or floating bubbles; pill logos brand|ink repaints icons; pill - reverts.'
  _keys_add 'Theme · prompt' 'pill2 [THEME]' 'Repaint the prompt with a different color per field, using ink logos.' 'pill2 dracula' 'Bare pill2 lists every theme as a live preview bar. Theme colors come from ~/.config/starship-pill-themes.txt.'

  _keys_add 'Ghostty' 'Ctrl-Tab / Ctrl-Shift-Tab' 'Move to the next / previous Ghostty tab.' 'Ctrl-Tab' 'These operate at the terminal-app level, outside tmux.'
  _keys_add 'Ghostty' 'Cmd-+ / Cmd-- / Cmd-0' 'Increase / decrease / reset terminal font size.' 'Cmd-+' 'Your size step is configured as half a point.'
  _keys_add 'Ghostty' 'Cmd-Left / Cmd-Right' 'Send shell beginning / end of line.' 'Cmd-Left' 'Mapped to terminal Home/End sequences in your config.'
  _keys_add 'Ghostty' 'Cmd-Shift-h / Cmd-l' 'Send custom sequences for previous / next tmux window.' 'Cmd-l' 'tmux receives these as User0 and User1.'
  _keys_add 'Ghostty' 'Cmd-;' 'Send tmux’s custom last-window sequence.' 'Cmd-;' 'tmux receives this as User2; the config has no Cmd-Shift-; mapping.'
  _keys_add 'Ghostty' 'Alt-h / Alt-l' 'Send Meta-h / Meta-l for tmux window navigation.' 'Alt-l' 'Fallback path shared with other compatible terminals.'
  _keys_add 'Ghostty' 'Select text' 'Copy a mouse selection directly to the macOS clipboard.' 'Drag across terminal output, then Cmd-v elsewhere' 'Enabled by copy-on-select = clipboard; no extra copy chord is required.'

  _keys_add 'Karabiner' 'Tap Caps Lock' 'Send Escape.' 'Tap Caps Lock to dismiss a mode or picker' 'Holding the same key acts as left Control; ordinary Caps Lock is intentionally unavailable.'
  _keys_add 'Karabiner' 'Hold Caps Lock' 'Act as left Control for another key.' 'Hold Caps Lock, press r' 'This is a global modifier layer and therefore also produces tmux’s Ctrl-based bindings.'
  _keys_add 'Karabiner' 'Right Cmd-h/j/k/l' 'Send global arrow keys left / down / up / right.' 'Hold Right Cmd, press j' 'Karabiner consumes these combinations before the foreground application sees them.'
  _keys_add 'Karabiner' 'Left Cmd-h in Ghostty' 'Rewrite Cmd-h to Cmd-Shift-h for previous tmux window.' 'In Ghostty, press Left Cmd-h' 'This intentionally replaces the normal macOS Hide action only in Ghostty.'

  _keys_add 'Your commands' 'ls / l' 'List files with icons or in a compact grid.' 'ls; l' 'These are eza-backed functions in your Zsh config, not system ls.'
  _keys_add 'Your commands' 'll / la' 'Long eza listing with Git state; la includes hidden files.' 'la ~/.config' 'Useful before edits to see permissions and repository status.'
  _keys_add 'Your commands' 'lt / ltt / lttt' 'Show eza trees two / three / four levels deep.' 'ltt' 'Git-ignored paths are hidden from these tree views.'
  _keys_add 'Your commands' 'gs / gp / gl' 'Git status / push / decorated graph log.' 'gs' 'Aliases from your active Zsh configuration.'
  _keys_add 'Your commands' 'k / kgp / kgpa' 'kubectl / pods / pods across every namespace.' 'kgpa' 'Shortcuts from your active Zsh configuration.'
  _keys_add 'Your commands' 'kdp / kl / klp / kctx' 'Describe pod / logs / previous logs / current context.' 'kl my-pod -f' 'Aliases still accept normal kubectl arguments afterward.'
  _keys_add 'Your commands' 'tf / tfp / tfa' 'Terraform / plan / apply shortcuts.' 'tfp' 'Review the plan before applying infrastructure changes.'
  _keys_add 'Your commands' 'yt QUERY / yt-stop' 'Search/play YouTube audio / stop your background player.' 'yt ambient jungle; yt-stop' 'Your fzf picker chooses among twelve search results.'
  _keys_add 'Your commands' 'g QUESTION' 'Start or continue your inline Antigravity assistant.' 'g explain this error' 'Conversation continues within that terminal invocation.'
  _keys_add 'Your commands' 'kk / keys' 'Open this palette using its short or long command.' 'kk; keys tmux' 'A category fragment such as keys tmux opens all matching sections.'
  _keys_add 'Your commands' 'keys --plain [SECTION]' 'Print the reference without opening fzf.' 'keys --plain tmux | less' 'An optional category fragment keeps plain output focused.'
}

_keys_tldr_root() {
  local candidate
  for candidate in \
    "$HOME/Library/Caches/tealdeer/tldr-pages/pages.en" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/tealdeer/tldr-pages/pages.en"; do
    [[ -d "$candidate" ]] && {
      print -r -- "$candidate"
      return 0
    }
  done
  return 1
}

_keys_build_tldr_index() {
  local root="$1" index_file="$2" temporary_file="${index_file}.$$.tmp"
  local index_dir="${index_file:h}"

  command mkdir -p "$index_dir" || return 1
  command find "$root" -type f -name '*.md' -exec awk '
    function clean(text) {
      gsub(/\t/, " ", text)
      gsub(/`/, "", text)
      gsub(/\{\{|\}\}/, "", text)
      return text
    }
    function emit(priority) {
      if (command_name == "") return
      if (platform != "common" && platform != "osx" && platform != "linux") return
      priority = platform == "osx" ? 1 : platform == "common" ? 2 : platform == "linux" ? 3 : 4
      if (summary == "") summary = "TLDR reference for " command_name "."
      printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\n", priority, command_name, platform, summary, first_example, search_text, source_path
    }
    FNR == 1 {
      if (NR > 1) emit()
      command_name = summary = first_example = search_text = ""
      source_path = FILENAME
      count = split(FILENAME, path_parts, "/")
      platform = path_parts[count - 1]
    }
    /^# / && command_name == "" {
      command_name = clean(substr($0, 3))
      next
    }
    /^> / && $0 !~ /^> More information:/ {
      line = clean(substr($0, 3))
      summary = summary == "" ? line : summary " " line
      next
    }
    /^- / {
      line = clean(substr($0, 3))
      sub(/:$/, "", line)
      search_text = search_text == "" ? line : search_text " " line
      next
    }
    /^`.*`$/ && first_example == "" {
      first_example = clean(substr($0, 2, length($0) - 2))
    }
    END { emit() }
  ' {} + | command sort -t $'\t' -k2,2 -k1,1n | awk -F '\t' '
    !seen[$2]++ {
      printf "tldr · %s\t%s\t%s\t%s\t%s\t%s\n", $3, $2, $4, $5, $6, $7
    }
  ' >| "$temporary_file" || {
    command rm -f "$temporary_file"
    return 1
  }

  command mv "$temporary_file" "$index_file"
}

_keys_tldr_index() {
  local root index_file
  root=$(_keys_tldr_root) || return 1
  index_file="${XDG_CACHE_HOME:-$HOME/.config/.cache}/keybind-palette/tldr-index-v3.tsv"

  if [[ ! -s "$index_file" || "$root" -nt "$index_file" ]]; then
    _keys_build_tldr_index "$root" "$index_file" || return 1
  fi
  command cat "$index_file"
}

_keys_tldr_preview() {
  local source_path="$1" command_name="$2" summary="$3"

  printf '%s%s%s\n' "$_KEYS_SGR_TITLE" "$command_name" "$_KEYS_SGR_RESET"
  print -r -- "$summary"
  print
  printf '%sEXAMPLES%s\n' "$_KEYS_SGR_TITLE" "$_KEYS_SGR_RESET"
  _keys_tldr_examples "$source_path" 8
}

_keys_tldr_examples() {
  local source_path="$1" limit="${2:-8}"
  local line description='' code='' shown=0

  while IFS= read -r line; do
    case "$line" in
      '- '*)
        description="${line#- }"
        description="${description%:}"
        description="${description//\`/}"
        ;;
      \`*\`)
        [[ -n "$description" ]] || continue
        code="${line#\`}"
        code="${code%\`}"
        code="${code//\{\{\[/}"
        code="${code//\]\}\}/}"
        code="${code//\{\{/}"
        code="${code//\}\}/}"
        print -r -- "$description"
        _keys_render_key "$code" shell
        print
        description=''
        (( ++shown == limit )) && break
        ;;
    esac
  done < "$source_path"
}

_keys_preview_dispatch() {
  local source="$1"
  shift
  if [[ "$source" == curated ]]; then
    _keys_preview "$@"
  else
    _keys_tldr_preview "$source" "$2" "$3"
  fi
}

_keys_open_viewer() {
  local detail_file viewer_rc nav_header search_header
  detail_file=$(command mktemp "${TMPDIR:-/tmp}/keybind-details.XXXXXX") || return 1
  _keys_preview_dispatch "$@" >| "$detail_file" || {
    command rm -f "$detail_file"
    return 1
  }

  if (( $+commands[fzf] )); then
    # A third fzf layer, not a separate viewer: reusing _KEYS_FZF_STYLE is the
    # only way the rounded border, labels, padding and palette cannot drift
    # from the category and reference menus above it.
    nav_header='j/k lines  |  u/d half  |  h/l pages  |  g/G ends  |  / search  |  q back'
    search_header='Type to filter lines  |  Esc back to results'
    command env -u NO_COLOR fzf "${_KEYS_FZF_STYLE[@]}" \
      --height=100% --layout=reverse --border=rounded --no-hscroll --no-multi \
      --border-label=' COMMAND DETAILS ' --info=inline-right \
      --prompt='search > ' --ghost='filter these lines' \
      --header="$nav_header" --no-input \
      --bind='q:abort' --bind='enter:abort' --bind='esc:abort' \
      --bind='j:down,k:up,u:half-page-up,d:half-page-down' \
      --bind='h:page-up,l:page-down,g:first,G:last' \
      --bind="/:show-input+clear-query+change-header($search_header)+unbind(q,j,k,u,d,h,l,g,G,/)" \
      < "$detail_file"
    viewer_rc=$?
    # Abort is how the reader is dismissed; it is not an error for the caller.
    (( viewer_rc == 130 || viewer_rc == 1 )) && viewer_rc=0
  else
    command less -R "$detail_file"
    viewer_rc=$?
  fi

  command rm -f "$detail_file"
  return "$viewer_rc"
}

_keys_render_key() {
  local value="$1" requested_mode="${2:-auto}"
  print -r -- "$value" | _keys_render_stream "$requested_mode"
}

_keys_render_stream() {
  local requested_mode="${1:-auto}"
  awk \
    -v requested_mode="$requested_mode" \
    -v command_color="$_KEYS_SGR_COMMAND" \
    -v argument_color="$_KEYS_SGR_ARGUMENT" \
    -v flag_color="$_KEYS_SGR_FLAG" \
    -v home_color="$_KEYS_SGR_HOME" \
    -v path_color="$_KEYS_SGR_PATH" \
    -v separator_color="$_KEYS_SGR_SEPARATOR" \
    -v reset="$_KEYS_SGR_RESET" '
    function paint(text, color) { printf "%s%s%s", color, text, reset }
    function is_command(text) {
      return text ~ /^(cd|pushd|popd|dirs|open|rg|fzf|fd|mkdir|cp|mv|trash|du|dust|ncdu|man|journalctl|less|git|sudo|kubectl|terraform|eza|yt|yt-stop|keys|ls|ll|la|lt|ltt|lttt|gs|gp|gl|k|kgp|kgpa|kdp|kl|klp|kctx|tf|tfp|tfa|fc|jobs|fg|bg|command|wait|disown|g)$/
    }
    function command_family(text) {
      if (text ~ /^(k|kgp|kgpa|kdp|kl|klp|kctx)$/) return "kubectl"
      if (text ~ /^(tf|tfp|tfa)$/) return "terraform"
      if (text ~ /^(ls|ll|la|lt|ltt|lttt)$/) return "eza"
      if (text ~ /^(gs|gp|gl)$/) return "git"
      return text
    }
    function is_value_flag(text, family) {
      if (text ~ /^(--glob|--context|--type|--exclude|--max-depth|--extension|--level|--tail|--namespace|-var|-var-file|-out|-chdir)$/) return 1
      if (family == "rg" && text ~ /^(-g|-C|-A|-B)$/) return 1
      if (family == "fd" && text ~ /^(-t|-E|-d|-e)$/) return 1
      if (family == "du" && text == "-d") return 1
      if (family == "open" && text == "-a") return 1
      if (family == "kubectl" && text ~ /^(-n|-o)$/) return 1
      return 0
    }
    function looks_like_path(text, clean) {
      clean = text
      gsub(/^"|"$/, "", clean)
      return clean == "." || clean == ".." || clean ~ /^~/ || clean ~ /^\// ||
        clean ~ /^\.\.?\// || clean ~ /\// || clean ~ /^\.[[:alnum:]_-]+$/ ||
        clean ~ /[*?]/ || clean ~ /\.[[:alnum:]_-]+$/
    }
    function render_path(text, quoted, clean, count, parts, part_index, segment) {
      quoted = text ~ /^".*"$/
      clean = text
      if (quoted) {
        paint("\"", argument_color)
        clean = substr(clean, 2, length(clean) - 2)
      }
      count = split(clean, parts, "/")
      for (part_index = 1; part_index <= count; part_index++) {
        if (part_index > 1) paint("/", separator_color)
        segment = parts[part_index]
        if (segment == "") continue
        if (segment == "~" || segment ~ /^~[0-9]*$/) paint(segment, home_color)
        else if (segment == "." || segment == "..") paint(segment, argument_color)
        else paint(segment, path_color)
      }
      if (quoted) paint("\"", argument_color)
    }
    function render_flag(text, equals_at, flag_name, flag_value) {
      equals_at = index(text, "=")
      if (equals_at > 1) {
        flag_name = substr(text, 1, equals_at - 1)
        flag_value = substr(text, equals_at + 1)
        paint(flag_name, flag_color)
        paint("=", separator_color)
        paint(flag_value, argument_color)
        expects_value = 0
      } else {
        paint(text, flag_color)
        expects_value = is_value_flag(text, current_family)
      }
    }
    function render_key_group(text, count, parts, part_index) {
      count = split(text, parts, "/")
      for (part_index = 1; part_index <= count; part_index++) {
        if (part_index > 1) paint("/", separator_color)
        if (parts[part_index] != "") paint(parts[part_index], flag_color)
      }
    }
    function render_flag_alternatives(text, count, parts, part_index) {
      count = split(text, parts, "|")
      for (part_index = 1; part_index <= count; part_index++) {
        if (part_index > 1) paint("|", separator_color)
        if (parts[part_index] ~ /^-/) paint(parts[part_index], flag_color)
        else paint(parts[part_index], argument_color)
      }
    }
    function render_shell_token(text) {
      if (text == "") return
      if (expects_value) {
        paint(text, argument_color)
        expects_value = 0
        command_expected = 0
      } else if (text == "|" || text == "&" || text == "/" || text == "→") {
        paint(text, separator_color)
        if (text == "|" || text == "&") command_expected = 1
      } else if (is_command(text)) {
        paint(text, command_color)
        current_family = command_family(text)
        command_expected = (text == "sudo" || text == "command")
      } else if (text ~ /^(!\!|!\$)$/) {
        paint(text, home_color)
        command_expected = 0
      } else if (command_expected && text !~ /^-/ && !looks_like_path(text)) {
        paint(text, command_color)
        current_family = text
        command_expected = 0
      } else if (text ~ /^(Ctrl|Alt|Cmd|Shift)-/) {
        render_key_group(text)
        command_expected = 0
      } else if (text ~ /^-[^ ]*\|-/) {
        render_flag_alternatives(text)
        command_expected = 0
      } else if (text ~ /^--?[[:alnum:].][-[:alnum:].]*(=.*)?$/) {
        render_flag(text)
      } else if (looks_like_path(text)) {
        render_path(text)
        command_expected = 0
      } else {
        paint(text, argument_color)
        command_expected = 0
      }
    }
    function render_key_token(text) {
      if (text == "") return
      if (after_prefix) {
        if (text ~ /^[\[\];,.|&-]$/) paint(text, separator_color)
        else render_key_group(text)
        after_prefix = 0
      } else if (text == "Prefix") {
        paint(text, argument_color)
        after_prefix = 1
      } else if (text == "/" || text == "|" || text == "&" || text == "→") {
        paint(text, separator_color)
      } else if (text ~ /^[?\/].+/) {
        paint(substr(text, 1, 1), separator_color)
        paint(substr(text, 2), argument_color)
      } else if (text ~ /^(Ctrl|Alt|Cmd|Shift)-/ || text ~ /^(Left|Right)-/ || text ~ /^<.*>$/) {
        render_key_group(text)
      } else if (text ~ /^.\/./) {
        render_key_group(text)
      } else if (text ~ /^(Tab|Enter|Escape|Space|Home|End|Up|Down|Left|Right)$/ || text ~ /^[0-9]+…[0-9]+$/ || length(text) == 1) {
        paint(text, flag_color)
      } else if (text ~ /^(!\!|!\$)$/) {
        paint(text, home_color)
      } else {
        printf "%s", text
      }
    }
    {
      shell_mode = requested_mode == "shell"
      if (requested_mode == "auto") {
        for (scan = 1; scan <= NF; scan++) {
          probe = $scan
          gsub(/^["(]+|["),;]+$/, "", probe)
          if (is_command(probe)) shell_mode = 1
        }
      }

      command_expected = 1
      current_family = ""
      expects_value = 0
      after_prefix = 0
      for (field = 1; field <= NF; field++) {
        token = $field
        if (field > 1) printf " "

        suffix = ""
        if (token ~ /[;,]$/) {
          suffix = substr(token, length(token), 1)
          token = substr(token, 1, length(token) - 1)
        }

        if (shell_mode) render_shell_token(token)
        else render_key_token(token)

        if (suffix != "") {
          paint(suffix, separator_color)
          if (shell_mode && suffix == ";") command_expected = 1
        }
      }
      printf "%s\n", reset
    }
  '
}

_keys_preview() {
  local category="$1" key="$2" purpose="$3" example="$4" context="$5"
  local family="${category%% · *}" related_category related_key related_purpose
  local related_example related_context shown=0 key_command guide_command
  local tldr_record tldr_source tldr_summary

  key_command="${key%%[[:space:]]*}"
  guide_command="$key_command"
  if [[ "$category" == 'Your commands' ]]; then
    case "$key_command" in
      k|kgp|kgpa|kdp|kl|klp|kctx) guide_command=kubectl ;;
      tf|tfp|tfa) guide_command=terraform ;;
      ls|ll|la|lt|ltt|lttt) guide_command=eza ;;
      gs|gp|gl) guide_command=git ;;
    esac
  fi

  if [[ "$guide_command" != *[^[:alnum:]_.+-]* ]]; then
    tldr_record=$(_keys_tldr_index | awk -F '\t' -v command="$guide_command" '
      $2 == command { print $6 "\t" $3; exit }
    ')
    if [[ -n "$tldr_record" ]]; then
      tldr_source="${tldr_record%%$'\t'*}"
      tldr_summary="${tldr_record#*$'\t'}"
    fi
  fi

  printf '%s%s%s\n' "$_KEYS_SGR_TITLE" "$category" "$_KEYS_SGR_RESET"
  printf '%s%s%s\n' "$_KEYS_SGR_TITLE" 'KEY / COMMAND' "$_KEYS_SGR_RESET"
  _keys_render_key "$key"
  print
  printf '%s%s%s\n' "$_KEYS_SGR_TITLE" 'WHAT IT DOES' "$_KEYS_SGR_RESET"
  print -r -- "$purpose"
  print
  printf '%s%s%s\n' "$_KEYS_SGR_TITLE" 'EXAMPLE' "$_KEYS_SGR_RESET"
  _keys_render_example "$example"
  print
  printf '%s%s%s\n' "$_KEYS_SGR_TITLE" 'CONTEXT / CAVEATS' "$_KEYS_SGR_RESET"
  print -r -- "$context"
  print

  if [[ -r "$tldr_source" ]]; then
    printf '%s%s%s\n' "$_KEYS_SGR_TITLE" 'COMMAND GUIDE / FLAGS' "$_KEYS_SGR_RESET"
    print -r -- "$tldr_summary"
    print
    _keys_tldr_examples "$tldr_source" 8
  fi

  printf '%s%s%s\n' "$_KEYS_SGR_TITLE" 'RELATED / SAME AREA' "$_KEYS_SGR_RESET"
  while IFS=$'\t' read -r related_category related_key related_purpose related_example related_context; do
    printf '  '
    _keys_render_key "$related_key"
    printf '    %s\n' "$related_purpose"
    (( ++shown == 6 )) && break
  done < <(_keys_data | awk -F '\t' \
    -v category="$category" -v family="$family" -v selected="$key" \
    -v command="$key_command" -v guide_command="$guide_command" '
    $2 != selected {
      base = $2
      sub(/[[:space:]].*/, "", base)
      priority = 0
      if ((command != "" && base == command) ||
          (guide_command != command && base == guide_command)) priority = 1
      else if ($1 == category) priority = 2
      else if (index($1, family " ·") == 1) priority = 3
      if (priority) rows[priority, ++counts[priority]] = $0
    }
    END {
      for (priority = 1; priority <= 3; priority++)
        for (i = 1; i <= counts[priority]; i++)
          print rows[priority, i]
    }
  ')
}

_keys_render_example() {
  local example="$1"

  if [[ "$example" == *$'\n'* ]] && (( $+commands[bat] )); then
    print -r -- "$example" | command bat --language=zsh --theme=ansi \
      --style=plain --paging=never --color=always
    return
  fi

  case "$example" in
    Press*|Hold*|Tap*|Type*|In\ *|Drag*|Ctrl-*|Cmd-*|Alt-*|Escape*|Space*|Up*|Down*|Left*|Right*|v,*)
      _keys_render_key "$example" key
      ;;
    *)
      _keys_render_key "$example" shell
      ;;
  esac
}

_keys_category_preview() {
  local category="$1" title="$_KEYS_SGR_TITLE"
  local dim=$'\e[2m' reset="$_KEYS_SGR_RESET"
  local item_category item_key item_purpose item_example item_context total tldr_total

  if [[ "$category" == all ]]; then
    tldr_total=$(_keys_tldr_index | wc -l | tr -d ' ')
    printf '%sSEARCH EVERYTHING%s\n' "$title" "$reset"
    print
    _keys_data | awk -F '\t' -v c="$title" -v d="$dim" -v r="$reset" '
      !seen[$1]++ { order[++count] = $1 }
      { totals[$1]++ }
      END {
        for (i = 1; i <= count; i++)
          printf "  %s%-28s%s %s%3d entries%s\n", c, order[i], r, d, totals[order[i]], r
      }
    '
    printf '  %s%-28s%s %s%3d commands%s\n' \
      "$title" 'tldr · all platforms' "$reset" "$dim" "$tldr_total" "$reset"
    return
  fi

  case "$category" in
    scope-category)
      printf '%sSEARCH BY CATEGORY%s\n\n' "$title" "$reset"
      print 'Match section names such as filesystem, tmux, shell, Ghostty, or Vim-style.'
      print 'Enter opens the selected reference; its details remain hidden until then.'
      return
      ;;
    scope-command)
      printf '%sSEARCH BY COMMAND%s\n\n' "$title" "$reset"
      print 'Match command names, descriptions, examples, flags, and related terms.'
      print 'Includes curated local commands plus every installed tldr page.'
      return
      ;;
    scope-key)
      printf '%sSEARCH BY KEY%s\n\n' "$title" "$reset"
      print 'Match terminal, Zsh, tmux, Ghostty, Karabiner, and viewer key bindings.'
      print 'Neovim mappings are intentionally excluded.'
      return
      ;;
    scope-warning)
      printf '%sSEARCH WARNINGS / CAVEATS%s\n\n' "$title" "$reset"
      print 'Search the context and warning field without unrelated command text.'
      print 'Useful for collisions, destructive flags, scope, and mode-specific behavior.'
      return
      ;;
  esac

  if [[ "$category" == tldr ]]; then
    printf '%sALL TLDR COMMANDS%s\n\n' "$title" "$reset"
    _keys_tldr_index | awk -F '\t' -v c="$title" -v d="$dim" -v r="$reset" '
      {
        platform = $1
        sub(/^tldr · /, "", platform)
        totals[platform]++
      }
      END {
        for (platform in totals)
          printf "  %s%-18s%s %s%4d commands%s\n", c, platform, r, d, totals[platform], r
      }
    ' | command sort
    return
  fi

  total=$(_keys_data | awk -F '\t' -v category="$category" '$1 == category { count++ } END { print count + 0 }')
  printf '%s%s%s\n%s%d entries%s\n\n' "$title" "$category" "$reset" "$dim" "$total" "$reset"
  while IFS=$'\t' read -r item_category item_key item_purpose item_example item_context; do
    [[ "$item_category" == "$category" ]] || continue
    _keys_render_key "$item_key"
    printf '  %s\n' "$item_purpose"
    printf '  %se.g.%s ' "$title" "$reset"
    _keys_render_example "$item_example"
    printf '  %s\n\n' "$item_context"
  done < <(_keys_data)
}

_keys_plain() {
  local category_query="$1"
  _keys_data | awk -F '\t' -v query="${category_query:l}" '
    {
      matches = 1
      count = split(query, terms, /[[:space:]]+/)
      for (i = 1; i <= count; i++)
        if (terms[i] != "" && !index(tolower($1), terms[i])) matches = 0
    }
    matches {
      if ($1 != category) {
        if (category != "") print ""
        category = $1
        print "[" category "]"
      }
      printf "  %-26s %s\n", $2, $3
      printf "    e.g. %s  |  %s\n", $4, $5
      found = 1
    }
    END { if (!found) exit 1 }
  '
}

_keys_terminal_columns() {
  local columns
  columns=$(command tput cols 2>/dev/null)
  [[ "$columns" == <-> ]] || columns=${COLUMNS:-120}
  print -r -- "$columns"
}

_keys_category_items() {
  local total category_total tldr_total combined_total command_total key_total title="$_KEYS_SGR_TITLE"
  local dim=$'\e[2m' reset="$_KEYS_SGR_RESET"
  total=$(_keys_data | wc -l | tr -d ' ')
  category_total=$(_keys_data | awk -F '\t' '!seen[$1]++ { count++ } END { print count + 0 }')
  tldr_total=$(_keys_tldr_index | wc -l | tr -d ' ')
  (( combined_total = total + tldr_total ))
  command_total=$(_keys_data | awk -F '\t' '$1 ~ /^(Filesystem|Flags|Theme|Your commands)/ { count++ } END { print count + 0 }')
  key_total=$(_keys_data | awk -F '\t' '$1 !~ /^(Filesystem|Flags|Theme|Your commands)/ { count++ } END { print count + 0 }')

  printf '%s%-30s%s %s%3d entries%s\tall\n' \
    "$title" 'Search everything' "$reset" "$dim" "$combined_total" "$reset"
  printf '%s%-30s%s %s%3d categories%s\tscope-category\n' \
    "$title" 'Search by category' "$reset" "$dim" "$category_total" "$reset"
  printf '%s%-30s%s %s%3d commands%s\tscope-command\n' \
    "$title" 'Search by command' "$reset" "$dim" "$(( command_total + tldr_total ))" "$reset"
  printf '%s%-30s%s %s%3d bindings%s\tscope-key\n' \
    "$title" 'Search by key' "$reset" "$dim" "$key_total" "$reset"
  printf '%s%-30s%s %s%3d notes%s\tscope-warning\n' \
    "$title" 'Search warnings / caveats' "$reset" "$dim" "$total" "$reset"
  printf '%s%-30s%s %s%3d commands%s\ttldr\n' \
    "$title" 'All tldr commands' "$reset" "$dim" "$tldr_total" "$reset"
  _keys_data | awk -F '\t' -v c="$title" -v d="$dim" -v r="$reset" '
    !seen[$1]++ { order[++count] = $1 }
    { totals[$1]++ }
    END {
      for (i = 1; i <= count; i++)
        printf "%s%-30s%s %s%3d entries%s\t%s\n", c, order[i], r, d, totals[order[i]], r, order[i]
    }
  '
}

_keys_choose_category() {
  local previous="$1" terminal_columns category_preview_window position=1 result rc
  terminal_columns=$(_keys_terminal_columns)
  if [[ -n "$previous" ]]; then
    position=$(_keys_category_items | awk -F '\t' -v category="$previous" '$2 == category { print NR; exit }')
    [[ "$position" == <-> ]] || position=1
  fi
  if (( terminal_columns >= 110 )); then
    category_preview_window='right,58%,wrap,border-left'
  else
    category_preview_window='down,55%,wrap,border-top'
  fi

  result=$(_keys_category_items | command env -u NO_COLOR fzf "${_KEYS_FZF_STYLE[@]}" \
    --delimiter=$'\t' --with-nth=1 --nth=1 \
    --height=100% --layout=reverse --border=rounded --sync \
    --border-label=' KEYBIND PALETTE ' --info=inline-right \
    --prompt='category > ' --ghost='type to filter sections' \
    --header='Enter open  |  Esc/Ctrl-c exit' \
    --preview="zsh -f -c 'source \"$_KEYS_PALETTE_FILE\"; _keys_category_preview \"\$1\"' _ {2}" \
    --preview-window="$category_preview_window" --preview-label=' section overview ' \
    --bind="start:pos($position)")
  rc=$?
  (( rc == 0 )) || return "$rc"
  print -r -- "${result##*$'\t'}"
}

_keys_select_data() {
  local category="$1"

  if [[ "$category" == (all|scope-category|scope-warning) ]]; then
    _keys_data
    return
  fi
  if [[ "$category" == scope-command ]]; then
    _keys_data | awk -F '\t' '$1 ~ /^(Filesystem|Flags|Theme|Your commands)/'
    return
  fi
  if [[ "$category" == scope-key ]]; then
    _keys_data | awk -F '\t' '$1 !~ /^(Filesystem|Flags|Theme|Your commands)/'
    return
  fi
  if [[ "$category" == tldr ]]; then
    _keys_tldr_index
    return
  fi
  _keys_data | awk -F '\t' -v query="${category:l}" '
    {
      matches = 1
      count = split(query, terms, /[[:space:]]+/)
      for (i = 1; i <= count; i++)
        if (terms[i] != "" && !index(tolower($1), terms[i])) matches = 0
      if (matches) print
    }
  '
}

_keys_detail_items() {
  local terminal_columns="$1" reset="$_KEYS_SGR_RESET"
  local category key purpose example context source rendered_key padding records
  local hidden_padding display_width
  local render_fd
  local category_width=18 key_width=18

  if (( terminal_columns >= 120 )); then
    category_width=23
    key_width=22
  fi

  records=$(command cat)
  [[ -n "$records" ]] || return 0
  exec {render_fd}< <(print -r -- "$records" | command cut -f2 | _keys_render_stream auto)

  while IFS=$'\t' read -r category key purpose example context source; do
    IFS= read -r rendered_key <&$render_fd
    if [[ -n "$source" ]]; then
      rendered_key="${_KEYS_SGR_COMMAND}${key}${reset}"
    else
      source=curated
    fi
    (( padding = key_width - ${#key} ))
    (( padding < 0 )) && padding=0
    (( display_width = category_width + key_width + ${#purpose} + 4 ))
    # fzf must retain searchable metadata in its transformed row. Keep it far
    # beyond any practical viewport so source paths can never leak into the UI.
    (( hidden_padding = 1024 - display_width ))
    (( hidden_padding < 256 )) && hidden_padding=256
    printf '%s%-*s%s  %s%*s  %s%*s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$_KEYS_SGR_TITLE" "$category_width" "$category" "$reset" \
      "$rendered_key" "$padding" '' "$purpose" "$hidden_padding" '' \
      "$source" "$category" "$key" "$purpose" "$example" "$context"
  done <<< "$records"
  exec {render_fd}<&-
}

_keys_tldr_items() {
  local terminal_columns="$1" category_width=18 key_width=18
  if (( terminal_columns >= 120 )); then
    category_width=23
    key_width=22
  fi

  awk -F '\t' \
    -v category_width="$category_width" -v key_width="$key_width" -v terminal_columns="$terminal_columns" \
    -v title="$_KEYS_SGR_TITLE" -v command_color="$_KEYS_SGR_COMMAND" \
    -v reset="$_KEYS_SGR_RESET" '
    {
      padding = key_width - length($2)
      if (padding < 0) padding = 0
      display_width = category_width + key_width + length($3) + 4
      hidden_padding = 1024 - display_width
      if (hidden_padding < 256) hidden_padding = 256
      printf "%s%-*s%s  %s%s%s%*s  %s%*s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        title, category_width, $1, reset,
        command_color, $2, reset, padding, "", $3, hidden_padding, "",
        $6, $1, $2, $3, $4, $5
    }
  '
}

_keys_browse_items() {
  local category="$1" terminal_columns="$2"
  case "$category" in
    all|scope-command)
      _keys_select_data "$category" | awk -F '\t' '
        { rows[++row_count] = $0; preferred[row_count] = $1 == "Your commands" }
        END {
          for (i = 1; i <= row_count; i++) if (preferred[i]) print rows[i]
          for (i = 1; i <= row_count; i++) if (!preferred[i]) print rows[i]
        }
      ' | _keys_detail_items "$terminal_columns"
      _keys_tldr_index | _keys_tldr_items "$terminal_columns"
      ;;
    tldr)
      _keys_tldr_index | _keys_tldr_items "$terminal_columns"
      ;;
    *)
      _keys_select_data "$category" | _keys_detail_items "$terminal_columns"
      ;;
  esac
}

_keys_browse() {
  local category="$1" terminal_columns result rc
  local query remainder action search_fields list_label ghost
  local -a matching_style
  local search_header='Tab navigate results  |  Enter details  |  Esc categories'
  local results_header='j/k rows  |  u/d half  |  h/l pages  |  g/G ends  |  Enter details  |  / search'
  local preview_window='right,55%,wrap,border-left,hidden'

  terminal_columns=$(_keys_terminal_columns)

  case "$category" in
    scope-category)
      search_fields='3'
      list_label='CATEGORY SEARCH'
      ghost='filesystem, tmux, shell, Ghostty...'
      ;;
    scope-command)
      search_fields='4,5,6,7'
      list_label='COMMAND SEARCH'
      ghost='command name or what it should do'
      matching_style=(--exact)
      ;;
    scope-key)
      search_fields='4,5'
      list_label='KEY SEARCH'
      ghost='Ctrl-r, Prefix z, copy mode...'
      ;;
    scope-warning)
      search_fields='7'
      list_label='WARNING / CAVEAT SEARCH'
      ghost='collision, destructive, outside tmux...'
      ;;
    tldr)
      search_fields='4,5,6,7'
      list_label='ALL TLDR COMMANDS'
      ghost='command name or what it should do'
      matching_style=(--exact)
      ;;
    *)
      search_fields='1,6,7'
      list_label='EVERYTHING'
      ghost='key, command, example, or warning'
      ;;
  esac

  result=$(_keys_browse_items "$category" "$terminal_columns" | \
    command env -u NO_COLOR fzf "${_KEYS_FZF_STYLE[@]}" "${matching_style[@]}" \
      --delimiter=$'\t' --with-nth=1.. --nth="$search_fields" \
      --height=100% --layout=reverse --border=rounded --no-hscroll \
      --border-label=' KEYBIND REFERENCE ' --info=inline-right \
      --prompt='search > ' --ghost="$ghost" \
      --query="${_KEYS_QUERIES[$category]-}" --print-query \
      --header="$search_header" --list-label=" $list_label " --preview-label=' COMMAND DETAILS ' \
      --preview="zsh -f -c 'source \"$_KEYS_PALETTE_FILE\"; _keys_preview_dispatch \"\$@\"' _ {2} {3} {4} {5} {6} {7}" \
      --preview-window="$preview_window" --expect=esc,alt-left \
      --bind="enter:execute(zsh -f -c 'source \"$_KEYS_PALETTE_FILE\"; _keys_open_viewer \"\$@\"' _ {2} {3} {4} {5} {6} {7})" \
      --bind="double-click:execute(zsh -f -c 'source \"$_KEYS_PALETTE_FILE\"; _keys_open_viewer \"\$@\"' _ {2} {3} {4} {5} {6} {7})" \
      --bind="tab:show-preview+hide-input+change-header($results_header)+rebind(j,k,u,d,h,l,g,G,/)+unbind(tab)" \
      --bind="/:hide-preview+show-input+change-header($search_header)+unbind(j,k,u,d,h,l,g,G,/)+rebind(tab)" \
      --bind='j:down,k:up,u:half-page-up,d:half-page-down' \
      --bind='h:page-up,l:page-down,g:first,G:last' \
      --bind='start:unbind(j,k,u,d,h,l,g,G,/)')
  rc=$?
  (( rc == 0 )) || return "$rc"

  query=${result%%$'\n'*}
  remainder=${result#*$'\n'}
  action=${remainder%%$'\n'*}
  _KEYS_QUERIES[$category]="$query"

  # Expected keys always return to the category menu; Ctrl-c exits the palette.
  [[ "$action" == (esc|alt-left) ]]
}

_keys_category_exists() {
  local query="${1:l}"
  [[ "$query" == (all|tldr|scope-category|scope-command|scope-key|scope-warning) ]] && return 0
  _keys_data | awk -F '\t' -v query="$query" '
    function term_matches(category, term, count, words, word_index) {
      count = split(tolower(category), words, /[^[:alnum:]]+/)
      for (word_index = 1; word_index <= count; word_index++)
        if (index(words[word_index], term) == 1) return 1
      return 0
    }
    {
      matches = 1
      count = split(query, terms, /[[:space:]]+/)
      for (i = 1; i <= count; i++)
        if (terms[i] != "" && !term_matches($1, terms[i])) matches = 0
      if (matches) {
        found = 1
        exit
      }
    }
    END { exit !found }
  '
}

keys() {
  local category='' category_query='' rc

  if [[ "$1" == --help ]]; then
    print 'usage: keys [CATEGORY | SEARCH TERMS]'
    print '       keys --plain [CATEGORY]'
    print '       keys tldr'
    return
  fi
  if [[ "$1" == --plain ]]; then
    shift
    _keys_plain "$*" || {
      print -u2 "No keybind category matches: $*"
      return 1
    }
    return
  fi
  if ! (( $+commands[fzf] )); then
    print -u2 'fzf is not installed; showing the plain cheat sheet.'
    _keys_plain "$*"
    return
  fi

  _KEYS_QUERIES=()
  category_query="$*"
  if [[ -n "$category_query" ]]; then
    if _keys_category_exists "$category_query"; then
      category="${category_query:l}"
    else
      category=all
      _KEYS_QUERIES[all]="$category_query"
    fi
    _keys_browse "$category"
    rc=$?
    (( rc == 2 )) && return 1
    (( rc == 130 )) && return 130
  else
    category=all
    _keys_browse "$category"
    rc=$?
    (( rc == 130 )) && return 130
  fi

  while true; do
    category=$(_keys_choose_category "$category") || return 0
    _keys_browse "$category"
    rc=$?
    (( rc == 130 )) && return 130
  done
}

# Short, memorable command for the palette.
alias kk='keys'

# Resolve previews back to this file even when it was sourced from another loader.
typeset -g _KEYS_PALETTE_FILE="${${(%):-%x}:A}"
typeset -gA _KEYS_QUERIES
typeset -ga _KEYS_FZF_STYLE=(
  --ansi --highlight-line --cycle --tiebreak=index --pointer='▶' --marker='✓'
  --color='fg:-1,bg:-1,hl:11,fg+:15,bg+:8,hl+:11,prompt:14,pointer:11,marker:10,spinner:14,header:-1,info:8,border:12,label:14,query:15,gutter:8,separator:8,scrollbar:8'
)

# Remove the retired shell chord if this file is re-sourced in a shell that
# loaded an earlier palette version. Do not disturb a user-defined binding.
if [[ -o interactive ]] && [[ "$(bindkey '^X?' 2>/dev/null)" == *'_keys_widget' ]]; then
  bindkey -r '^X?'
  unfunction _keys_widget 2>/dev/null
fi
