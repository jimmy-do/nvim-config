-- exit_watchdog -- guarantee that quitting nvim actually ends the process.
--
-- THE CASE THIS EXISTS FOR. An nvim was found holding a full core for 36
-- minutes after `:qa`. Its stack was entirely inside loop_close:
--
--   nv_colon -> do_cmdline -> ex_quitall -> getout -> os_exit -> loop_close
--     -> uv_walk / loop_walk_cb / uv_is_closing      (100% of samples)
--
-- loop_close spins `do { uv_run(NOWAIT); uv_walk(close everything) } while
-- (uv_loop_close() == EBUSY)`. One libuv handle that can never finish closing
-- makes that loop run forever at 100% CPU. The editor is already gone by then
-- -- buffers, shada and the session are all written well before os_exit -- so
-- what is left burning is a corpse with nothing to protect.
--
-- WHY A WATCHDOG AND NOT A FIX. The specific stuck handle was never identified:
-- the process died before its handle table could be dumped, and the leak that
-- WAS found (yaml-key-depth's debounce timers, fixed separately) does not
-- reproduce the hang even at 60k leaked handles. Rather than guess at a root
-- cause, this bounds the damage: whatever the handle is, and whatever future
-- plugin introduces the next one, the exit path can no longer outlive
-- `timeout` seconds.
--
-- WHY SIGKILL IS SAFE HERE. The watchdog is armed at VimLeavePre, which runs
-- BEFORE the session save, the shada write and every BufWritePre. By the time
-- the timer could possibly fire, all of that is on disk. The timeout is set
-- far above a normal teardown (measured at 0.09-0.56s) so a healthy exit is
-- never in the blast radius -- the process is long gone and the watchdog's
-- kill lands on nothing.
--
-- The watchdog is a detached shell, not a uv timer: a uv timer would live in
-- the very loop that is stuck, and would never get to run.

local M = {}

-- Seconds to allow for teardown before assuming the loop is wedged. Healthy
-- exits finish in well under a second; 15 is two orders of magnitude of slack.
local timeout = tonumber(vim.g.exit_watchdog_secs) or 15

local logfile = vim.fn.stdpath("state") .. "/exit-watchdog.log"

-- PID reuse guard: match the process START TIME as well as the pid, so a
-- recycled pid belonging to some other process can never be killed. `ps -o
-- lstart=` is stable for the life of a process and differs between two
-- processes that merely share a number.
local function start_stamp(pid)
  local out = vim.fn.system({ "ps", "-o", "lstart=", "-p", tostring(pid) })
  return (out:gsub("^%s*(.-)%s*$", "%1"))
end

function M.arm()
  local pid = vim.uv.os_getpid()
  local stamp = start_stamp(pid)
  if stamp == "" then
    return
  end

  local script = [[
    pid=$1; want=$2; secs=$3; log=$4
    sleep "$secs"
    cur=$(ps -o lstart= -p "$pid" 2>/dev/null | sed -e 's/^ *//' -e 's/ *$//')
    # Exited cleanly (no such pid), or the pid was recycled by someone else.
    [ -n "$cur" ] || exit 0
    [ "$cur" = "$want" ] || exit 0
    printf '%s killed wedged nvim pid=%s after %ss\n' "$(date '+%F %T')" "$pid" "$secs" >> "$log"
    kill -9 "$pid"
  ]]

  -- detach: the job must outlive the process it is watching. Without this nvim
  -- reaps its children on exit and the watchdog dies with the thing it guards.
  pcall(vim.fn.jobstart, {
    "sh",
    "-c",
    script,
    "_",
    tostring(pid),
    stamp,
    tostring(timeout),
    logfile,
  }, { detach = true })
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("ExitWatchdog", { clear = true }),
  callback = M.arm,
})

return M
