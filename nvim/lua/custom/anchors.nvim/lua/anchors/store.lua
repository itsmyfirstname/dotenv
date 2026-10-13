-- Entries are plain markdown files with a small frontmatter block:
--   <store>/<repo key>/<fingerprint>.md
-- The store is meant to be a git repo you commit at your leisure, so nothing
-- machine specific (absolute paths, hostnames) is ever written.
local M = {}

local FIELDS = { "id", "keyword", "title", "path", "line", "created", "updated" }

---@param opts table
---@param repo_key string
---@return string
function M.dir(opts, repo_key)
  return vim.fs.joinpath(vim.fs.normalize(opts.store), repo_key)
end

---@param opts table
---@param repo_key string
---@param id string
---@return string
function M.path(opts, repo_key, id)
  return vim.fs.joinpath(M.dir(opts, repo_key), id .. ".md")
end

local function now()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

---@param lines string[]
---@return table meta, integer body_start
function M.parse(lines)
  local meta = {}
  if lines[1] ~= "---" then
    return meta, 1
  end
  for i = 2, #lines do
    if lines[i] == "---" then
      return meta, i + 1
    end
    local key, value = lines[i]:match("^(%w+):%s*(.*)$")
    if key then
      if value:sub(1, 1) == '"' then
        local ok, decoded = pcall(vim.json.decode, value)
        meta[key] = ok and decoded or value
      else
        meta[key] = tonumber(value) or value
      end
    end
  end
  return meta, 1
end

---@param meta table
---@return string[]
function M.frontmatter(meta)
  local lines = { "---" }
  for _, key in ipairs(FIELDS) do
    local value = meta[key]
    if value ~= nil then
      if type(value) == "string" then
        value = vim.json.encode(value)
      end
      table.insert(lines, ("%s: %s"):format(key, value))
    end
  end
  table.insert(lines, "---")
  return lines
end

---@param file string
---@return table? meta
function M.read(file)
  if not vim.uv.fs_stat(file) then
    return nil
  end
  local meta = M.parse(vim.fn.readfile(file, "", 20))
  return meta
end

--- Create the entry file for an anchor if it does not exist yet.
---@param opts table
---@param repo_key string
---@param anchor anchors.Anchor
---@return string file, boolean created
function M.ensure(opts, repo_key, anchor)
  local file = M.path(opts, repo_key, anchor.id)
  if vim.uv.fs_stat(file) then
    return file, false
  end
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  local stamp = now()
  local lines = M.frontmatter({
    id = anchor.id,
    keyword = anchor.keyword,
    title = anchor.title,
    path = anchor.path,
    line = anchor.lnum,
    created = stamp,
    updated = stamp,
  })
  vim.list_extend(lines, { "", "# " .. anchor.title, "", "" })
  vim.fn.writefile(lines, file)
  return file, true
end

--- All entries stored for a repo, keyed by id.
---@param opts table
---@param repo_key string
---@return table<string, table>
function M.list(opts, repo_key)
  local entries = {}
  local dir = M.dir(opts, repo_key)
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:match("%.md$") then
      local file = vim.fs.joinpath(dir, name)
      local meta = M.read(file) or {}
      meta.id = meta.id or name:gsub("%.md$", "")
      meta.file = file
      entries[meta.id] = meta
    end
  end
  return entries
end

--- Re-point an existing entry at a different anchor: new id/file, same body.
---@param opts table
---@param repo_key string
---@param entry table entry metadata with `file`
---@param anchor anchors.Anchor
---@return string? file, string? err
function M.move(opts, repo_key, entry, anchor)
  local target = M.path(opts, repo_key, anchor.id)
  if target ~= entry.file and vim.uv.fs_stat(target) then
    return nil, "an entry already exists for " .. anchor.id
  end
  local buf = vim.fn.bufnr(entry.file)
  if buf ~= -1 then
    if vim.bo[buf].modified then
      return nil, "unsaved changes in " .. entry.file
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  local lines = vim.fn.readfile(entry.file)
  local meta, body_start = M.parse(lines)
  local body = vim.list_slice(lines, body_start)
  for i, line in ipairs(body) do
    if line == "# " .. (meta.title or "") then
      body[i] = "# " .. anchor.title
      break
    end
  end
  meta = vim.tbl_extend("force", meta, {
    id = anchor.id,
    keyword = anchor.keyword,
    title = anchor.title,
    path = anchor.path,
    line = anchor.lnum,
    updated = now(),
  })
  local out = M.frontmatter(meta)
  vim.list_extend(out, body)
  vim.fn.writefile(out, target)
  if target ~= entry.file then
    vim.uv.fs_unlink(entry.file)
  end
  return target
end

--- Refresh the `updated` stamp (and optionally line hint) in a buffer before it is written.
---@param buf integer
---@param fields? table
function M.touch(buf, fields)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local meta, body_start = M.parse(lines)
  if body_start == 1 then
    return
  end
  meta = vim.tbl_extend("force", meta, fields or {}, { updated = now() })
  vim.api.nvim_buf_set_lines(buf, 0, body_start - 1, false, M.frontmatter(meta))
end

return M
