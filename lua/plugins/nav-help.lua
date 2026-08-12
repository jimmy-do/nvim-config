-- nav-help.lua — :NavHelp, the "how do I find things in this repo" cheat sheet.
--
-- ---------------------------------------------------------------------------
-- WHY THIS EXISTS
-- ---------------------------------------------------------------------------
-- theme-help.lua documents the theme command surface. This is the other half:
-- code navigation. Not a keymap dump -- <leader>sk (fzf-lua keymaps) already
-- lists every mapping with its desc, and that is exactly as useless here as
-- <leader>sC was for the theme knobs. Knowing that <leader>sw exists is not
-- the same as knowing it is the answer to "where else is this used".
--
-- So this is organised by SITUATION, not by key. Left column is what you want,
-- right column is what to press. The important content is the caveats: which
-- of these work in yaml (grep does, LSP mostly does not) and why.
--
-- Sections are hand-written. The staleness guard at the bottom is automatic:
-- every lhs documented here is resolved against the live keymap table, and
-- anything that no longer maps to something is listed. A key that gets
-- renamed or a plugin that stops loading shows up there instead of silently
-- becoming a lie.
--
-- Not a plugin spec -- returns {} like theme-help.lua and the other pure-config
-- files under plugins/. It only needs to run once at startup.

