-- mason-tool-installer only accepts mason names
local servers = {
	"lua-language-server",
	"pyright",
	"pyrefly",
	"ast-grep",
	"typescript-language-server",
	"marksman",
	"stylua",
	"ruff",
}

-- configs will automatically be read from lsp/. use these names
vim.lsp.enable("pyrefly")
vim.lsp.enable("ruff")
vim.lsp.enable("lua_ls")
vim.lsp.enable("ast_grep")
vim.lsp.enable("ts_ls")
vim.lsp.enable("marksman")

vim.diagnostic.config({
	severity_sort = true,
	float = { border = "rounded", source = true },
	underline = { severity = vim.diagnostic.severity.ERROR },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
	},
	virtual_text = {
		source = true,
		spacing = 2,
		format = function(diagnostic)
			local diagnostic_message = {
				[vim.diagnostic.severity.ERROR] = diagnostic.message,
				[vim.diagnostic.severity.WARN] = diagnostic.message,
				[vim.diagnostic.severity.INFO] = diagnostic.message,
				[vim.diagnostic.severity.HINT] = diagnostic.message,
			}
			return diagnostic_message[diagnostic.severity]
		end,
	},
})

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
