-- anchors: markdown knowledge entries attached to todo-comments anchors.
local anchor = require("anchors.anchor")
local relink = require("anchors.relink")
local repo = require("anchors.repo")
local store = require("anchors.store")
local ui = require("anchors.ui")

local M = {}

M.opts = {
  -- where entries live; make it a git repo to share/sync it
  store = "~/.anchors",
  -- canonical todo-comments keywords that count as anchors, nil = all of them
  keywords = nil,
}

local function warn(msg)
  vim.notify("anchors: " .. msg, vim.log.levels.WARN)
end

---@param a anchors.Anchor
---@param root string
local function open_anchor(a, root)
  local file = store.ensure(M.opts, repo.key(root), a)
  ui.open_entry(file, { title = a.title, footer = ("%s:%d"):format(a.path, a.lnum), line = a.lnum })
end

--- Open (creating if needed) the entry for the anchor under the cursor.
function M.edit()
  local a, root = anchor.at(0, vim.api.nvim_win_get_cursor(0)[1], M.opts)
  if not a then
    return warn("no anchor on this line (must be a keyword comment in a file inside a git repo)")
  end
  open_anchor(a, root)
end

--- Keywords offered when creating a new anchor.
---@return string[]
function M.anchor_keywords()
  local config = require("todo-comments.config")
  local kws = M.opts.keywords or vim.tbl_keys(config.options.keywords)
  table.sort(kws)
  return kws
end