local SECTIONS = {
  {
    title = "LEARNING A REPO YOU DO NOT KNOW",
    blurb = "Start here. Grep is the primary tool -- not LSP. In a repo that is"
      .. " mostly yaml/HCL there are no symbols to jump between, so 'find usages'"
      .. " is literally 'grep the identifier'. That is not a workaround, it is how"
      .. " people actually read infra repos.",
    items = {
      { "<leader>/", "GREP THE WHOLE REPO, live. The one key. Type a value you can see -- core-api, TF_WORKING_DIR, argocd -- and every file that mentions it appears as you type. Enter jumps there, <C-o> comes back." },
      { "<leader>sw", "Grep the word UNDER THE CURSOR, repo-wide. This is your 'find all usages' and it works in every filetype including yaml. Cursor on a name, press it, read the list." },
      { "<leader>ff", "Find file by name. Fuzzy, so 'apyml' finds aws-apply.yml." },
      { "<leader>fr", "Recent files. Fastest way back to the thing you had open ten minutes ago." },
      { "<leader>sF", "Grep only the CURRENT FILE'S DIRECTORY. Use when a name is generic and repo-wide grep returns 200 hits." },
      { "", "Workflow that answers most questions: <leader>/ the identifier -> Enter on a hit -> read -> <C-o> back -> Enter on the next hit. You are done in four keys." },
    },
  },
  {
    title = "GREP VARIANTS (all fzf-lua -- telescope is disabled in this config)",
    blurb = "Two families here, and the difference matters when results disagree."
      .. " <leader>/ is LazyVim STOCK and shows everything. Everything under"
      .. " <leader>s is CUSTOM: those strip comment lines from results. That is why"
      .. " a heavily-commented yaml file can look under-represented in an sg/sw hit"
      .. " list but fully represented under <leader>/ -- the match was in a comment"
      .. " and got filtered on purpose. If the counts differ, that is the reason.",
    items = {
      { "<leader>sg", "Live grep, ROOT DIR (the project root, wherever you are in it)." },
      { "<leader>sG", "Live grep, CWD only. Use when root is too wide." },
      { "<leader>sW", "Word under cursor, CWD only." },
      { "<leader>sk", "Search your own KEYMAPS. When you forget a key, this beats reading this file." },
      { "<leader>sC", "Search COMMANDS. Every :Command with its desc -- this is where the theme knobs live." },
      { "<leader>sh", "Search HELP. Vim's own docs, fuzzy." },
      { "", "Inside any picker: <C-n>/<C-p> move, <C-v> opens in a vsplit, <C-t> in a tab, <Esc> cancels." },
      { "", "IF AN sg/sw/sG/sW PICKER OPENS EMPTY -- '0/0', no error, on a word you can SEE in the file -- that is the comment filter in fzf.lua failing, not rg and not your keys. Cross-check with <leader>/ on the same word: if stock finds it and the custom one does not, the filter is the culprit. It broke exactly this way once (2026-08-11) and it fails SILENTLY, which is why this line exists." },
    },
  },
  {
    title = "LSP NAVIGATION (real code -- lua, bash, terraform, dockerfile)",
    blurb = "These are the VSCode-equivalent keys. They need a language server"
      .. " ATTACHED to the buffer. :LspInfo tells you what is attached right now;"
      .. " if it says nothing, none of this section will do anything and that is"
      .. " the explanation, not a bug.",
    items = {
      { "gd", "Go to DEFINITION. Where is this thing declared." },
      { "gr", "Go to REFERENCES. Every place it is used -- the real 'find usages', when a server exists. Servers installed here: lua, bash, terraform, docker/compose, helm, yaml. NOTHING ELSE. In python/ts/go this does nothing because the server is not installed, and the error you get names treesitter, which is misleading -- it is the fallback talking, not the cause." },
      { "gI", "Go to IMPLEMENTATION." },
      { "gy", "Go to TYPE definition." },
      { "K", "HOVER: docs, type, signature for the thing under the cursor. Press twice to jump INTO the hover window and scroll it." },
      { "<leader>ss", "SYMBOLS in this file -- functions, blocks, keys. The fastest way to orient in a long file you just opened." },
      { "<leader>cr", "Rename the symbol everywhere. LSP-aware, so it is not a blind find/replace." },
      { "<leader>ca", "Code actions (fixes, imports, refactors)." },
    },
  },
  {
    title = "WHY K SAYS 'No information available'",
    blurb = "This is the single most confusing thing about this setup, so it gets"
      .. " its own section.",
    items = {
      { "", "K is LSP hover. It has nothing to do with grep or search. On a buffer with no server attached it always reports nothing." },
      { "", "yaml-language-server IS installed here (lazyvim extras.lang.yaml). So on yaml, K failing is usually NOT a missing server -- it is a missing SCHEMA. yamlls only knows a file if it can match it to a JSON schema by filename or by an inline modeline." },
      { "", "Kubernetes manifests and GitHub Actions workflows are matched and DO hover. ArgoCD Application CRDs, Helm values files and bare config yaml are not in SchemaStore by filename, so they hover nothing." },
      { "", "Force a schema on a file by putting this on line 1: # yaml-language-server: $schema=<url>. That is the only way to make K work on a CRD." },
      { "", "There is no gr for yaml under ANY setup. yamlls implements no references at all -- yaml has no cross-file symbol graph, so there is nothing to enumerate. gr therefore drops to the treesitter fallback and reports that treesitter does not support this filetype. That message is a red herring: installing a parser fixes nothing. Use <leader>sw. This is not a config gap to fix." },
      { "", "gd is the ONE partial exception: recent yamlls resolves anchors and aliases, so gd on *common-env jumps to &common-env. Same file only, and only for real yaml anchors -- not for a k8s name referenced by another manifest. If you are chasing a name across files, that is grep, always." },
      { "", ":LspInfo -- what is attached to this buffer. Check it before assuming anything above is broken." },
    },
  },
  {
    title = "GETTING BACK (the half people skip)",
    blurb = "Navigation is only useful if returning is free. All of these are"
      .. " built into vim, no plugin involved.",
    items = {
      { "<C-o>", "Back to where you jumped FROM. Works across files. Press it repeatedly to walk your whole history backwards." },
      { "<C-i>", "Forward again. The redo to <C-o>'s undo." },
      { "``", "Back to the exact position before the last jump (two backticks)." },
      { "<C-^>", "Toggle between this buffer and the previous one. Two files, ping-pong." },
      { "'\"", "In a freshly opened file: jump to where you were last time you had it open." },
      { "", "gf on a path under the cursor opens that file. Works on the path in a values-file list." },
    },
  },
  {
    title = "FILES AND BUFFERS (this config's own keys)",
    items = {
      { "gb", "SNIPE. Every open buffer gets a fixed letter; press gb then the letter. Draws nothing until pressed -- this is the buffer switcher here, not a tab bar click." },
      { "<S-h> / <S-l>", "Previous / next buffer." },
      { "<leader>bd", "Close this buffer, keep the window layout." },
      { "<leader>nt", "Neo-tree toggle, revealing the current file on the left." },
      { "<leader>nr", "Neo-tree reveal -- open it AND jump to where the current file sits in it. Best 'where am I in this repo' answer." },
      { "<leader>e", "Neo-tree (LazyVim default)." },
    },
  },
  {
    title = "PROJECT SHORTCUTS ALREADY WIRED UP",
    blurb = "These exist in keymaps.lua. They assume the standard infra repo layout.",
    items = {
      { "<leader>or", "Open README.md." },
      { "<leader>og", "Open .github/workflows." },
      { "<leader>ok", "Open the k8s folder." },
      { "<leader>ot", "Open the terraform folder." },
    },
  },
  {
    title = "DIAGNOSTICS AND ERRORS",
    items = {
      { "<leader>cd", "Full diagnostic for the current line, in a float. The lualine indicator only counts them; this is how you read one." },
      { "<leader>cq", "All diagnostics into the location list." },
      { "]d / [d", "Next / previous diagnostic in this file." },
      { "]e / [e", "Next / previous ERROR only, skipping warnings and hints." },
    },
  },
  {
    title = "SEEING INTO A FILE YOU JUST OPENED",
    items = {
      { "zR / zM", "Open every fold / close every fold. zM then zR is a fast structural skim of a long yaml file." },
      { "za", "Toggle the fold under the cursor." },
      { "{ / }", "Jump by blank-line-separated block. In yaml this lands on section boundaries." },
      { "%", "Jump to the matching bracket." },
      { "*", "Search forward for the word under the cursor IN THIS FILE. The local-only counterpart to <leader>sw. It builds the search FOR you -- no typing the name out -- then jumps to the next occurrence." },
      { "#", "Same as * but backwards." },
      { "n / N", "Repeat that jump forwards / backwards. They only REPEAT a search, they cannot start one -- that is what * is for. So: * once, then n n n to walk every hit, N to back up." },
      { "g*", "Like * but matches substrings too. * on 'app' skips 'apparmor'; g* stops on it." },
      { "<leader>ss", "Document symbols -- see the LSP section. Needs a server." },
    },
  },
  {
    title = "MISC WORTH KNOWING",
    items = {
      { "<C-;>", "Command mode without Shift. Same as pressing colon." },
      { "<leader>", "Just press it and WAIT. which-key shows every key available from here, live. This is the discovery mechanism -- this file is the annotated version of it." },
      { ":ThemeHelp", "The other cheat sheet: every theme and yaml colour knob." },
      { ":NavHelp <filter>", "This file, filtered. :NavHelp grep shows only grep lines." },
    },
  },
}

