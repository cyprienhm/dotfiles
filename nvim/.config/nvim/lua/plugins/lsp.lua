local servers = { "lua_ls", "pyright", "pyrefly", "ast_grep", "ts_ls", "marksman", "stylua" }

vim.lsp.config["pyright"] = require("plugins.lspconfigs.pyright")
vim.lsp.config["pyrefly"] = require("plugins.lspconfigs.pyrefly")
vim.lsp.enable("pyrefly")

vim.diagnostic.config({ virtual_text = true })

return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = servers,
			})
		end,
	},
}