--- Prompt for a keyword and title, insert the comment above the cursor and open its entry.
function M.new()
  local buf = vim.api.nvim_get_current_buf()
  if not repo.root(vim.api.nvim_buf_get_name(buf)) then
    return warn("buffer is not inside a git repo")
  end
  vim.ui.select(M.anchor_keywords(), { prompt = "Anchor keyword" }, function(kw)
    if not kw then
      return
    end
    vim.ui.input({ prompt = kw .. ": " }, function(title)
      if not title or vim.trim(title) == "" then
        return
      end
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local current = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
      local indent = current:match("^%s*")
      local cs = vim.bo[buf].commentstring ~= "" and vim.bo[buf].commentstring or "# %s"
      local text = kw .. ": " .. anchor.normalize(title)
      local line = indent .. cs:gsub("%%s", function()
        return text
      end)
      vim.api.nvim_buf_set_lines(buf, row - 1, row - 1, false, { line })
      vim.api.nvim_win_set_cursor(0, { row, #line })
      local a, root = anchor.at(buf, row, M.opts)
      if not a then
        return warn("inserted comment was not recognised as an anchor: " .. line)
      end
      open_anchor(a, root)
    end)
  end)
end

--- Scan the repo and pair anchors with stored entries.
---@param cb fun(rows: anchors.Row[], root: string)
local function collect(cb)
  local root = repo.root()
  if not root then
    return warn("not inside a git repo")
  end
  anchor.scan(root, M.opts, function(anchors)
    local entries = store.list(M.opts, repo.key(root))
    local rows = {}
    for _, a in ipairs(anchors) do
      local entry = entries[a.id]
      entries[a.id] = nil
      table.insert(rows, { status = entry and "linked" or "unlinked", anchor = a, entry = entry })
    end
    -- whatever is left has lost its anchor (comment edited, moved or deleted)
    for _, entry in pairs(entries) do
      table.insert(rows, { status = "orphan", entry = entry })
    end
    cb(rows, root)
  end)
end

--- Reconnect orphaned entries to unlinked anchors.
---@param only? table restrict to this single orphaned entry
function M.relink(only)
  collect(function(rows, root)
    local key = repo.key(root)
    local orphans, pool = {}, {}
    for _, row in ipairs(rows) do
      if row.status == "orphan" and (not only or row.entry.id == only.id) then
        table.insert(orphans, row.entry)
      elseif row.status == "unlinked" then
        table.insert(pool, row.anchor)
      end
    end
    if #orphans == 0 then
      return vim.notify("anchors: no orphaned entries")
    end
    relink.run(orphans, pool, function(entry, a)
      local _, err = store.move(M.opts, key, entry, a)
      if err then
        warn(("could not relink %s: %s"):format(entry.id, err))
      end
    end, function(stats)
      vim.notify(("anchors: relinked %d automatically, %d picked, %d left orphaned"):format(stats.auto, stats.picked, stats.skipped))
    end)
  end)
end

--- Picker over every anchor in the repo plus orphaned entries.
function M.scan()
  collect(function(rows, root)
    if #rows == 0 then
      return warn("no anchors found in " .. root)
    end
    ui.pick(rows, {
      open = function(row)
        if row.anchor then
          return open_anchor(row.anchor, root)
        end
        ui.open_entry(row.entry.file, { title = row.entry.title or row.entry.id, footer = "orphaned" })
      end,
      jump = function(row)
        if row.anchor then
          return ui.jump(row.anchor.abs, row.anchor.lnum)
        end
        local abs = row.entry.path and vim.fs.joinpath(root, row.entry.path)
        if not abs or not vim.uv.fs_stat(abs) then
          return warn("orphaned entry's source no longer exists: " .. tostring(row.entry.path))
        end
        ui.jump(abs, tonumber(row.entry.line) or 1)
      end,
      relink = function(row)
        if row.status ~= "orphan" then
          return warn("only orphaned (✗) entries can be relinked")
        end
        M.relink(row.entry)
      end,
    })
  end)
end

--- Create entries for every anchor in the repo that does not have one.
function M.import()
  collect(function(rows, root)
    local pending = vim.tbl_filter(function(row)
      return row.status == "unlinked"
    end, rows)
    if #pending == 0 then
      return vim.notify("anchors: every anchor already has an entry")
    end
    local choice = vim.fn.confirm(("Create %d entries for %s?"):format(#pending, repo.key(root)), "&Yes\n&No", 2)
    if choice ~= 1 then
      return
    end
    for _, row in ipairs(pending) do
      store.ensure(M.opts, repo.key(root), row.anchor)
    end
    vim.notify(("anchors: imported %d entries into %s"):format(#pending, store.dir(M.opts, repo.key(root))))
  end)
end

--- Register a new keyword with todo-comments (highlighting + search) at runtime.
---@param name string
---@param kw_opts? table todo-comments keyword options (icon, color, alt)
function M.add_keyword(name, kw_opts)
  name = name:upper()
  local config = require("todo-comments.config")
  local tc_opts = vim.deepcopy(config._options or {})
  tc_opts.keywords = tc_opts.keywords or {}
  tc_opts.keywords[name] = kw_opts or { icon = " ", color = "hint" }
  require("todo-comments").setup(tc_opts)
  if M.opts.keywords and not vim.tbl_contains(M.opts.keywords, name) then
    table.insert(M.opts.keywords, name)
  end
  vim.notify("anchors: added keyword " .. name)
end

local subcommands = {
  scan = M.scan,
  new = M.new,
  edit = M.edit,
  import = M.import,
  relink = function()
    M.relink()
  end,
  keyword = function(args)
    if not args[1] then
      return warn("usage: :Anchor keyword NAME")
    end
    M.add_keyword(args[1])
  end,
}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

  vim.api.nvim_create_user_command("Anchor", function(cmd)
    local name = cmd.fargs[1] or "scan"
    local fn = subcommands[name]
    if not fn then
      return warn("unknown subcommand " .. name)
    end
    fn(vim.list_slice(cmd.fargs, 2))
  end, {
    nargs = "*",
    desc = "Anchored knowledge entries",
    complete = function(_, line)
      if #vim.split(line, "%s+") > 2 then
        return {}
      end
      return vim.tbl_keys(subcommands)
    end,
  })
end

return M
