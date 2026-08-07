-- ${{ ... }} expression highlighting for GitHub Actions / Helm-style yaml.
--
-- ---------------------------------------------------------------------------
-- WHY THIS IS NOT A TREESITTER QUERY
-- ---------------------------------------------------------------------------
-- `${{ inputs.action }}` is, to the yaml grammar, one plain_scalar. There is no
-- parser for GitHub Actions expression syntax, so a query can capture the whole
-- scalar and nothing finer -- which is exactly the flat single colour this file
-- exists to fix. after/queries/yaml/highlights.scm can say "this value is an
-- expression"; it cannot say "this part is the context and that part is the
-- property".
--
-- WHY NOT matchadd() EITHER
-- The rest of theme.lua uses matchadd overlays, and the obvious move was to add
-- a few more. It does not work here. A matchadd pattern that requires the `${{`
-- prefix (to avoid recolouring ordinary yaml) consumes it, so after the first
-- token the engine looks for another `${{` and never finds one --
-- `github.event.pull_request.number` gets its first dot coloured and the rest
-- left flat. Dropping the prefix instead recolours every period in the file.
--
-- So: a real tokenizer over the expression interior, painted with extmarks.
-- Extmarks also give us a priority above treesitter (which paints the whole
-- scalar at 100) without fighting the existing overlay priorities.
--
-- ---------------------------------------------------------------------------
-- THE COLOUR MODEL
-- ---------------------------------------------------------------------------
-- Taken from how every other ecosystem themes interpolation -- JS template
-- literals `${expr}`, shell `$VAR`, Ruby `#{}`, Python f-strings. The shared
-- convention is:
--
--   1. The SIGIL gets its own class, distinct from ordinary brackets. It is the
--      marker that you have left string-land and entered code, and it is the
--      thing you scan for. This is why `$` is not the same colour as `{{`.
--   2. The NAMESPACE (github, env, secrets, inputs, vars, matrix...) is a
--      builtin -- a fixed vocabulary the platform defines.
--   3. The MEMBER after the dot is a property access, and is coloured like
--      other field/property reads.
--   4. Calls, operators and string literals keep their ordinary code classes,
--      so `success()` looks like a function and `'plan'` looks like a string.
--
-- Concretely, `${{ vars.AWS_DEPLOY_ROLE_ARN }}` goes from one flat colour to:
--   $   sigil        {{ }}  brace        vars  context
--   .   dot          AWS_DEPLOY_ROLE_ARN  property
--
-- Colours are NOT hardcoded here. The seven groups are defined by the theme
-- pipeline (derive_yaml_baseline in theme.lua for every colorscheme, plus
-- hand-tuned entries in lua/config/theme_baseline.lua), so this file only
-- decides WHAT each token is, never what colour it gets.

local M = {}

local ns = vim.api.nvim_create_namespace("YamlExpr")

-- The GitHub Actions expression contexts. A bare word that is one of these, and
-- is not being called and not preceded by a dot, is the namespace of the
-- expression. Everything else in identifier position is a property read.
local CONTEXTS = {
  github = true,
  env = true,
  vars = true,
  secrets = true,
  inputs = true,
  matrix = true,
  needs = true,
  steps = true,
  runner = true,
  job = true,
  jobs = true,
  strategy = true,
  }

-- Priority 220: treesitter paints the enclosing scalar at 100 and LSP semantic
-- tokens land at 125, so anything below that is drawn over and silently does
-- nothing. 200 -> 220 on 2026-07-26: 200 TIED with yaml-tone's YamlTonePeriod
-- matchadd and theme.lua's GlobalCommentReset (both 200), making dots inside
-- ${{ }} non-deterministic once :YamlTone/:YamlPeriods ran. 220 wins outright
-- while staying under indent-ladder's 250 guides.
local PRIORITY = 220

-- Guard: these files are normally tiny, but a generated manifest can be huge
-- and this runs on every edit. Above the cap we simply skip.
local MAX_LINES = 4000

local function mark(buf, row, col_start, col_end, group)
  pcall(vim.api.nvim_buf_set_extmark, buf, ns, row, col_start, {
    end_col = col_end,
    hl_group = group,
    priority = PRIORITY,
    strict = false,
  })
