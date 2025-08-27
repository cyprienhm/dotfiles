return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			python = { "ruff_format", "ruff_organize_imports" },
			lua = { "stylua" },
			fish = { "fish_indent" },
			sh = { "beautysh" },
			zsh = { "beautysh" },
			go = { "gofmt" },
			html = { "prettier" },
			htmldjango = { "prettier" },
			htmlangular = { "prettier" },
			css = { "prettier" },
			json = { "prettier" },
			jsonc = { "prettier" },
			md = { "prettier" },
			yaml = { "prettier" },
			javascript = { "prettier" },
		},
	},
}
