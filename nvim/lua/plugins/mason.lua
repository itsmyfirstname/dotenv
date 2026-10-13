return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      -- lspconfig server names (not Mason package names!)
      ensure_installed = {
        "basedpyright",
        "docker_compose_language_service",
        "gopls",
        "lua_ls",
      },
    },
  },
}

--[[
nvim-lspconfig (required, the workhorse)
 - The registry of launch recipes: for each server, what command to run, with what args, for which filetypes,
   with what default settings.
 - It also does the actual enabling: attaching the server to buffers, spawning the process, wiring up the LSP
   client.
 - Without it, nothing else works — even Mason's binaries would just be executables nothing knows how to
   launch.

 mason.nvim (package manager)
 - Downloads/installs/upgrades the binaries. It knows nothing about LSP at all — it happily manages non-LSP
   tools like your shfmt and stylua.

 mason-lspconfig (thin automation layer, optional)
 - Sits on top and calls the other two's APIs. Its entire job is two automations:
     1. "These servers should exist" → at startup, checks ensure_installed against what Mason has, installs
        the rest.
     2. "You opened a .go file" → maps filetype → lspconfig server name → calls lspconfig to enable it.
 - It contains no launch recipes of its own. It's plumbing, not the engine.
-- ]]
