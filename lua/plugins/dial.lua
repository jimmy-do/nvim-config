-- dial.nvim: <C-a>/<C-x> increment more than integers — booleans, dates,
-- semver, and the yaml-ish word cycles below.
--
-- tmux caveat: the prefix is <C-a> (bind C-a send-prefix), so a single <C-a>
-- never reaches nvim inside tmux — press <C-a><C-a> to increment. <C-x> is
-- unclaimed and works on the first press.
return {
  {
    "monaqa/dial.nvim",
    keys = {
      { "<C-a>", function() require("dial.map").manipulate("increment", "normal") end, mode = "n", desc = "Increment" },
      { "<C-x>", function() require("dial.map").manipulate("decrement", "normal") end, mode = "n", desc = "Decrement" },
      { "<C-a>", function() require("dial.map").manipulate("increment", "visual") end, mode = "x", desc = "Increment" },
      { "<C-x>", function() require("dial.map").manipulate("decrement", "visual") end, mode = "x", desc = "Decrement" },
      { "g<C-a>", function() require("dial.map").manipulate("increment", "gvisual") end, mode = "x", desc = "Increment sequence" },
      { "g<C-x>", function() require("dial.map").manipulate("decrement", "gvisual") end, mode = "x", desc = "Decrement sequence" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal_int, -- 0, 42, -3 (negatives included)
          augend.integer.alias.hex, -- 0x1f
          augend.date.alias["%Y-%m-%d"], -- 2026-07-29, component-aware
          augend.semver.alias.semver, -- 1.2.3, bumps the component under cursor
          augend.constant.alias.bool, -- true ⇄ false
          augend.constant.new({ elements = { "True", "False" } }), -- python/ansible
          augend.constant.new({ elements = { "yes", "no" } }), -- yaml 1.1 booleans
          augend.constant.new({ elements = { "on", "off" } }),
          augend.constant.new({ elements = { "enabled", "disabled" } }),
          augend.constant.new({ elements = { "&&", "||" }, word = false }),
        },
      })
    end,
  },
}
