local M = {}

M.prctl = function(opts)
  opts = opts or {}
  
  local utils = require('prctl.utils')
  local gh = require('prctl.gh')
  local picker = require('prctl.picker')
  
  -- Pre-flight checks
  if not utils.is_git_repo() then
    utils.notify_error("Not in a git repository")
    return
  end
  
  if not utils.check_gh_installed() then
    utils.notify_error("GitHub CLI (gh) not installed")
    return
  end
  
  -- Fetch PRs
  gh.fetch_prs(
    function(prs)
      vim.schedule(function()
        if #prs == 0 then
          utils.notify_info("No pull requests found")
          return
        end
        picker.pr_picker(prs, opts)
      end)
    end,
    function(err)
      vim.schedule(function()
        utils.notify_error("Failed to fetch PRs: " .. err)
      end)
    end
  )
end

return M
