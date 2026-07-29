-- Start where you left off.
--
-- Both bare `nvim` and `nvim <dir>` used to dump you somewhere you did not want:
-- bare nvim on the dashboard, `nvim <dir>` straight into the fzf file picker
-- (which is what force-loaded fzf-lua at startup — nothing else does; plain nvim
-- has never loaded it). Either way the first thing typed was <leader>ql. So do
-- that automatically instead.
--
-- Precedence, both cases:
--   1. the session for this cwd (persistence's own branch-aware name, then the
--      branch-less one — the same two-step `<leader>qs` does)
--   2. bare `nvim` only: the most recent session anywhere, which is exactly what
--      <leader>ql loads
--   3. nothing to restore → the old behaviour: dashboard for bare nvim, file
--      picker for a dir arg. Only that last fallback loads fzf, and only when
--      there is genuinely no session for the directory.
--
-- A dir arg deliberately never falls through to (2): "open this project" must
-- not resurrect an unrelated project's window layout.

local M = {}

-- Set by the StdinReadPre autocmd below. `nvim -` / `cmd | nvim` has content on
-- the way in and must not be replaced by a session.
local from_stdin = false

vim.api.nvim_create_autocmd("StdinReadPre", {
  group = vim.api.nvim_create_augroup("jimmy_startup_stdin", { clear = true }),
  callback = function()
    from_stdin = true
  end,
})

-- The session file that would be restored for the current cwd, or nil.
-- Reads persistence's config for the path but does NOT load the plugin's runtime
-- side effects beyond that — it is required either way a moment later.
local function cwd_session()
  local ok, persistence = pcall(require, "persistence")
  if not ok then
    return nil
  end
  for _, file in ipairs({ persistence.current(), persistence.current({ branch = false }) }) do
    if file and vim.fn.filereadable(file) ~= 0 then
      return file
    end
  end
  return nil
end

local function last_session()
  local ok, persistence = pcall(require, "persistence")
  if not ok then
    return nil
  end
  local file = persistence.last()
  return (file and vim.fn.filereadable(file) ~= 0) and file or nil
end

-- Would a bare `nvim` right now restore something? Used at spec time to decide
-- whether the dashboard is worth showing at all, so there is no dashboard flash
-- before the session paints over it.
function M.will_restore_on_startup()
  if vim.fn.argc(-1) ~= 0 then
    return false
  end
  return (cwd_session() or last_session()) ~= nil
end

-- Re-run filetype detection on restored buffers that never got a filetype.
--
-- Why this is needed (measured 2026-07-27, nvim 0.12.4): the session file's FIRST
-- `edit` lands with Vim's internal `did_filetype` flag already set, because we
-- source the session from inside a VimEnter autocmd. Neovim's detection autocmd
-- uses `:setf`, and `:setf` is a documented NO-OP while that flag is true. So the
-- buffer loads, BufReadPost fires, detection matches "yaml" correctly -- and then
-- silently declines to set it. Later buffers in the same session are unaffected;
-- the flag has been reset by then. Trace of a two-file session:
--
--   BufReadPre   buf=2 did_filetype=0        <- aws-apply.yml
--   BufReadPost  buf=2 did_filetype=1        <- setf no-ops, no FileType, ft=""
--   BufReadPre   buf=3 did_filetype=0        <- application.yaml
--   BufReadPost  buf=3 did_filetype=0
--   FileType     buf=3 ft="yaml"             <- fine
--
-- No filetype means no treesitter attach, which is why exactly one window came
-- back as flat unhighlighted text while the other was fully coloured. Nothing to
-- do with the colorscheme -- the yaml groups were never applied to that buffer.
--
-- Deliberately only touches buffers with an EMPTY filetype: a buffer that
-- detected fine, or one the session explicitly typed, is left alone.
--
-- Directories are skipped too. A session saved from `nvim <dir>` keeps that dir
-- in its arglist (`$argadd ~/project/`), which leaves a buffer whose name is a
-- directory. Entering it -- which nvim_buf_call does -- is precisely netrw's
-- cue to draw a directory listing, and that listing then owns the screen. That
-- was the mystery netrw window on every restore.
local function redetect_filetypes()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].filetype == ""
      and vim.bo[buf].buftype == "" -- skip terminals, quickfix, scratch UI buffers
      and name ~= ""
      and vim.fn.isdirectory(name) ~= 1
    then
      pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd("filetype detect")
      end)
    end
  end
end

