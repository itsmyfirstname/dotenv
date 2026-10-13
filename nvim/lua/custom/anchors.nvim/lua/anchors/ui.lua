local store = require("anchors.store")

local M = {}

local ICONS = { linked = "●", unlinked = "○", orphan = "✗" }

--- Open an entry file in a centered float. `q` saves and closes.
---@param file string
---@param ctx {title: string, footer?: string, line?: integer}
function M.open_entry(file, ctx)
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.7)
  local buf = vim.fn.bufadd(file)
  vim.bo[buf].buflisted = true
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. ctx.title .. " ",
    title_pos = "center",
    footer = ctx.footer and (" " .. ctx.footer .. " ") or nil,
    footer_pos = "right",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 2

  if not vim.b[buf].anchors_entry then
    vim.b[buf].anchors_entry = true
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = buf,
      desc = "anchors: refresh updated stamp",
      callback = function()
        store.touch(buf, vim.b[buf].anchors_hint)
      end,
    })
    vim.keymap.set("n", "q", "<cmd>silent update | close<cr>", { buffer = buf, desc = "Save and close entry" })
  end

  -- refreshed line hint is only written if the user saves the entry
  vim.b[buf].anchors_hint = ctx.line and { line = ctx.line } or nil

  -- land on the end of the body, ready to write
  vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
end

--- Jump to an anchor's source location in the current window.
---@param abs string
---@param lnum integer
function M.jump(abs, lnum)
  vim.cmd.edit(vim.fn.fnameescape(abs))
  pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
  vim.cmd("normal! zz")
end

---@class anchors.Row
---@field status "linked"|"unlinked"|"orphan"
---@field anchor? anchors.Anchor
---@field entry? table
---@field root string repo root on this machine
---@field repo string portable repo key
---@field show_repo? boolean prefix the repo key when listing several repos

---@param row anchors.Row
---@return string
function M.format(row)
  local prefix = ICONS[row.status] .. " " .. (row.show_repo and (row.repo .. "  ") or "")
  if row.anchor then
    local a = row.anchor
    return ("%s%s:%d  %s"):format(prefix, a.path, a.lnum, a.title)
  end
  local e = row.entry
  return ("%s%s:%s  %s"):format(prefix, e.path or "?", e.line or "?", e.title or e.id)
end

--- Pick from anchor rows. Telescope when available, vim.ui.select otherwise.
---@param rows anchors.Row[]
---@param handlers {open: fun(row: anchors.Row), jump: fun(row: anchors.Row), relink?: fun(row: anchors.Row)}
function M.pick(rows, handlers)
  local ok = pcall(require, "telescope")
  if not ok then
    vim.ui.select(rows, { prompt = "Anchors", format_item = M.format }, function(row)
      if row then
        handlers.open(row)
      end
    end)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = "Anchors  (<CR> entry, <C-o> source, <C-r> relink orphan)",
      finder = finders.new_table({
        results = rows,
        entry_maker = function(row)
          local preview_file, preview_lnum
          if row.entry and row.entry.file then
            preview_file, preview_lnum = row.entry.file, 1
          else
            preview_file, preview_lnum = row.anchor.abs, row.anchor.lnum
          end
          return {
            value = row,
            display = M.format(row),
            ordinal = M.format(row),
            filename = preview_file,
            lnum = preview_lnum,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.grep_previewer({}),
      attach_mappings = function(prompt_bufnr, map)
        local function with(fn)
          return function()
            local selected = state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selected then
              fn(selected.value)
            end
          end
        end
        actions.select_default:replace(with(handlers.open))
        map({ "i", "n" }, "<C-o>", with(handlers.jump))
        if handlers.relink then
          map({ "i", "n" }, "<C-r>", with(handlers.relink))
        end
        return true
      end,
    })
    :find()
end

return M
