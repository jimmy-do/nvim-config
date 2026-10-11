local function termcode(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function with_snacks_scroll_disabled(fn)
  local previous = vim.g.snacks_scroll
  vim.g.snacks_scroll = false
  local ok, err = pcall(fn)
  vim.g.snacks_scroll = previous
  if not ok then
    error(err)
  end
end

local function scroll_window(win, delta)
  if not vim.api.nvim_win_is_valid(win) or delta == 0 then
    return
  end

  with_snacks_scroll_disabled(function()
    vim.api.nvim_win_call(win, function()
      local view = vim.fn.winsaveview()
      view.topline = math.max(1, view.topline + delta)
      pcall(vim.fn.winrestview, view)
    end)
  end)
end

local wheel_state = {}

local function smooth_wheel(direction)
  return function()
    local win = vim.api.nvim_get_current_win()
    local state = wheel_state[win] or { value = 0, target = 0 }
    wheel_state[win] = state

    state.target = state.target + direction * 2

    local snacks = rawget(_G, "Snacks")
    if not (snacks and snacks.animate and snacks.animate.enabled({ buf = vim.api.nvim_get_current_buf() })) then
      local delta = state.target - state.value
      state.value, state.target = 0, 0
      scroll_window(win, delta)
      return
    end

    snacks.animate(state.value, state.target, function(value, ctx)
      local rounded = math.floor(value + 0.5)
      local delta = rounded - state.value

      if delta ~= 0 then
        scroll_window(win, delta)
        state.value = state.value + delta
      end

      if ctx.done and state.value == state.target then
        state.value = 0
        state.target = 0
      end
    end, {
      id = "trackpad-scroll-" .. win,
      buf = vim.api.nvim_get_current_buf(),
      int = true,
      easing = "outCubic",
      duration = { step = 9, total = 95 },
    })
  end
end

-- Nesting-safe. Presses can land closer together than the 40ms restore delay
-- (that is the whole point of the spam path below), so a naive save/restore would
-- have press #2 capture the ALREADY-SUPPRESSED value and then restore `false`
-- permanently -- snacks scroll silently dead for the rest of the session. The
-- depth counter means only the outermost press owns the saved value, and only the
-- last one in a burst restores it.
local suppress_depth = 0
local suppress_saved = nil

local function instant_page_scroll(keys)
  return function()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    if suppress_depth == 0 then
      suppress_saved = vim.g.snacks_scroll
    end
    suppress_depth = suppress_depth + 1
    vim.g.snacks_scroll = false
    vim.api.nvim_feedkeys(count .. termcode(keys), "nx", false)
    vim.defer_fn(function()
      suppress_depth = math.max(0, suppress_depth - 1)
      if suppress_depth == 0 then
        vim.g.snacks_scroll = suppress_saved
      end
    end, 40)
  end
end

-- Smooth (animated) page scroll: feed <C-u>/<C-d> with snacks scroll left ON so
-- the resulting WinScrolled is animated. Opposite of instant_page_scroll above.
--
-- ...EXCEPT while you are spamming the SAME direction. A snacks page glide walks
-- the cursor's SCREEN position one row at a time for the whole animation, and
-- Ghostty's cursor shaders (cursor_tail + sonic_boom) restart their trail on every
-- one of those steps -- so a held `d` leaves ~20 half-finished smears raking down
-- the column instead of one tail. Repeats in the same direction therefore go
-- INSTANT: one cursor jump, one clean trail, no restart storm.
--
-- The first press of a direction, and any reversal, still glides -- that is the
-- press you actually watch. Nothing here touches snacks' indent animation.
local repeat_window_ms = 220 -- quiet for this long => next press is a "first" press again
local last_dir, last_at = nil, 0

local function smooth_page_scroll(keys, dir)
  local instant = instant_page_scroll(keys)
  return function()
    local now = (vim.uv or vim.loop).now()
    local spamming = last_dir == dir and (now - last_at) < repeat_window_ms
    last_dir, last_at = dir, now

    if spamming then
      return instant()
    end

    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    vim.api.nvim_feedkeys(count .. termcode(keys), "nx", false)
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.scroll = vim.tbl_deep_extend("force", opts.scroll or {}, {
        -- 2026-10-11: OFF at Jimmy's request. Flip back to true to restore the
        -- glide; the animate settings below are kept for that.
        enabled = false,
        animate = {
          -- step = ms per line, total = hard cap. Higher = more glide. A ~20-line
          -- half-page (u/d) now rides ~15*20=300ms instead of the old 180 cap;
          -- an 11j is ~165ms. outCubic eases out at the end for that slide feel.
          duration = { step = 15, total = 450 },
          -- linear = constant pacing between row hops. Reads more even than an
          -- ease-out for continuous keyboard scrolling; ease-out is nicer for a
          -- single settle but makes rapid repeats feel uneven.
          easing = "linear",
        },
        -- Used when you fire u/d or j/k in quick succession. Kept snappier than a
        -- single press so rapid navigation stays responsive, but no longer an
        -- instant snap -- it still glides.
        animate_repeat = {
          delay = 50,
          duration = { step = 7, total = 140 },
          easing = "linear",
        },
      })
      return opts
    end,
    init = function()
      vim.o.mousescroll = "ver:1,hor:6"

      vim.keymap.set({ "n", "v" }, "<ScrollWheelUp>", smooth_wheel(-1), { desc = "Smooth scroll up" })
      vim.keymap.set({ "n", "v" }, "<ScrollWheelDown>", smooth_wheel(1), { desc = "Smooth scroll down" })
      -- Page scroll lives on the BARE keys, not the Ctrl ones: u / d scroll,
      -- while <C-u> / <C-d> do undo and delete. The editing half of that swap is
      -- in lua/config/keymaps.lua -- both halves must move together.
      --
      -- smooth_page_scroll feeds <C-u>/<C-d> with snacks scroll left ON, so the
      -- half-page jump animates. (Swap to instant_page_scroll here if you ever
      -- want u/d to jump instantly instead.)
      vim.keymap.set({ "n", "x" }, "u", smooth_page_scroll("<C-u>", -1), { desc = "Page up (smooth)" })
      vim.keymap.set({ "n", "x" }, "d", smooth_page_scroll("<C-d>", 1), { desc = "Page down (smooth)" })
    end,
  },
}
