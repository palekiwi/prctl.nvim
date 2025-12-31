local M = {}

-- Run a command in a bottom split terminal window
-- @param cmd table: command array (e.g., {'gh', 'pr', 'checkout', '123'})
-- @param opts table: options
--   - height: number of lines for terminal window (default: 15)
--   - on_exit: callback function(exit_code) called when command finishes
M.run_in_split = function(cmd, opts)
  opts = opts or {}
  local height = opts.height or 15
  local on_exit = opts.on_exit

  -- Save current window to return focus if needed
  local current_win = vim.api.nvim_get_current_win()

  -- Create a new buffer for the terminal
  local buf = vim.api.nvim_create_buf(false, true) -- unlisted, scratch buffer
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe') -- Delete buffer when hidden
  vim.api.nvim_buf_set_option(buf, 'buflisted', false)   -- Don't show in buffer list
  
  -- Create horizontal split at bottom
  vim.cmd('botright ' .. height .. 'split')
  local win = vim.api.nvim_get_current_win()
  
  -- Set the buffer in the new window
  vim.api.nvim_win_set_buf(win, buf)
  
  -- Set window options
  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)
  vim.api.nvim_win_set_option(win, 'signcolumn', 'no')
  vim.api.nvim_win_set_option(win, 'winfixheight', true)
  
  -- Start the terminal with the command
  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code, _)
      vim.schedule(function()
        -- Call the on_exit callback if provided
        if on_exit then
          on_exit(exit_code)
        end
        
        -- Auto-close terminal window after a short delay on success
        if exit_code == 0 then
          vim.defer_fn(function()
            -- Check if window and buffer still exist before closing
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, 2000) -- 2 second delay to read output
        else
          -- On failure, set up a keymap to close with 'q'
          vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', 
            { noremap = true, silent = true, nowait = true })
        end
      end)
    end,
  })
  
  -- Check if termopen succeeded
  if job_id <= 0 then
    vim.api.nvim_win_close(win, true)
    error("Failed to start terminal")
  end
  
  -- Enter insert mode in terminal to show live output
  vim.cmd('startinsert')
  
  return {
    buf = buf,
    win = win,
    job_id = job_id,
  }
end

return M
