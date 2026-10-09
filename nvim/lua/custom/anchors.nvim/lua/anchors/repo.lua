-- Repo identity. Everything stored must be machine independent, so paths are
-- repo relative and repos are keyed by their remote, not their location on disk.
local M = {}

local key_cache = {}

local function git(root, args)
  local cmd = vim.list_extend({ "git", "-C", root }, args)
  local res = vim.system(cmd, { text = true }):wait()
  if res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout)
end

--- Absolute path of the git repo containing `path` (defaults to current buffer).
---@param path? string
---@return string?
function M.root(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.uv.cwd()
  end
  return vim.fs.root(path, ".git")
end

--- "git@github.com:user/repo.git" -> "github.com/user/repo"
---@param url string
---@return string
function M.normalize_remote(url)
  url = url:gsub("%.git$", "")
  url = url:gsub("^%w+://", "")
  url = url:gsub("^[^@/]+@", "")
  url = url:gsub(":%d+/", "/", 1)
  url = url:gsub(":", "/", 1)
  url = url:gsub("[^%w%._%-/]", "_")
  return url
end

--- Portable identifier for a repo: origin remote, else the root commit, else the dir name.
---@param root string
---@return string
function M.key(root)
  if key_cache[root] then
    return key_cache[root]
  end
  local key
  local remote = git(root, { "remote", "get-url", "origin" })
  if remote and remote ~= "" then
    key = M.normalize_remote(remote)
  else
    local first = git(root, { "rev-list", "--max-parents=0", "HEAD" })
    if first and first ~= "" then
      key = "local/" .. vim.split(first, "\n")[1]:sub(1, 12)
    else
      key = "local/" .. vim.fs.basename(root)
    end
  end
  key_cache[root] = key
  return key
end

--- Path relative to the repo root, always "/" separated.
---@param root string
---@param path string
---@return string?
function M.relpath(root, path)
  local rel = vim.fs.relpath(root, vim.fs.normalize(path))
  return rel
end

return M
