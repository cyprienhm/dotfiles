local M = {}

M._keys = nil

function M.get()
	if M._keys then
		return M._keys
	end
  -- stylua: ignore
	M._keys = {
		{ "gd", Snacks.picker.lsp_definitions, desc = "Goto Definition" },
		{ "grr", Snacks.picker.lsp_references, desc = "References", nowait = true },
		{ "gI", Snacks.picker.lsp_implementations, desc = "Goto Implementation" },
		{ "gy", Snacks.picker.lsp_type_definitions, desc = "Goto T[y]pe Definition" },
		{ "gD", Snacks.picker.lsp_declarations, desc = "Goto Declaration" },
		{ "gK", function() return vim.lsp.buf.signature_help() end, desc = "Signature Help", has = "signatureHelp", },
		{ "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = "codeLens" },
		{ "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", mode = { "n" }, has = "codeLens", },
		{ "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", mode = { "n" }, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" }, },
		{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
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
