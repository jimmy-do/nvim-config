-- One answer to "should the yaml painters run on this buffer".
--
-- ---------------------------------------------------------------------------
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------
-- Every yaml painter used to test the filetype itself, by exact equality:
--
--   yaml-key-depth.lua:  if vim.bo[buf].filetype ~= "yaml" then return end
--   yaml-expr.lua:       if ft ~= "yaml" and ft ~= "helm" then return end
--
-- That is fine while every yaml buffer is plain `yaml`, and today it is. But
-- Nvim supports COMPOUND filetypes (`yaml.github`, `yaml.docker-compose`), and
-- lua/config/filetypes.lua used to set exactly those for .github/workflows and
-- compose files. It was never `require`d, so it never took effect -- the only
-- reason the equality checks held.
--
-- Wire that file up (or add any dotted yaml filetype from a plugin) and the
-- checks above start returning false, while the treesitter LANGUAGE stays
-- `yaml` so after/queries/yaml/*.scm keeps applying. The result is the worst
-- possible outcome: a partial system. Workflows would keep their value-shape
-- colours and silently lose key depth and ${{ }} tokenizing, so `.github/*.yml`
-- would render differently from every other yaml file in the repo for reasons
-- nothing in the code states.
--
-- .yml vs .yaml is NOT the axis, and never was: Nvim maps both extensions to
-- filetype `yaml`, so the queries have always covered both. The axis is the
-- compound filetype. Testing the ROOT closes it permanently.
--
-- Anything that paints yaml must ask this module. Do not re-derive it locally.

local M = {}

-- Filetype roots that carry yaml syntax. `helm` is a gotmpl fork whose
-- non-template body is yaml, so the painters are wanted there too.
local ROOTS = {
  yaml = true,
  helm = true,
}

--- Root of a (possibly compound) filetype: "yaml.github" -> "yaml".
--- @param ft string|nil
--- @return string
function M.root(ft)
  return vim.split(ft or "", ".", { plain = true })[1] or ""
end

--- True when `buf` (default: current) should get the yaml painters.
--- @param buf integer|nil
--- @return boolean
function M.is_yaml(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  return ROOTS[M.root(vim.bo[buf].filetype)] == true
end

return M
