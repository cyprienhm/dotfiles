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
