local M = {}

-- Setup custom highlight groups
M.setup_highlights = function()
  vim.api.nvim_set_hl(0, 'PrctlNumber', { fg = '#6e9440', bold = true })        -- Green
  vim.api.nvim_set_hl(0, 'PrctlTitle', { link = 'Normal' })                     -- Default color
  vim.api.nvim_set_hl(0, 'PrctlAuthor', { fg = '#5f819d' })                     -- Blue
  vim.api.nvim_set_hl(0, 'PrctlTreeConnector', { fg = '#6e738d', bold = false })-- Muted gray for tree lines
end

-- Initialize highlights on module load
M.setup_highlights()

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

  -- Show immediate feedback
  local notif_id = utils.notify_info(
    "Fetching pull requests...",
    { timeout = false }
  )

  -- Fetch PRs
  gh.fetch_prs(
    function(prs)
      vim.schedule(function()
        if #prs == 0 then
          utils.notify_info(
            "No pull requests found",
            { replace = notif_id, timeout = 3000 }
          )
          return
        end
        
        -- Dismiss the notification immediately since picker is opening
        utils.dismiss_notification(notif_id)
        
        picker.pr_picker(prs, opts)
      end)
    end,
    function(err)
      vim.schedule(function()
        utils.notify_error(
          "Failed to fetch PRs: " .. err,
          { replace = notif_id, timeout = 5000 }
        )
      end)
    end
  )
end

return M
