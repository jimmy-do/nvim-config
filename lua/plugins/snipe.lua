-- Buffer switching by stable single-character tag.
--
-- The problem this actually solves: buffers are an UNORDERED list. `:bnext`
-- walks them in the order you happened to open files, so <S-l> is a slot
-- machine once you're a dozen files deep. Bufferline shows the list but you
-- still have to read it every time, because a buffer's position moves.
--
-- Snipe pops a menu where every buffer carries a letter, and `persist_tags`
-- pins bufnr -> tag so a given file keeps the SAME letter for the whole
-- session. That's the harpoon idea (fixed slots you build muscle memory
-- against) without hand-marking anything, and unlike a winbar or a tabline it
-- adds ZERO pixels until you press the key.
--
-- gb was verified free before binding (nothing in LazyVim or config/keymaps.lua
-- claims it). <leader>, stays LazyVim's fuzzy buffer picker -- untouched.
return {
  {
    "leath-dub/snipe.nvim",
    keys = {
      {
        "gb",
        function()
          require("snipe").open_buffer_menu()
        end,
        desc = "Snipe buffers",
      },
    },
    opts = {
      ui = {
        -- Menu opens at the cursor rather than a screen corner, so your eyes
        -- don't travel. Nothing is drawn until gb.
        position = "cursor",
        open_win_override = { border = "none" },
        -- Filename first, path dimmed after it -- the discriminating token is
        -- the thing you read, same reason the tmux pane border truncates to
        -- ~/…/leaf instead of printing the whole path.
        text_align = "file-first",
      },
      hints = {
        -- Home-row-ish set, no letters that collide with the nav keys below.
        dictionary = "sadflewcmpghio",
      },
      navigate = {
        cancel_snipe = "<esc>",
      },
      -- THE point of this plugin for this config: a buffer keeps its letter.
      -- Without it the tags reshuffle as the buffer list changes and you're
      -- back to reading the menu every time.
      sort = "default",
      persist_tags = true,
    },
  },
}
