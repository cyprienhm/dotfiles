-- mason-tool-installer only accepts mason names
local servers =
	{ "lua-language-server", "pyright", "pyrefly", "ast-grep", "typescript-language-server", "marksman", "stylua" }

-- configs will automatically be read from lsp/. use these names
vim.lsp.enable("pyrefly")
vim.lsp.enable("lua_ls")
vim.lsp.enable("ast_grep")
vim.lsp.enable("ts_ls")
vim.lsp.enable("marksman")

vim.diagnostic.config({ virtual_text = true })

return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = servers,
			})
		end,
	},
}
