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

local function instant_page_scroll(keys)
  return function()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    local previous = vim.g.snacks_scroll
    vim.g.snacks_scroll = false
    vim.api.nvim_feedkeys(count .. termcode(keys), "nx", false)
    vim.defer_fn(function()
      vim.g.snacks_scroll = previous
    end, 40)
  end
end

-- Smooth (animated) page scroll: feed <C-u>/<C-d> with snacks scroll left ON so
-- the resulting WinScrolled is animated. Opposite of instant_page_scroll above.
local function smooth_page_scroll(keys)
  return function()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    vim.api.nvim_feedkeys(count .. termcode(keys), "nx", false)
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.scroll = vim.tbl_deep_extend("force", opts.scroll or {}, {
        enabled = true,
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
      vim.keymap.set({ "n", "x" }, "u", smooth_page_scroll("<C-u>"), { desc = "Page up (smooth)" })
      vim.keymap.set({ "n", "x" }, "d", smooth_page_scroll("<C-d>"), { desc = "Page down (smooth)" })
    end,
  },
}
