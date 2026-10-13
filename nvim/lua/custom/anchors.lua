return {
  {
    -- local plugin: knowledge entries pinned to todo-comments anchors
    -- keymaps live in init.lua, they lazy load this through the :Anchor command
    dir = vim.fn.stdpath("config") .. "/lua/custom/anchors.nvim",
    name = "anchors",
    dependencies = { "folke/todo-comments.nvim", "nvim-telescope/telescope.nvim" },
    cmd = "Anchor",
    opts = {
      store = "~/.anchors",
      -- keywords = { "TODO", "FIX", "NOTE" }, -- limit which keywords count as anchors
    },
  },
}