-- Every lhs this file claims, checked against the live keymap table. A key that
-- no longer resolves is listed at the bottom rather than quietly lying. Only
-- <leader>/<C-...> style lhs are checked -- plain-vim motions like % and { are
-- built in, never in the keymap table, and would be false positives.
--
-- SKIP is the rest of the false positives, and each entry earns its place:
--   * <C-o> <C-i> <C-^> are BUILT IN. They are the most important keys in this
--     file and they are not mappings, so the check can never see them.
--   * <leader> alone is the which-key prompt, not an lhs.
--   * <leader>cr and <leader>ca are LSP BUFFER-LOCAL -- they exist only while a
--     server is attached. Checking them would make the guard fire on every yaml
--     buffer, which is precisely the situation this file explains as normal.
local SKIP = {
  ["<C-o>"] = true,
  ["<C-i>"] = true,
  ["<C-^>"] = true,
  ["<leader>"] = true,
  ["<leader>cr"] = true,
  ["<leader>ca"] = true,
  -- <C-;> IS mapped (config/keymaps.lua) but does not survive the
  -- replace_termcodes round trip the check does -- it only exists as a distinct
  -- key at all because tmux extended-keys is on. Verified present by hand; the
  -- guard simply cannot see it.
  ["<C-;>"] = true,
}

local function documented_keys()
  local out = {}
  for _, section in ipairs(SECTIONS) do
    for _, item in ipairs(section.items) do
      local lhs = item[1]
      if lhs ~= "" and (lhs:find("<leader>", 1, true) or lhs:find("^<C%-")) then
        for part in lhs:gmatch("[^/]+") do
          part = vim.trim(part)
          if not SKIP[part] then
            table.insert(out, part)
          end
        end
      end
    end
  end
  return out
end

local function unresolved()
  local leader = vim.g.mapleader == " " and " " or (vim.g.mapleader or "\\")
  local bad = {}
  for _, lhs in ipairs(documented_keys()) do
    local resolved = lhs:gsub("<leader>", leader)
    -- maparg on the translated form; empty rhs AND empty callback = not mapped.
    local m = vim.fn.maparg(vim.api.nvim_replace_termcodes(resolved, true, true, true), "n", false, true)
    if type(m) ~= "table" or vim.tbl_isempty(m) then
      table.insert(bad, lhs)
    end
  end
  return bad
end

local function build_lines(filter)
  local lines = {}
  local function add(s)
    table.insert(lines, s)
  end

  add("# Navigating code")
  add("")
  add("Organised by what you are trying to do. In infra repos grep is the main")
  add("tool and LSP is the bonus -- not the other way round.")
  if filter and filter ~= "" then
    add("")
    add("Filtered by: " .. filter)
  end

  local needle = filter and filter ~= "" and filter:lower() or nil

  for _, section in ipairs(SECTIONS) do
    local matched = {}
    for _, item in ipairs(section.items) do
      local hay = (item[1] .. " " .. item[2] .. " " .. section.title):lower()
      if not needle or hay:find(needle, 1, true) then
        table.insert(matched, item)
      end
    end
    if #matched > 0 then
      add("")
      add("## " .. section.title)
      if section.blurb then
        add("")
        add(section.blurb)
      end
      add("")
      for _, item in ipairs(matched) do
        if item[1] == "" then
          add("  " .. item[2])
        else
          add("  " .. item[1])
          add("      " .. item[2])
        end
      end
    end
  end

  local bad = unresolved()
  if #bad > 0 then
    add("")
    add("## DOCUMENTED BUT NOT CURRENTLY MAPPED")
    add("")
    add("  These lhs resolve to nothing in normal mode right now -- a plugin did")
    add("  not load, or the key was renamed. Fix the config or fix this file.")
    add("")
    for _, lhs in ipairs(bad) do
      add("  " .. lhs)
    end
  end

  add("")
  return lines
end

vim.api.nvim_create_user_command("NavHelp", function(opts)
  local lines = build_lines(vim.trim(opts.args))

  -- Vertical split, matching :ThemeHelp: this is read beside the file you are
  -- trying to navigate, and a float would cover the thing you are looking at.
  vim.cmd("botright vsplit")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.api.nvim_win_set_width(0, math.min(90, math.floor(vim.o.columns * 0.5)))
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
end, {
  nargs = "?",
  desc = "Code navigation cheat sheet (optional filter, e.g. :NavHelp grep). q closes.",
})

vim.keymap.set("n", "<leader>H", "<cmd>NavHelp<cr>", { desc = "Navigation cheat sheet" })

return {}
