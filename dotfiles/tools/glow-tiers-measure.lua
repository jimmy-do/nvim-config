-- headless: for every colorscheme, resolve the yaml VALUE colours and score glow
local out = {}

local function hl(name)
  local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and h and h.fg then
    return h.fg
  end
  return nil
end

-- Value tokens only. Field/property/label groups are deliberately absent.
local value_groups = {
  "@string.yaml",
  "@string",
  "String",
  "@number.yaml",
  "@number",
  "Number",
  "@boolean.yaml",
  "@boolean",
  "Boolean",
  "@type.yaml",
  "@constant.macro.yaml",
  "@string.special.image.yaml",
  "@string.special.version.yaml",
  "@string.special.url.yaml",
}

local colors = vim.fn.getcompletion("", "color")
local lazy = package.loaded["lazy.core.util"]
if lazy and lazy.get_unloaded_rtp then
  local paths = lazy.get_unloaded_rtp("")
  for _, f in ipairs(vim.fn.globpath(table.concat(paths, ","), "colors/*", true, true)) do
    table.insert(colors, vim.fn.fnamemodify(f, ":t:r"))
  end
end
table.sort(colors)

local seen = {}
for _, name in ipairs(colors) do
  if not seen[name] then
    seen[name] = true
    local ok = pcall(vim.cmd.colorscheme, name)
    if ok then
      local vals = {}
      for _, g in ipairs(value_groups) do
        local c = hl(g)
        if c then
          vals[g] = string.format("#%06x", c)
        end
      end
      table.insert(out, { name = name, bg = vim.o.background, vals = vals })
    end
  end
end

local f = io.open(vim.env.GLOW_OUT, "w")
f:write(vim.json.encode(out))
f:close()
vim.cmd("qa!")
