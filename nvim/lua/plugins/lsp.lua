-- return {}
-- Install + enabling is handled by mason-lspconfig (see mason.lua).
-- Put per-server overrides here, e.g.:

return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })
    end,
  },
}
