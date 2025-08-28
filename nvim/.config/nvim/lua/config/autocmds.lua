local function augroup(name)
	return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
})

local function maybe_format(bufnr)
	if vim.b.autoformat ~= false then
		require("conform").format({ bufnr = bufnr })
	end
end

vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("format_on_save"),
	pattern = "*",
	callback = function(args)
		maybe_format(args.buf)
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local buffer = args.buf ---@type number
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		require("config.lsp_keymaps").on_attach(client, buffer)
	end,
})
