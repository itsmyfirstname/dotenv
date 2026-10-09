-- An anchor is a todo-comments style comment ("TODO: ...", "NOTE: ...").
-- Its fingerprint is derived only from portable data:
--   repo relative path + keyword + normalized message + occurrence index
-- Line numbers are deliberately left out: they shift on every edit above the
-- comment, which would orphan the entry. The line is kept as a hint only.
local M = {}

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

---@class anchors.Parsed
---@field keyword string raw keyword as written
---@field message string normalized text after the keyword
---@field title string "KEYWORD: message"

--- Parse a single line of text into an anchor, or nil.
---@param text string
---@return anchors.Parsed?
function M.parse(text)
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
  local message = M.normalize(text:sub(kw_end + 1):gsub("^%s*:%s*", ""))
  return { keyword = kw, message = message, title = kw .. ": " .. message }
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
---@field id string
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
      anchor.id = M.fingerprint(rel, parsed, seen[key])
      table.insert(anchors, anchor)
    end
  end
  return anchors
end

--- Anchor on line `lnum` (1-based) of buffer `buf`, or nil.
---@param buf integer
---@param lnum integer
---@param opts table
---@return anchors.Anchor?, string? root
function M.at(buf, lnum, opts)
  local abs = vim.api.nvim_buf_get_name(buf)
  local root = require("anchors.repo").root(abs)
  if abs == "" or not root then
    return nil
  end
  local items = {}
  for i, text in ipairs(vim.api.nvim_buf_get_lines(buf, 0, lnum, false)) do
    table.insert(items, { abs = abs, lnum = i, text = text })
  end
  for _, anchor in ipairs(M.build(root, items, opts)) do
    if anchor.lnum == lnum then
      return anchor, root
    end
  end
end

--- Scan a repo with todo-comments' ripgrep search.
---@param root string
---@param opts table
---@param cb fun(anchors: anchors.Anchor[])
function M.scan(root, opts, cb)
  if not tc_config() then
    vim.notify("anchors: todo-comments is not loaded", vim.log.levels.ERROR)
    return
  end
  require("todo-comments.search").search(function(results)
    local items = {}
    for _, r in ipairs(results) do
      table.insert(items, { abs = vim.fs.normalize(vim.fn.fnamemodify(r.filename, ":p")), lnum = r.lnum, text = r.line })
    end
    cb(M.build(root, items, opts))
  end, { cwd = root, disable_not_found_warnings = true })
end

return M
