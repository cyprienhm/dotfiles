-- keymaps
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set
-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bd", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
	vim.cmd("noh")
	return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map(
	"n",
	"<leader>ur",
	"<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
	{ desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- windows
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- diagnostics
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next Diagnostic" })
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous Diagnostic" })
map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next Error" })
map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Previous Error" })

vim.keymap.set("n", "<leader>fo", function()
	require("oil").open()
end, { desc = "Open Oil", noremap = true, silent = true })

-- toggle function
local function toggle_buffer_format()
	if vim.b.autoformat == nil then
		vim.b.autoformat = false
	else
		vim.b.autoformat = not vim.b.autoformat
	end
	vim.notify("Buffer format " .. (vim.b.autoformat and "enabled" or "disabled"))
end
map("n", "<leader>uf", toggle_buffer_format, { desc = "Toggle buffer format" })

map("n", "<leader>uw", "<cmd>set wrap!<cr>", { desc = "Toggle wrap" })

map("n", "<leader>fY", function()
	local filepath = vim.api.nvim_buf_get_name(0)
	vim.fn.setreg("+", filepath)
	vim.notify("Yanked: " .. filepath)
end, { desc = "Yank full path" })

map("n", "<leader>fy", function()
	local cwd = vim.uv.cwd()
	local buf = vim.api.nvim_buf_get_name(0)
	local filepath = vim.fn.fnamemodify(buf, ":." .. cwd)

	vim.fn.setreg("+", filepath)
	vim.notify("Yanked: " .. filepath)
end, { desc = "Yank relative path" })

local function git_root()
	local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
	return root ~= "" and root or vim.fn.getcwd()
end

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

local function maybe_format(bufnr)
	if vim.b.autoformat ~= false then
		require("conform").format({ bufnr = bufnr })
	end
end

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("format_on_save", { clear = true }),
	pattern = "*",
	callback = function(args)
		maybe_format(args.buf)
	end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = vim.fn.expand("~/notes") .. "/*",
	callback = function()
		vim.opt_local.textwidth = 80
		vim.opt_local.formatoptions:append("t")
	end,
})

-- options
vim.b.autoformat = true
local opt = vim.opt

opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 2 -- Size of an indent
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.number = true -- Print line number
opt.relativenumber = true -- Relative line numbers
opt.wrap = false -- Disable line wrap
opt.splitbelow = true -- Put new windows below current
opt.splitright = true -- Put new windows right of current
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
opt.undofile = true
opt.undolevels = 10000
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.signcolumn = "yes"
opt.foldlevel = 99
opt.smoothscroll = true
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldmethod = "expr"
opt.foldtext = "" -- text displayed on closed fold
opt.foldcolumn = "auto"
opt.showmode = false
opt.ignorecase = true
opt.smartcase = true
opt.winborder = "rounded"
opt.grepprg = "rg --vimgrep"

