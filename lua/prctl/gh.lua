local M = {}

-- Fetch pull requests from GitHub
M.fetch_prs = function(on_success, on_error)
  vim.system(
    {
      'gh', 'pr', 'list',
      '--json', 'number,title,author,headRefName,baseRefName,labels',
      '--limit', '50'
    },
    { text = true },
    function(obj)
      vim.schedule(function()
        if obj.code == 0 then
          local ok, prs = pcall(vim.json.decode, obj.stdout)
          
          if ok then
            on_success(prs)
          else
            on_error("Failed to parse PR data")
          end
        else
          on_error(obj.stderr or "Command failed")
        end
      end)
    end
  )
end

-- Checkout a pull request (background execution)
M.checkout_pr = function(pr_number, on_success, on_error)
  -- Check for dirty working tree first (synchronous)
  local status_result = vim.system(
    { 'git', 'status', '--porcelain' },
    { text = true }
  ):wait()
  
  if status_result.code ~= 0 then
    on_error("Failed to check git status")
    return
  end
  
  if status_result.stdout ~= '' then
    on_error("Cannot checkout PR: You have uncommitted changes")
    return
  end
  
  -- Proceed with checkout (asynchronous)
  vim.system(
    { 'gh', 'pr', 'checkout', tostring(pr_number) },
    { text = true },
    function(obj)
      vim.schedule(function()
        if obj.code == 0 then
          on_success()
        else
          on_error(obj.stderr or "Checkout failed")
        end
      end)
    end
  )
end

-- Checkout a pull request in a terminal split window
M.checkout_pr_in_terminal = function(pr_number, on_success, on_error)
  -- Check for dirty working tree first (synchronous)
  local status_result = vim.system(
    { 'git', 'status', '--porcelain' },
    { text = true }
  ):wait()
  
  if status_result.code ~= 0 then
    on_error("Failed to check git status")
    return
  end
  
  if status_result.stdout ~= '' then
    on_error("Cannot checkout PR: You have uncommitted changes")
    return
  end
  
  -- Run checkout in terminal split
  local terminal = require('prctl.terminal')
  terminal.run_in_split(
    { 'gh', 'pr', 'checkout', tostring(pr_number) },
    {
      height = 15,
      on_exit = function(exit_code)
        if exit_code == 0 then
          on_success()
        else
          on_error("Checkout failed with exit code " .. exit_code)
        end
      end
    }
  )
end

return M
