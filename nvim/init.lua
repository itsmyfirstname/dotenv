-- This is also a good place to setup other settings (vim.opt)

-- Share local buffer and global leader
-- Make sure to setup `mapleader` and `maplocalleader` before
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Case insensitive searching
vim.o.ignorecase = true
vim.o.smartcase = true

-- Should enable Jetbrains Font I have installed
-- TODO: Fix this, the jetbrains font should show
-- this a a symbol: >= not a > then =
vim.g.have_nerd_font = true

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [q]uickfix list" })

-- Sometime hints, warnings, errors etc, are too long to fit on the scren
--   this pops the diagnostic message into a hovering window for easier reading
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "[p]op open diagnostic window" })

-- Anchors (lua/custom/anchors.nvim): markdown entries attached to TODO/NOTE/FIX comments
vim.keymap.set("n", "<leader>aa", "<cmd>Anchor new<cr>", { desc = "[a]nchors: [a]dd anchor + entry" })
vim.keymap.set("n", "<leader>as", "<cmd>Anchor scan<cr>", { desc = "[a]nchors: [s]can current repo" })
-- prefilled, not executed: edit the path (defaults to home) and press enter
vim.keymap.set("n", "<leader>aS", ":Anchor scan ~", { desc = "[a]nchors: [S]can a location (default ~)" })
vim.keymap.set("n", "<leader>ae", "<cmd>Anchor edit<cr>", { desc = "[a]nchors: [e]dit entry under cursor" })
vim.keymap.set("n", "<leader>ai", "<cmd>Anchor import<cr>", { desc = "[a]nchors: [i]mport anchor near cursor" })
vim.keymap.set("n", "<leader>aI", "<cmd>Anchor import all<cr>", { desc = "[a]nchors: [I]mport all unlinked anchors" })
vim.keymap.set("n", "<leader>ar", "<cmd>Anchor relink<cr>", { desc = "[a]nchors: [r]elink orphaned entries" })

require("config.lazy")
