local M = {}

function M.git_root()
	local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
	return root ~= "" and root or vim.fn.getcwd()
end

return M
