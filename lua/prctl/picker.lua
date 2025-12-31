local M = {}

M.pr_picker = function(prs, opts)
  opts = opts or {}

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entry_display = require('telescope.pickers.entry_display')
  local tree = require('prctl.tree')

  -- Build tree structure and flatten for display
  local tree_structure = tree.build_pr_tree(prs)
  local flat_entries = tree.flatten_tree(tree_structure)

  -- Calculate maximum column widths dynamically
  local max_tree_number_width = 0
  local max_author_width = 0

  for _, entry in ipairs(flat_entries) do
    local pr = entry.pr
    local prefix = tree.get_tree_prefix(entry)
    local tree_and_number = prefix .. tostring(pr.number)
    
    max_tree_number_width = math.max(max_tree_number_width, vim.fn.strdisplaywidth(tree_and_number))
    max_author_width = math.max(max_author_width, vim.fn.strdisplaywidth(pr.author.login))
  end

  -- Apply constraints: minimum widths for consistency, maximum to prevent extreme cases
  max_tree_number_width = math.min(math.max(max_tree_number_width, 8), 30)
  max_author_width = math.min(math.max(max_author_width, 15), 35)

  -- Create displayer with dynamic widths
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = max_tree_number_width },  -- Dynamic: tree prefix + PR number
      { remaining = true },                -- Title takes remaining space
      { width = max_author_width },        -- Dynamic: author name
    },
  })

  -- Create picker
  pickers.new(opts, {
    prompt_title = "Pull Requests",
    finder = finders.new_table({
      results = flat_entries,
      entry_maker = function(entry)
        local pr = entry.pr
        
        -- Get tree prefix
        local prefix = tree.get_tree_prefix(entry)
        
        -- Build tree + number combined
        local tree_and_number = prefix .. tostring(pr.number)
        
        return {
          value = entry,
          ordinal = string.format("%d %s %s", pr.number, pr.title, pr.author.login),
          display = function(e)
            return displayer({
              { tree_and_number, "PrctlNumber" },  -- Tree + number in green
              pr.title,                             -- Title in default color
              { pr.author.login, "PrctlAuthor" },  -- Author in blue
            })
          end,
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