-- The netrw listing that showed up on every restore, and had to be `:bd`'d by
-- hand each time. A session saved from `nvim <dir>` writes BOTH
--
--   $argadd ~/k8s-gitops-delivery-platform
--   edit    ~/k8s-gitops-delivery-platform
--
-- into the session file. Sourcing it runs that `edit` on a directory, which is
-- netrw's cue to draw a listing, and the listing takes the window. The earlier
-- fix (skipping directories in redetect_filetypes, above) stopped US from
-- entering the buffer, but the session file itself still creates it, so it kept
-- coming back.
--
-- Two halves, and both are needed:
--   * purge on restore — every session file already written carries the stale
--     `$argadd`/`edit`, so old sessions have to be cleaned as they load;
--   * prune on save (see the SessionSavePre autocmd) — clears the arglist so
--     newly written sessions never contain a directory in the first place.
local function purge_directory_buffers()
  -- A window showing the listing needs somewhere else to go first, otherwise
  -- deleting the buffer leaves it on a blank [No Name].
  local fallback
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buflisted and name ~= "" and vim.fn.isdirectory(name) ~= 1 and vim.fn.filereadable(name) == 1 then
      fallback = buf
      break
    end
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.api.nvim_buf_is_valid(buf) and (vim.bo[buf].filetype == "netrw" or (name ~= "" and vim.fn.isdirectory(name) == 1)) then
      if fallback then
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            pcall(vim.api.nvim_win_set_buf, win, fallback)
          end
        end
      end
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  -- The arglist entry is what mksession turns back into `$argadd`, so drop it
  -- too or this session re-saves the same directory on exit.
  for i = vim.fn.argc(-1) - 1, 0, -1 do
    if vim.fn.isdirectory(vim.fn.argv(i)) == 1 then
      pcall(vim.cmd, i .. "argdelete")
    end
  end
end

local function restore(file)
  local ok, persistence = pcall(require, "persistence")
  if not ok then
    return false
  end
  persistence.fire("LoadPre")
  local sourced = pcall(vim.cmd, "silent! source " .. vim.fn.fnameescape(file))
  persistence.fire("LoadPost")
  vim.schedule(purge_directory_buffers)
  -- Scheduled, not immediate: `did_filetype` is still set while we are inside the
  -- VimEnter callback, so detecting here would hit the same no-op that caused the
  -- problem. One tick later the flag is clear and `:filetype detect` takes.
  vim.schedule(redetect_filetypes)
  return sourced
end

-- Save side of the netrw fix above: persistence saves with :mksession, and
-- mksession writes the arglist verbatim. `nvim <dir>` puts the directory in that
-- arglist, so without this every save re-writes `$argadd <dir>` + `edit <dir>`
-- and the listing is back on the next restore. Fired for both <leader>qs and the
-- automatic VimLeavePre save.
vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceSavePre",
  group = vim.api.nvim_create_augroup("jimmy_session_no_dirs", { clear = true }),
  callback = function()
    for i = vim.fn.argc(-1) - 1, 0, -1 do
      if vim.fn.isdirectory(vim.fn.argv(i)) == 1 then
        pcall(vim.cmd, i .. "argdelete")
      end
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if vim.bo[buf].filetype == "netrw" or (name ~= "" and vim.fn.isdirectory(name) == 1) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("jimmy_startup_session", { clear = true }),
  nested = true,
  callback = function()
    if from_stdin then
      return
    end

    local argc = vim.fn.argc(-1)

    -- Bare `nvim`: cwd session, else the most recent one anywhere.
    if argc == 0 then
      local file = cwd_session() or last_session()
      if file then
        restore(file)
      end
      return
    end

    -- `nvim <dir>`: cd in, drop the directory buffer, restore that project's
    -- session. neo-tree's netrw hijack is off (see lua/plugins/neo-tree.lua), so
    -- without this the dir arg lands in a netrw listing.
    if argc ~= 1 then
      return
    end
    local arg = vim.fn.argv(0)
    if vim.fn.isdirectory(arg) ~= 1 then
      return
    end

    vim.cmd.cd(vim.fn.fnamemodify(arg, ":p"))
    pcall(vim.api.nvim_buf_delete, vim.api.nvim_get_current_buf(), { force = true })
    -- Drop it from the arglist too. `<leader>qs` calls persistence.save()
    -- directly, which does NOT fire PersistenceSavePre, so a manual save in a
    -- session started this way would otherwise still write `$argadd <dir>` out.
    pcall(vim.cmd, "0argdelete")

    -- cwd only — see the header note about not resurrecting another project.
    local file = cwd_session()
    if file then
      restore(file)
      return
    end

    -- No session for this directory: the old behaviour. Deferred because the
    -- picker wants a settled window, and LazyVim.pick resolves to whichever
    -- picker the extras installed (fzf-lua here) — this is the only startup path
    -- that loads it.
    vim.schedule(function()
      LazyVim.pick("files")()
    end)
  end,
})

return {
  -- No dashboard when a session is going to replace it a few milliseconds later.
  -- Decided at spec time (cwd and argc are both already final) rather than by
  -- racing snacks' own VimEnter handler.
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      if M.will_restore_on_startup() then
        opts.dashboard = vim.tbl_deep_extend("force", opts.dashboard or {}, { enabled = false })
      end
      return opts
    end,
  },

  -- persistence must be loaded before VimEnter for any of the above to see a
  -- session. LazyVim lazy-loads it on BufReadPre, which on a bare `nvim` never
  -- fires — the reason the session had to be pulled in by hand with <leader>ql.
  {
    "folke/persistence.nvim",
    lazy = false,
    priority = 100,
  },
}
