local M = {}

M.pr_picker = function(prs, opts)
  opts = opts or {}

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local tree = require('prctl.tree')

  -- Build tree structure and flatten for display
  local tree_structure = tree.build_pr_tree(prs)
  local flat_entries = tree.flatten_tree(tree_structure)

  -- Create picker
  pickers.new(opts, {
    prompt_title = "Pull Requests",
    finder = finders.new_table({
      results = flat_entries,
      entry_maker = function(entry)
        local pr = entry.pr
        
        -- Get tree prefix
        local prefix = tree.get_tree_prefix(entry)
        
        -- Build display string
        local number_str = tostring(pr.number)
        local combined = prefix .. number_str .. " " .. pr.title
        
        -- Truncate if too long
        local max_width = 80
        if #combined > max_width then
          combined = combined:sub(1, max_width - 3) .. "..."
        end
        
        -- Pad for author alignment
        local padding = string.rep(" ", math.max(0, 80 - vim.fn.strdisplaywidth(combined)))
        local display_str = combined .. padding .. " " .. pr.author.login
        
        return {
          value = entry,
          display = display_str,
          ordinal = string.format("%d %s %s", pr.number, pr.title, pr.author.login),
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local pr = selection.value.pr
        local gh = require('prctl.gh')
        local utils = require('prctl.utils')

        -- Show immediate feedback
        local notif_id = utils.notify_info(
          string.format("Checking out PR #%d...", pr.number),
          { timeout = false }
        )

        -- Checkout the selected PR
        gh.checkout_pr(
          pr.number,
          function()
            utils.notify_success(
              string.format("Checked out PR #%d", pr.number),
              { replace = notif_id, timeout = 3000 }
            )
          end,
          function(err)
            utils.notify_error(
              "Checkout failed: " .. err,
              { replace = notif_id, timeout = 5000 }
            )
          end
        )
      end)
      return true -- Keep default mappings
    end,
  }):find()
end

return M
