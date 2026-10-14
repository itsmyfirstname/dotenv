-- Reconnect orphaned entries to an unlinked anchor: the comment lost its "(id)",
-- or an untagged comment was edited or its file moved/renamed. The entry keeps
-- its body; an untagged anchor gets the entry's id written into it.
local anchor = require("anchors.anchor")

local M = {}

-- candidates scoring below this are not offered
M.threshold = 0.3

local function tokens(text)
  local set = {}
  for word in text:lower():gmatch("%w+") do
    set[word] = true
  end
  return set
end

local function jaccard(a, b)
  local inter, union = 0, 0
  for k in pairs(a) do
    union = union + 1
    if b[k] then
      inter = inter + 1
    end
  end
  for k in pairs(b) do
    if not a[k] then
      union = union + 1
    end
  end
  return union == 0 and 0 or inter / union
end

--- Message an entry was created from, recovered from its stored title.
---@param entry table
---@return string
function M.entry_message(entry)
  local title = entry.title or ""
  local kw = entry.keyword or ""
  if title:sub(1, #kw + 1) == kw .. ":" then
    title = title:sub(#kw + 2)
  end
  return anchor.normalize(title)
end

---@param entry table orphaned entry metadata
---@param a anchors.Anchor unlinked anchor
---@return number score, boolean exact
function M.score(entry, a)
  local keywords = anchor.keywords()
  local same_kw = (keywords[entry.keyword] or entry.keyword) == (keywords[a.keyword] or a.keyword)
  local message = M.entry_message(entry)
  if same_kw and message == a.message then
    -- identical comment, only the path or occurrence changed
    return 2, true
  end
  local score = jaccard(tokens(message), tokens(a.message))
  if same_kw then
    score = score + 0.1
  end
  if entry.path == a.path then
    score = score + 0.25
    local line = tonumber(entry.line)
    if line then
      score = score + 0.1 * math.max(0, 1 - math.abs(line - a.lnum) / 50)
    end
  end
  return score, false
end

---@param entry table
---@param pool anchors.Anchor[]
---@return {anchor: anchors.Anchor, score: number, exact: boolean}[]
function M.candidates(entry, pool)
  local out = {}
  for _, a in ipairs(pool) do
    local score, exact = M.score(entry, a)
    if score >= M.threshold then
      table.insert(out, { anchor = a, score = score, exact = exact })
    end
  end
  table.sort(out, function(x, y)
    return x.score > y.score
  end)
  return vim.list_slice(out, 1, 10)
end

--- Walk orphans: unique exact matches relink silently, the rest prompt.
---@param orphans table[] entries
---@param pool anchors.Anchor[] unlinked anchors, consumed as they get claimed
---@param apply fun(entry: table, a: anchors.Anchor)
---@param done fun(stats: {auto: integer, picked: integer, skipped: integer})
function M.run(orphans, pool, apply, done)
  local stats = { auto = 0, picked = 0, skipped = 0 }

  local function claim(entry, a)
    for i, p in ipairs(pool) do
      if p == a then
        table.remove(pool, i)
        break
      end
    end
    apply(entry, a)
  end

  local prompted = {}
  for _, entry in ipairs(orphans) do
    local cands = M.candidates(entry, pool)
    local exact = vim.tbl_filter(function(c)
      return c.exact
    end, cands)
    if #exact == 1 then
      claim(entry, exact[1].anchor)
      stats.auto = stats.auto + 1
    else
      table.insert(prompted, entry)
    end
  end

  local function step(i)
    local entry = prompted[i]
    if not entry then
      return done(stats)
    end
    local cands = M.candidates(entry, pool)
    if #cands == 0 then
      stats.skipped = stats.skipped + 1
      return step(i + 1)
    end
    local prompt = ("Relink ✗ %s (%s:%s)"):format(entry.title or entry.id, entry.path or "?", entry.line or "?")
    vim.ui.select(cands, {
      prompt = prompt,
      format_item = function(c)
        return ("%3d%%  %s:%d  %s"):format(math.min(100, math.floor(c.score * 100)), c.anchor.path, c.anchor.lnum, c.anchor.title)
      end,
    }, function(choice)
      if choice then
        claim(entry, choice.anchor)
        stats.picked = stats.picked + 1
      else
        stats.skipped = stats.skipped + 1
      end
      -- let the previous select window close before opening the next
      vim.schedule(function()
        step(i + 1)
      end)
    end)
  end
  step(1)
end

return M
