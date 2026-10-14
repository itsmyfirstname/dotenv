-- An anchor is a todo-comments style comment ("TODO: ...", "NOTE: ...").
-- Once it has an entry it carries a random id right after the keyword:
--   TODO: (hj6shjgdf) message
-- The id survives file moves, renames and message edits, so the entry follows it.
-- Untagged anchors fall back to a fingerprint derived only from portable data:
--   repo relative path + keyword + normalized message + occurrence index
-- Line numbers are deliberately left out: they shift on every edit above the
-- comment, which would orphan the entry. The line is kept as a hint only.
local M = {}

-- crockford base32: no i/l/o/u, so ordinary words in parens are rarely mistaken for ids
local ALPHABET = "0123456789abcdefghjkmnpqrstvwxyz"
local ID_LEN = 9
local ID_PATTERN = string.rep("[0-9a-hjkmnp-tv-z]", ID_LEN)

local function tc_config()
  local ok, config = pcall(require, "todo-comments.config")
  if ok and config.loaded then
    return config
  end
end

--- Raw keyword -> canonical keyword (FIXME -> FIX), as todo-comments sees it.
---@return table<string, string>
function M.keywords()
  local config = tc_config()
  return config and config.keywords or {}
end

---@param opts table plugin options
---@param keyword string raw keyword
function M.is_anchor_keyword(opts, keyword)
  local canonical = M.keywords()[keyword]
  if not canonical then
    return false
  end
  return opts.keywords == nil or vim.tbl_contains(opts.keywords, canonical) or vim.tbl_contains(opts.keywords, keyword)
end

---@param message string
---@return string
function M.normalize(message)
  message = message:gsub("%s*%*/%s*$", ""):gsub("%s*%-%->%s*$", "")
  message = message:gsub("%s+", " ")
  return vim.trim(message)
end

---@param id? string
---@return boolean
function M.is_id(id)
  return id ~= nil and id:match("^" .. ID_PATTERN .. "$") ~= nil
end

--- Random anchor id, retried while `taken(id)` says it is in use.
---@param taken? fun(id: string): boolean
---@return string
function M.new_id(taken)
  while true do
    local id = vim.uv.random(ID_LEN):gsub(".", function(c)
      local i = c:byte() % #ALPHABET + 1
      return ALPHABET:sub(i, i)
    end)
    if not (taken and taken(id)) then
      return id
    end
  end
end

--- Split a line around its keyword: text up to and including the keyword, and
--- whatever follows the keyword's colon.
---@param text string
---@return string? keyword, string? head, string? rest
local function split(text)
  if not tc_config() then
    return nil
  end
  local start, _, kw = require("todo-comments.highlight").match(text)
  if not start or not kw then
    return nil
  end
  local kw_start, kw_end = text:find(kw, start, true)
  if not kw_start then
    return nil
  end
  local rest = text:sub(kw_end + 1):gsub("^%s*:%s*", "")
  return kw, text:sub(1, kw_end), rest
end

---@class anchors.Parsed
---@field keyword string raw keyword as written
---@field id? string id embedded in the comment, "(id)" right after the keyword
---@field message string normalized text after the keyword (and id)
---@field title string "KEYWORD: message"

--- Parse a single line of text into an anchor, or nil.
---@param text string
---@return anchors.Parsed?
function M.parse(text)
  local kw, _, rest = split(text)
  if not kw then
    return nil
  end
  local id, after = rest:match("^%((" .. ID_PATTERN .. ")%)%s*(.*)$")
  local message = M.normalize(id and after or rest)
  return { keyword = kw, id = id, message = message, title = kw .. ": " .. message }
end

--- `text` with "(id)" inserted after its keyword.
---@param text string
---@param id string
---@return string?
function M.tag_text(text, id)
  local kw, head, rest = split(text)
  if not kw then
    return nil
  end
  return head .. ": (" .. id .. ")" .. (rest == "" and "" or " " .. rest)
end

---@param path string repo relative path
---@param parsed anchors.Parsed
---@param occurrence integer 1 for the first identical anchor in the file, 2 for the next...
---@return string
function M.fingerprint(path, parsed, occurrence)
  local parts = { path, parsed.keyword, parsed.message }
  if occurrence > 1 then
    table.insert(parts, tostring(occurrence))
  end
  return vim.fn.sha256(table.concat(parts, "\n")):sub(1, 12)
end

---@class anchors.Anchor: anchors.Parsed
---@field id string embedded id, or the content fingerprint when untagged
---@field tagged boolean whether `id` is embedded in the comment
---@field path string repo relative path
---@field abs string absolute path on this machine (never stored)
---@field lnum integer

