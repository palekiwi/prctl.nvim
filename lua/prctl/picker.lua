local M = {}

M.pr_picker = function(prs, opts)
  opts = opts or {}

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entry_display = require('telescope.pickers.entry_display')

  -- Create entry displayer for consistent formatting
  local displayer = entry_display.create({
    separator = "\t",
    items = {
      { width = 6 },        -- PR number
      { width = 80 },       -- Title
      { remaining = true }, -- Author
    },
  })

  -- Entry maker function
  local make_display = function(entry)
    local pr = entry.value
    return displayer({
      pr.number,
      pr.title,
      pr.author.login,
    })
  end

  -- Create picker
  pickers.new(opts, {
    prompt_title = "Pull Requests",
    finder = finders.new_table({
      results = prs,
      entry_maker = function(pr)
        return {
          value = pr,
          display = make_display,
          ordinal = string.format("%d %s %s", pr.number, pr.title, pr.author.login),
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local pr = selection.value
        local gh = require('prctl.gh')
        local utils = require('prctl.utils')

        -- Checkout the selected PR
        gh.checkout_pr(
          pr.number,
          function()
            utils.notify_success(string.format("✓ Checked out PR #%d", pr.number))
          end,
          function(err)
            utils.notify_error("Checkout failed: " .. err)
          end
        )
      end)
      return true -- Keep default mappings
    end,
  }):find()
end

return M
