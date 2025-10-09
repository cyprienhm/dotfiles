local M = {}

M._keys = nil

function M.get()
	if M._keys then
		return M._keys
	end
  -- stylua: ignore
	M._keys = {
		{ "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", mode = { "n" }, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" }, },
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
