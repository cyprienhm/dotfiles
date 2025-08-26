local servers = { "lua_ls", "pyright" }

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
	{
		"neovim/nvim-lspconfig",
		config = function(_, opts)
			vim.diagnostic.config(opts.diagnostics)

			local lspconfig = require("lspconfig")
			local keymaps = require("config.lsp_keymaps")

			local capabilities = vim.lsp.protocol.make_client_capabilities()

			for _, server in ipairs(servers) do
				local server_opts = {
					on_attach = keymaps.on_attach,
					capabilities = capabilities,
				}

				if server == "lua_ls" then
					server_opts.settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
						},
					}
				end

				lspconfig[server].setup(server_opts)
			end
		end,
		opts = {
			diagnostics = {
				underline = true,
				virtual_text = {
					spacing = 4,
					source = "if_many",
					prefix = "x",
				},
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.HINT] = "",
						[vim.diagnostic.severity.INFO] = "",
					},
					numhl = {
						[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
						[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
						[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
						[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
					},
				},
			},
		},
	},
}
