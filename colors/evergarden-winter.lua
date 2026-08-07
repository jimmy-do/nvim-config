-- evergarden-winter — shadows comfysage/evergarden's own colors/evergarden-winter.lua
-- (the config dir wins the runtimepath). Upstream's three dark seasons are the
-- same theme with a different background, and the background is pinned by
-- bg_base anyway; the real palette lives in lua/config/evergarden_seasons.lua.
--
-- Stock `evergarden` is untouched and still loads upstream.
local ok, seasons = pcall(require, "config.evergarden_seasons")
if not (ok and seasons.load("winter")) then
  pcall(vim.cmd.colorscheme, "evergarden")
end
