local M = {}

-- Detect if nvim-notify is available
local has_notify = pcall(require, "notify")

-- Check if current directory is a git repository
M.is_git_repo = function()
  local result = vim.system(
    { 'git', 'rev-parse', '--is-inside-work-tree' },
    { text = true }
  ):wait()
  
  return result.code == 0
end

-- Check if gh CLI is installed
M.check_gh_installed = function()
  return vim.fn.executable('gh') == 1
end

-- Notification helpers
M.notify_error = function(msg, opts)
  opts = opts or {}
  vim.notify(msg, vim.log.levels.ERROR, vim.tbl_extend("force", {
    title = "prctl.nvim",
  }, opts))
end

M.notify_info = function(msg, opts)
  opts = opts or {}
  local ret = vim.notify(msg, vim.log.levels.INFO, vim.tbl_extend("force", {
    title = "prctl.nvim",
  }, opts))
  return has_notify and ret and ret.id or nil
end

M.notify_success = function(msg, opts)
  opts = opts or {}
  vim.notify(msg, vim.log.levels.INFO, vim.tbl_extend("force", {
    title = "prctl.nvim",
  }, opts))
end

return M