vim.pack.add({
	{ src = "https://github.com/folke/snacks.nvim" },
	{ src = "https://github.com/folke/lazydev.nvim" },
	{ src = "https://github.com/rose-pine/neovim", name = "rose-pine" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
	{ src = "https://github.com/williamboman/mason.nvim" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
}, { confirm = false })

require("lazydev").setup()

-- mason-tool-installer only accepts mason names
local servers = {
	"lua-language-server",
	"basedpyright",
	"ast-grep",
	"typescript-language-server",
	"svelte-language-server",
	"marksman",
	"stylua",
	"ruff",
	"tinymist",
	"beautysh",
	"css-lsp",
}

require("mason").setup()
require("mason-tool-installer").setup({
	ensure_installed = servers,
})

-- configs will automatically be read from lsp/. use these names
vim.lsp.enable("basedpyright")
vim.lsp.enable("ruff")
vim.lsp.enable("lua_ls")
vim.lsp.enable("ast_grep")
vim.lsp.enable("ts_ls")
vim.lsp.enable("svelte")
vim.lsp.enable("marksman")
vim.lsp.enable("tinymist")
vim.lsp.enable("cssls")

vim.diagnostic.config({
	severity_sort = true,
	float = { border = "rounded", source = true },
	underline = { severity = vim.diagnostic.severity.ERROR },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "x",
			[vim.diagnostic.severity.WARN] = "!",
			[vim.diagnostic.severity.INFO] = "i",
			[vim.diagnostic.severity.HINT] = "󰌶",
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

require("rose-pine").setup({ styles = { transparency = true } })
vim.cmd.colorscheme("rose-pine-moon")

require("oil").setup({
	default_file_explorer = true,
	columns = { "icon", "size", "mtime" },
	keymaps = {
		["<C-v>"] = { "actions.select", opts = { vertical = true } },
		["<C-s>"] = { "actions.select", opts = { horizontal = true } },
		["<C-h>"] = {},
		["gS"] = { "actions.change_sort", mode = "n" },
	},
	lsp_file_methods = {
		-- Enable or disable LSP file operations
		enabled = true,
		-- Time to wait for LSP file operations to complete before skipping
		timeout_ms = 10000,
		-- Set to true to autosave buffers that are updated with LSP willRenameFiles
		-- Set to "unmodified" to only save unmodified buffers
		autosave_changes = false,
	},
})

require("conform").setup({
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
		typescript = { "prettier" },
	},
})

require("snacks").setup({
	image = {},
	picker = {
		layout = {
			preview = false,
			layout = {
				position = "float",
				row = -2,
				col = 7,
				box = "horizontal",
				height = 0.6,
				width = 0.7,
				backdrop = false,
				{
					box = "vertical",
					border = "rounded",
					title = "",
					{ win = "input", height = 1, border = "bottom" },
					{ win = "list", border = "none", cursorline = false },
				},
				{ win = "preview", title = "{preview}", border = "rounded", width = 0.5 },
			},
		},
	},
	explorer = {},
	toggle = { map = vim.keymap.set },
	animate = { enabled = false },
	scroll = { enabled = false },
})

map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
map("n", "<leader><space>", function()
	Snacks.picker.smart()
end, { desc = "Find Files (Root Dir)" })
map("n", "<leader>sg", function()
	Snacks.picker.grep()
end, { desc = "Grep" })
map("n", "<leader>sk", function()
	Snacks.picker.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>sm", function()
	Snacks.picker.marks()
end, { desc = "Marks" })
map("n", "<leader>su", function()
	Snacks.picker.undo()
end, { desc = "Undotree" })
map("n", "<leader>sd", function()
	Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
map("n", "<leader>sD", function()
	Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer Diagnostics" })
map("n", "<leader>ss", function()
	Snacks.picker.lsp_symbols()
end, { desc = "LSP Symbols" })
map("n", "<leader>sS", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "LSP Workspace Symbols" })
map("n", "<leader>,", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>fe", function()
	Snacks.explorer({ cwd = git_root() })
end, { desc = "Explorer Snacks (root dir)" })
map("n", "<leader>fr", function()
	Snacks.picker.recent()
end, { desc = "Recent" })
map("n", "<leader>fR", function()
	Snacks.picker.recent({ filter = { cwd = true } })
end, { desc = "Recent (cwd)" })
map("n", "<leader>sl", function()
	Snacks.picker.resume()
end, { desc = "Last picker" })
map("n", "<leader>bo", function()
	Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>gg", function()
	Snacks.lazygit({ cwd = git_root() })
end, { desc = "Lazygit (Root Dir)" })
map("n", "<leader>gf", function()
	Snacks.picker.git_log_file()
end, { desc = "Git Current File History" })
map("n", "<leader>gl", function()
	Snacks.picker.git_log({ cwd = git_root() })
end, { desc = "Git Log" })
map("n", "<leader>gL", function()
	Snacks.picker.git_log()
end, { desc = "Git Log (cwd)" })
map("n", "<leader>gd", function()
	Snacks.picker.git_diff()
end, { desc = "Git Diff (hunks)" })

-- snippets
local ls = require("luasnip")
vim.keymap.set({ "i", "s" }, "<C-K>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-L>", function()
	ls.jump(1)
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-J>", function()
	ls.jump(-1)
end, { silent = true })

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("python", {
	s("log", {
		t({ "import logging", "logger = logging.getLogger(name=__name__)" }),
	}),
})
