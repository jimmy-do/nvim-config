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

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.scroll = vim.tbl_deep_extend("force", opts.scroll or {}, {
        animate = {
          duration = { step = 10, total = 180 },
          easing = "outCubic",
        },
        animate_repeat = {
          delay = 60,
          duration = { step = 4, total = 70 },
          easing = "outCubic",
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
      -- It has to be done HERE and not there, because the whole point of
      -- instant_page_scroll is suppressing snacks' animation for a page jump. A
      -- plain `u -> <C-u>` remap in keymaps.lua would reach the builtin and skip
      -- this wrapper, and the page jump would animate again.
      vim.keymap.set({ "n", "x" }, "u", instant_page_scroll("<C-u>"), { desc = "Page up" })
      vim.keymap.set({ "n", "x" }, "d", instant_page_scroll("<C-d>"), { desc = "Page down" })
    end,
  },
}