--- Build anchors from (abs path, lnum, text) triples, assigning occurrence indexes.
---@param root string
---@param items {abs: string, lnum: integer, text: string}[]
---@param opts table plugin options
---@return anchors.Anchor[]
function M.build(root, items, opts)
  table.sort(items, function(a, b)
    if a.abs ~= b.abs then
      return a.abs < b.abs
    end
    return a.lnum < b.lnum
  end)
  local seen = {}
  local anchors = {}
  for _, item in ipairs(items) do
    local parsed = M.parse(item.text)
    local rel = vim.fs.relpath(root, item.abs)
    if parsed and rel and M.is_anchor_keyword(opts, parsed.keyword) then
      local key = table.concat({ rel, parsed.keyword, parsed.message }, "\n")
      seen[key] = (seen[key] or 0) + 1
      local anchor = vim.tbl_extend("force", parsed, {
        path = rel,
        abs = item.abs,
        lnum = item.lnum,
      })
      anchor.tagged = parsed.id ~= nil
      anchor.id = parsed.id or M.fingerprint(rel, parsed, seen[key])
      table.insert(anchors, anchor)
    end
  end
  return anchors
end

--- Write `id` into an untagged anchor's comment: into its buffer when loaded
--- (saved only if it had no unsaved changes), straight to disk otherwise.
--- On success `a` becomes tagged with `id`.
---@param a anchors.Anchor
---@param id string
---@return boolean ok
function M.write_tag(a, id)
  local buf = vim.fn.bufnr(a.abs)
  local loaded = buf ~= -1 and vim.api.nvim_buf_is_loaded(buf)
  local lines = loaded and vim.api.nvim_buf_get_lines(buf, 0, -1, false) or vim.fn.readfile(a.abs, "b")
  local text = lines[a.lnum]
  -- the line must still hold this exact anchor
  local parsed = text and M.parse(text)
  if not parsed or parsed.id or parsed.keyword ~= a.keyword or parsed.message ~= a.message then
    return false
  end
  local tagged = M.tag_text(text, id)
  if loaded then
    local was_modified = vim.bo[buf].modified
    vim.api.nvim_buf_set_lines(buf, a.lnum - 1, a.lnum, false, { tagged })
    if not was_modified then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent noautocmd write")
      end)
    end
  else
    lines[a.lnum] = tagged
    if vim.fn.writefile(lines, a.abs, "b") ~= 0 then
      return false
    end
  end
  a.id, a.tagged = id, true
  return true
end

--- Anchor closest to line `lnum` (1-based) of buffer `buf`, within `radius` lines.
--- Ties go to the anchor above, since comments usually sit above the code they describe.
---@param buf integer
---@param lnum integer
---@param opts table
---@param radius? integer defaults to 0 (exact line only)
---@return anchors.Anchor?, string? root
function M.near(buf, lnum, opts, radius)
  radius = radius or 0
  local abs = vim.api.nvim_buf_get_name(buf)
  local root = require("anchors.repo").root(abs)
  if abs == "" or not root then
    return nil
  end
  -- read from the top so occurrence indexes match a full scan
  local items = {}
  for i, text in ipairs(vim.api.nvim_buf_get_lines(buf, 0, lnum + radius, false)) do
    table.insert(items, { abs = abs, lnum = i, text = text })
  end
  local best, best_dist
  for _, anchor in ipairs(M.build(root, items, opts)) do
    local dist = math.abs(anchor.lnum - lnum)
    if dist <= radius and (not best or dist < best_dist or (dist == best_dist and anchor.lnum < best.lnum)) then
      best, best_dist = anchor, dist
    end
  end
  if best then
    return best, root
  end
end

--- Anchor exactly on line `lnum` (1-based) of buffer `buf`, or nil.
---@param buf integer
---@param lnum integer
---@param opts table
---@return anchors.Anchor?, string? root
function M.at(buf, lnum, opts)
  return M.near(buf, lnum, opts, 0)
end

--- Scan a directory with todo-comments' ripgrep search. Results are grouped by the
--- git repo each file lives in; files outside a repo are not anchors and are dropped.
---@param dir string
---@param opts table
---@param cb fun(groups: table<string, anchors.Anchor[]>) repo root -> anchors
function M.scan(dir, opts, cb)
  if not tc_config() then
    vim.notify("anchors: todo-comments is not loaded", vim.log.levels.ERROR)
    return
  end
  local repo = require("anchors.repo")
  require("todo-comments.search").search(function(results)
    local roots, by_root = {}, {}
    for _, r in ipairs(results) do
      local abs = vim.fs.normalize(vim.fn.fnamemodify(r.filename, ":p"))
      local parent = vim.fs.dirname(abs)
      if roots[parent] == nil then
        roots[parent] = repo.root(abs) or false
      end
      local root = roots[parent]
      if root then
        by_root[root] = by_root[root] or {}
        table.insert(by_root[root], { abs = abs, lnum = r.lnum, text = r.line })
      end
    end
    local groups = {}
    for root, items in pairs(by_root) do
      groups[root] = M.build(root, items, opts)
    end
    cb(groups)
  end, { cwd = dir, disable_not_found_warnings = true })
end

return M
