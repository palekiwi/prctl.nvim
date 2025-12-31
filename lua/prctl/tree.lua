local M = {}

--- Find all children of a given PR
--- A child PR is one whose baseRefName matches this PR's headRefName
--- @param pr table The PR to find children for
--- @param all_prs table List of all PRs
--- @return table List of child PRs
local function find_children(pr, all_prs)
  local children = {}
  
  for _, candidate in ipairs(all_prs) do
    -- A PR is a child if its base branch is this PR's head branch
    if candidate.baseRefName == pr.headRefName then
      table.insert(children, candidate)
    end
  end
  
  return children
end

--- Build a tree structure from a flat list of PRs
--- Creates parent-child relationships based on branch dependencies
--- @param prs table List of PRs from GitHub API
--- @return table Tree structure grouped by base branch
function M.build_pr_tree(prs)
  -- Phase 1: Index PRs by headRefName for O(1) parent lookup
  local pr_by_branch = {}
  for _, pr in ipairs(prs) do
    pr_by_branch[pr.headRefName] = pr
  end
  
  -- Phase 2: Build parent → children relationships
  local roots = {}
  
  for _, pr in ipairs(prs) do
    -- Find and attach children to this PR
    pr.children = find_children(pr, prs)
    
    -- Determine if this is a root PR
    local parent_pr = pr_by_branch[pr.baseRefName]
    
    if not parent_pr then
      -- This PR doesn't depend on another PR - it's a root
      table.insert(roots, pr)
    end
    -- Note: If parent_pr exists, this PR is already in parent_pr.children
  end
  
  -- Phase 3: Group roots by base branch
  return M.group_by_base(roots)
end

--- Group root PRs by their base branch
--- @param roots table List of root PRs
--- @return table Groups keyed by base branch name
function M.group_by_base(roots)
  local groups = {}
  
  for _, pr in ipairs(roots) do
    local base = pr.baseRefName
    if not groups[base] then
      groups[base] = {
        base_branch = base,
        prs = {}
      }
    end
    table.insert(groups[base].prs, pr)
  end
  
  return groups
end

--- Recursively flatten a PR and its children into a list
--- @param pr table The PR to flatten
--- @param depth number Current depth in tree (0 = root)
--- @param parent_connectors table List of booleans indicating if parent levels have siblings below
--- @param flat table The accumulator list to append to
--- @param is_last_sibling boolean Whether this is the last child of its parent
local function flatten_pr(pr, depth, parent_connectors, flat, is_last_sibling)
  table.insert(flat, {
    type = "pr",
    pr = pr,
    depth = depth,
    parent_connectors = vim.deepcopy(parent_connectors),
    is_last_sibling = is_last_sibling,
  })
  
  -- Recursively add children
  if pr.children and #pr.children > 0 then
    local new_connectors = vim.deepcopy(parent_connectors)
    table.insert(new_connectors, not is_last_sibling)
    
    for i, child in ipairs(pr.children) do
      local is_last = (i == #pr.children)
      flatten_pr(child, depth + 1, new_connectors, flat, is_last)
    end
  end
end

--- Flatten tree structure into a list suitable for Telescope
--- Maintains hierarchy information without group headers
--- @param groups table Tree structure from build_pr_tree
--- @return table Flattened list with metadata for display
function M.flatten_tree(groups)
  local flat = {}
  
  -- Sort base branches alphabetically for consistent display
  local group_keys = vim.tbl_keys(groups)
  table.sort(group_keys)
  
  for _, base_branch in ipairs(group_keys) do
    local group = groups[base_branch]
    
    -- Add PRs in this group with tree structure (no group header)
    for i, pr in ipairs(group.prs) do
      local is_last = (i == #group.prs)
      flatten_pr(pr, 0, {}, flat, is_last)
    end
  end
  
  return flat
end

--- Generate tree connector prefix for display
--- Creates box-drawing characters to show hierarchy
--- @param entry table Entry with depth, parent_connectors, is_last_sibling
--- @return string prefix The tree connector string
function M.get_tree_prefix(entry)
  if entry.depth == 0 then
    return "" -- No prefix for root PRs
  end
  
  local prefix = ""
  
  -- Build vertical connectors for parent levels
  -- parent_connectors[i] = true means parent at level i has more siblings below it
  for i = 1, entry.depth - 1 do
    if entry.parent_connectors[i] then
      prefix = prefix .. "│ "  -- Parent has more siblings below
    else
      prefix = prefix .. "  "  -- Parent was last sibling (2 spaces)
    end
  end
  
  -- Add final connector for this level
  if entry.is_last_sibling then
    prefix = prefix .. "└─"  -- Last child
  else
    prefix = prefix .. "├─"  -- Has siblings below
  end
  
  return prefix
end

return M