end

-- Tokenize the inside of one ${{ ... }} and mark each token.
-- `base` is the 0-indexed byte column where `inner` starts on the line.
local function scan_expression(buf, row, inner, base)
  local i = 1
  local len = #inner
  while i <= len do
    local rest = inner:sub(i)

    -- whitespace
    local ws = rest:match("^%s+")
    if ws then
      i = i + #ws

    -- 'single quoted literal' — the only string form Actions expressions have
    elseif rest:sub(1, 1) == "'" then
      local s, e = rest:find("^'[^']*'")
      if s then
        mark(buf, row, base + i - 1, base + i - 1 + (e - s + 1), "YamlExprStr")
        i = i + (e - s + 1)
      else
        i = i + 1
      end

    -- identifier: context, function call, or property
    elseif rest:match("^[%a_]") then
      local word = rest:match("^[%a_][%w_%-]*")
      local wlen = #word
      -- A '(' after optional space makes it a call, regardless of the word.
      local is_call = inner:sub(i + wlen):match("^%s*%(") ~= nil
      -- The character before us, ignoring whitespace, tells us whether this is
      -- a member access. Dot beats the context list: in `env.github`, `github`
      -- is a property, not the context.
      local prev = inner:sub(1, i - 1):match("([^%s])%s*$")
      local group
      if is_call then
        group = "YamlExprFunc"
      elseif prev == "." then
        group = "YamlExprProp"
      elseif CONTEXTS[word] then
        group = "YamlExprContext"
      else
        group = "YamlExprProp"
      end
      mark(buf, row, base + i - 1, base + i - 1 + wlen, group)
      i = i + wlen

    -- number
    elseif rest:match("^%d") then
      local num = rest:match("^%d+%.?%d*")
      mark(buf, row, base + i - 1, base + i - 1 + #num, "YamlExprNum")
      i = i + #num

    -- member-access dot
    elseif rest:sub(1, 1) == "." then
      mark(buf, row, base + i - 1, base + i, "YamlExprDot")
      i = i + 1

    -- operators: == != && || ! > < >= <=
    elseif rest:match("^[=!<>&|]") then
      local op = rest:match("^[=!<>&|]+")
      mark(buf, row, base + i - 1, base + i - 1 + #op, "YamlExprOp")
      i = i + #op

    -- parens group with the braces: they are the expression's own punctuation
    elseif rest:sub(1, 1) == "(" or rest:sub(1, 1) == ")" then
      mark(buf, row, base + i - 1, base + i, "YamlExprBrace")
      i = i + 1

    else
      i = i + 1
    end
  end
end

function M.highlight(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local n = vim.api.nvim_buf_line_count(buf)
  if n > MAX_LINES then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for idx, line in ipairs(lines) do
    local row = idx - 1
    -- Skip full-line comments outright; a `${{` inside a comment is prose.
    if not line:match("^%s*#") then
      -- ── Bare expression keys: `if:` and `when:` ──────────────────────────
      -- GitHub Actions treats the body of `if:` as an expression WITHOUT
      -- requiring ${{ }} -- the braces are optional there and almost nobody
      -- writes them. The braced branch below cannot see those lines at all
      -- (its gate needs a literal `${{`), so they fell through to the .scm's
      -- @string.special.condition capture, which paints the WHOLE scalar one
      -- colour.
      --
      -- That was the single most visible inconsistency in the system:
      --   name: Terraform ${{ inputs.action }}   ->  inputs / action, 2 colours
      --   if: inputs.action == 'plan'            ->  one flat colour
      -- Identical syntax, identical semantics, different rendering, purely
      -- because of punctuation the platform does not require.
      --
      -- scan_expression already handles every token in these bodies (==, ||,
      -- 'quoted', dotted access, calls) -- it was simply never invoked. Argo's
      -- `when:` gets the same treatment for the same reason.
      local key, body = line:match("^%s*%-?%s*([%w_]+):%s*(.*)$")
      if key == "if" or key == "when" then
        -- A block scalar indicator (`>`, `|`, `>-`, `|+2`, ...) means the
        -- expression is on the FOLLOWING lines, not this one. Two measured bugs
        -- if it is not special-cased: the indicator itself matches
        -- scan_expression's operator rule and gets painted as an operator, and
        -- the real expression underneath is never scanned at all.
        if body:match("^[>|][-+]?%d*$") then
          -- Continuation lines are the ones indented PAST THE KEY. Comparing
          -- against the line's own leading whitespace instead is wrong for a
          -- sequence item: in `      - if: >` the dash pushes the key out to
          -- column 8 while a sibling `run:` also sits at 8, so a leading-space
          -- test would swallow the sibling into the block.
          local kcol = (line:find(key .. ":", 1, true) or 1) - 1
          for j = idx + 1, #lines do
            local nl = lines[j]
            if not nl:match("^%s*$") then -- blank lines belong to the block
              local ind = #nl:match("^(%s*)")
              if ind <= kcol then
                break
              end
              if not nl:match("^%s*#") then
                local code = nl:match("^(.-)%s+#") or nl
                scan_expression(buf, j - 1, code:sub(ind + 1), ind)
              end
            end
          end
        elseif body ~= "" and not body:find("${{", 1, true) then
          -- Bail on a braced body: the loop below owns those, and running both
          -- would double-mark the interior.
          -- Trailing comment is prose, not expression.
          local code = body:match("^(.-)%s+#") or body
          -- Anchor to the real byte column: the key match is anchored at the
          -- line start, so the body begins wherever the line stops matching.
          local base = #line - #body
          scan_expression(buf, row, code, base)
        end
      end

      local search_from = 1
      while true do
        -- Plain find for the opener, then the matching closer. `%$` and the
        -- braces are escaped Lua-pattern-wise; `.-` is non-greedy so nested
        -- expressions on one line stay separate.
        local s, e, inner = line:find("(%b{})", search_from)
        -- %b{} matches one balanced {...}; Actions uses {{ }}, so a real
        -- expression shows up as an outer {...} whose body starts with '{'.
        if not s then
          break
        end
        local is_expr = line:sub(s - 1, s - 1) == "$" and line:sub(s + 1, s + 1) == "{"
        if is_expr and inner then
          -- Body between the doubled braces.
          local body = inner:sub(3, #inner - 2)
          if line:sub(e - 1, e) == "}}" then
            mark(buf, row, s - 2, s - 1, "YamlExprSigil") -- the $
            mark(buf, row, s - 1, s + 1, "YamlExprBrace") -- {{
            mark(buf, row, e - 2, e, "YamlExprBrace") -- }}
            scan_expression(buf, row, body, s + 1)
          end
        end
        search_from = e + 1
      end
    end
  end
end

local function attach()
  -- Root-filetype test, not equality: see lua/config/yaml_ft.lua. `yaml.github`
  -- is the case that matters here -- workflows are where ${{ }} actually lives,
  -- so an equality check is guaranteed to fail on exactly the files this
  -- feature exists for, the moment a compound filetype is introduced.
  if not require("config.yaml_ft").is_yaml() then
    return
  end
  M.highlight(vim.api.nvim_get_current_buf())
end

vim.api.nvim_create_augroup("YamlExpr", { clear = true })
-- Pattern semantics differ per event: file globs match BufEnter/BufWritePost/
-- TextChanged*, the bare filetype names match FileType, and for ColorScheme the
-- pattern is the COLORSCHEME NAME — a combined list silently never fired on
-- theme switches, leaving stale extmark groups until the next edit. Split out.
vim.api.nvim_create_autocmd(
  { "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "FileType" },
  {
    group = "YamlExpr",
    pattern = { "*.yaml", "*.yml", "yaml", "helm" },
    callback = attach,
  }
)
vim.api.nvim_create_autocmd("ColorScheme", {
  group = "YamlExpr",
  callback = function()
    -- attach() already no-ops for non-yaml/helm buffers.
    vim.schedule(attach) -- after theme.lua's pipeline re-stamps the YamlExpr* groups
  end,
})

vim.api.nvim_create_user_command("YamlExprRefresh", function()
  M.highlight(vim.api.nvim_get_current_buf())
  vim.notify("YamlExpr re-applied")
end, { desc = "Re-apply ${{ }} expression highlighting" })

return {}
