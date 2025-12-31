local M = {}

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
M.notify_error = function(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "prctl.nvim" })
end

M.notify_info = function(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "prctl.nvim" })
end

M.notify_success = function(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "prctl.nvim" })
end

return M
