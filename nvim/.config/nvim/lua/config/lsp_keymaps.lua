local M = {}

M._keys = nil

function M.get()
	if M._keys then
		return M._keys
	end

	M._keys = {
		{
			"<leader>cl",
			function()
				Snacks.picker.lsp_config()
			end,
			desc = "Lsp Info",
		},
		{ "gd", Snacks.picker.lsp_definitions, desc = "Goto Definition" },
		{ "grr", Snacks.picker.lsp_references, desc = "References", nowait = true },
		{ "gI", Snacks.picker.lsp_implementations, desc = "Goto Implementation" },
		{ "gy", Snacks.picker.lsp_type_definitions, desc = "Goto T[y]pe Definition" },
		{ "gD", Snacks.picker.lsp_declarations, desc = "Goto Declaration" },
		{
			"K",
			function()
				return vim.lsp.buf.hover()
			end,
			desc = "Hover",
		},
		{
			"gK",
			function()
				return vim.lsp.buf.signature_help()
			end,
			desc = "Signature Help",
			has = "signatureHelp",
		},
		{ "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = "codeLens" },
		{
			"<leader>cC",
			vim.lsp.codelens.refresh,
			desc = "Refresh & Display Codelens",
			mode = { "n" },
			has = "codeLens",
		},
		{
			"<leader>cR",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File",
			mode = { "n" },
			has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
		},
		{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
		{
			"]]",
			function()
				Snacks.words.jump(vim.v.count1)
			end,
			has = "documentHighlight",
			desc = "Next Reference",
			cond = function()
				return Snacks.words.is_enabled()
			end,
		},
		{
			"[[",
			function()
				Snacks.words.jump(-vim.v.count1)
			end,
			has = "documentHighlight",
			desc = "Prev Reference",
			cond = function()
				return Snacks.words.is_enabled()
			end,
		},
		{
			"<a-n>",
			function()
				Snacks.words.jump(vim.v.count1, true)
			end,
			has = "documentHighlight",
			desc = "Next Reference",
			cond = function()
				return Snacks.words.is_enabled()
			end,
		},
		{
			"<a-p>",
			function()
				Snacks.words.jump(-vim.v.count1, true)
			end,
			has = "documentHighlight",
			desc = "Prev Reference",
			cond = function()
				return Snacks.words.is_enabled()
			end,
		},
	}

	return M._keys
end

function M.on_attach(client, buffer)
	for _, keys in pairs(M.get()) do
		local opts = { buffer = buffer, desc = keys.desc, silent = true }
		vim.keymap.set(keys.mode or "n", keys[1], keys[2], opts)
	end
end

return M
