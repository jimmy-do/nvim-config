# prefix w — the pane switcher

Every pane on the server, one per row. Type to filter (session, window and
pane names all match). `Enter` goes there — session, window and pane in one hop.

| key | does |
|-----|------|
| `Enter` | switch to that pane |
| `Ctrl-N` / `Ctrl-P` | down / up (arrows work too) |
| `?` | this help ⇄ live pane preview |
| `Esc` | close, change nothing |

# What a MARK is

A mark is **a bookmark for one pane**. tmux holds exactly **one** mark at a
time, for the whole server — not one per session, not one per window. One.

Setting a mark does nothing on its own. It does not move, lock, pin, or
protect anything. All it does is let you write the word `{marked}` in a later
command instead of naming a pane by `session:window.pane`.

That matters because of a chicken-and-egg problem: to move a pane you have to
say **which pane** and **where to**, but you can only ever be standing in one
of those two places. The mark is how you point at the *there* while you are
still *here*.

    Alt-m   set the mark on the highlighted row   (badge: 󰐁 MARK)
    Alt-M   clear it

The mark is visible outside this popup too: the marked pane's border shows a
 badge, and its window gets an `M` flag in the status bar. So you can always
see which pane is currently bookmarked.

## Worked example — move a pane into another window

You are in `devops:1`. There is a `logs` pane over in `devops:2` and you want
it *here*, split below your current pane.

    1.  prefix w                 open this chooser
    2.  filter to the logs pane, highlight it
    3.  Alt-m                    mark it — it now shows 󰐁 MARK
    4.  highlight any pane in devops:1  (the destination)
    5.  Ctrl-j                   the marked pane is pulled in below

Step 3 said *which pane*, step 5 said *where to*. That is the entire job of
the mark. `Ctrl-l` does the same but side by side instead of stacked.

## The other thing marks are for — swap

    Ctrl-s   swap the highlighted pane with the marked one

Two panes trade places, wherever they live. Same reason it needs a mark: two
targets, one cursor.

# Moving panes around

| key | does |
|-----|------|
| `Alt-m` / `Alt-M` | set / clear the mark |
| `Ctrl-j` | pull the MARKED pane into the highlighted pane's window, below it |
| `Ctrl-l` | same, but beside it |
| `Ctrl-s` | swap the highlighted pane with the marked one |
| `Ctrl-b` | break the highlighted pane out into a window of its own |

`Ctrl-b`'s opposite is `Ctrl-j` — break out, join back in.

# Housekeeping

| key | does |
|-----|------|
| `Ctrl-x` | kill the highlighted pane |
| `Ctrl-r` | rename the highlighted pane's window |
| `Ctrl-o` | rotate: reload the list |

# What happened to the old tree

`prefix w` used to be tmux's built-in `choose-tree`. Two things about it were
confusing enough to replace it:

* **`t` was tag, not pin.** Tagging only put a checkmark on rows so that `X`
  (kill all tagged) or `:` (run a command per tagged row) could act on several
  at once. It pinned nothing. This chooser has no tags — filter and act.
* **It could not move a pane.** The tree switched *to* things. Moving a pane
  needed `m` plus a `join-pane` typed somewhere else entirely. That is now
  `Alt-m` then `Ctrl-j`, both in here, without leaving.

tmux's original tree is still one key away if you want it: `prefix C-w`.
