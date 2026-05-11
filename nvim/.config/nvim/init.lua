vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set
-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <meta> hjkl keys
map("n", "<M-k>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<M-j>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<M-h>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<M-l>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bd", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
map("n", "<leader>ba", "<cmd>:%bd<cr>", { desc = "Delete All Buffers" })
map("n", "<leader>br", "<cmd>e!<cr>", { desc = "Reload Buffer" })

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
	vim.cmd("noh")
	return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Search non-ASCII characters
map("n", "<leader>ca", "/[^\\d0-\\d127]<cr>", { desc = "Search non-ASCII characters" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
map("n", "<leader>qr", "<cmd>restart<cr>", { desc = "Restart Neovim" })

-- tabs
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })

-- diagnostics
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "<leader>cf", function()
	require("conform").format()
end, { desc = "Conform Format" })
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

map("n", "<leader>e", function()
	require("oil").open()
end, { desc = "Open Oil" })

map("n", "<leader>yy", "<cmd>Yazi<cr>", { desc = "Open Yazi (current file)" })
map("n", "<leader>yt", "<cmd>Yazi toggle<cr>", { desc = "Open Yazi (resume)" })
map("n", "<leader>yc", "<cmd>Yazi cwd<cr>", { desc = "Open Yazi (cwd)" })

-- toggles
map("n", "<leader>uw", "<cmd>set wrap!<cr>", { desc = "Toggle wrap" })
map("n", "<leader>us", "<cmd>set spell!<cr>", { desc = "Toggle spell" })
map("n", "<leader>uz", function()
	Snacks.zen()
end, { desc = "Toggle Zen" })

local function toggle_buffer_format()
	if vim.b.autoformat == nil then
		vim.b.autoformat = false
	else
		vim.b.autoformat = not vim.b.autoformat
	end
	vim.notify("Buffer format " .. (vim.b.autoformat and "enabled" or "disabled"))
end
map("n", "<leader>uf", toggle_buffer_format, { desc = "Toggle buffer format" })

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

map("n", "<leader>fY", function()
	if vim.bo.filetype == "oil" then
		require("oil.actions").copy_to_system_clipboard.callback()
		return
	end
	local filepath = vim.api.nvim_buf_get_name(0)
	vim.fn.setreg("+", filepath)
	vim.notify("Yanked: " .. filepath)
end, { desc = "Yank full path" })

map("n", "<leader>fy", function()
	local filepath
	if vim.bo.filetype == "oil" then
		local oil = require("oil")
		local entry = oil.get_cursor_entry()
		local dir = oil.get_current_dir()
		if not entry or not dir then
			return
		end
		filepath = vim.fn.fnamemodify(dir .. entry.name, ":.")
	else
		local buf = vim.api.nvim_buf_get_name(0)
		filepath = vim.fn.fnamemodify(buf, ":.")
	end
	vim.fn.setreg("+", filepath)
	vim.notify("Yanked: " .. filepath)
end, { desc = "Yank relative path" })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
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
opt.scrolloff = 5
opt.sidescrolloff = 5
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldmethod = "expr"
opt.foldtext = "" -- text displayed on closed fold
opt.foldcolumn = "auto"
opt.showmode = false
opt.ignorecase = true
opt.smartcase = true
opt.winborder = "rounded"
opt.grepprg = "rg --vimgrep"
opt.fillchars = {
	foldinner = " ",
}

-- plugins

vim.cmd("packadd nvim.difftool")
vim.cmd("packadd nvim.undotree")

-- hooks for plugins which need them
-- taken from :h vim.pack-events
local plugins_hooks = function(ev)
	local name, kind = ev.data.spec.name, ev.data.kind
	if name == "markdown-preview.nvim" and (kind == "install" or kind == "update") then
		if not ev.data.active then
			vim.cmd.packadd("markdown-preview.nvim")
		end
		vim.fn["mkdp#util#install"]()
	end
end

vim.api.nvim_create_autocmd("PackChanged", { callback = plugins_hooks })

vim.pack.add({
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
	{ src = "https://github.com/folke/snacks.nvim" },
	{ src = "https://github.com/folke/lazydev.nvim" },
	{ src = "https://github.com/folke/persistence.nvim" },
	{ src = "https://github.com/folke/which-key.nvim" },
	{ src = "https://github.com/folke/flash.nvim" },
	{ src = "https://github.com/rose-pine/neovim", name = "rose-pine" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/mikavilpas/yazi.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
	{ src = "https://github.com/williamboman/mason.nvim" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim", name = "ibl" },
	{ src = "https://github.com/saghen/blink.cmp" },
	{ src = "https://github.com/saghen/blink.lib" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/Bekaboo/dropbar.nvim" },
	{ src = "https://github.com/chentoast/marks.nvim" },
	{ src = "https://github.com/jpalardy/vim-slime" },
	{ src = "https://github.com/nvim-mini/mini.surround" },
	{ src = "https://github.com/akinsho/bufferline.nvim" },
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
	{ src = "https://codeberg.org/mfussenegger/nvim-dap.git" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui" },
	{ src = "https://github.com/mfussenegger/nvim-dap-python" },
	{ src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
	{ src = "https://github.com/chomosuke/typst-preview.nvim" },
	{ src = "https://github.com/pwntester/octo.nvim" },
	{ src = "https://github.com/iamcco/markdown-preview.nvim" },
	{ src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
	{ src = "https://github.com/obsidian-nvim/obsidian.nvim" },
	{ src = "https://github.com/cyprienhm/tableview.nvim" },
	{ src = "https://github.com/sindrets/diffview.nvim" },
}, { confirm = false })

require("lazydev").setup()

-- nvim-treesitter & nvim-treesitter-textobjects

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		pcall(vim.treesitter.start)
	end,
})

require("nvim-treesitter-textobjects").setup({
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			selection_modes = {
				["@function.inner"] = "V",
				["@function.outer"] = "V",
				["@class.inner"] = "V",
				["@class.outer"] = "V",
			},
			include_surrounding_whitespace = true,
		},
	},
})
map({ "x", "o" }, "af", function()
	require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
end)
map({ "x", "o" }, "if", function()
	require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
end)
map({ "x", "o" }, "ac", function()
	require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
end)
map({ "x", "o" }, "ic", function()
	require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
end)
map({ "x", "o" }, "aa", function()
	require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects")
end)
map({ "x", "o" }, "ia", function()
	require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects")
end)

-- lsp
map("n", "<leader>lr", "<cmd>lsp restart<cr>", { desc = "Restart LSP" })

-- mason-tool-installer only accepts mason names
local servers = {
	"lua-language-server",
	"ty",
	"ast-grep",
	"typescript-language-server",
	"svelte-language-server",
	"marksman",
	"stylua",
	"ruff",
	"tinymist",
	"beautysh",
	"css-lsp",
	"clangd",
	"gopls",
}

require("mason").setup()
require("mason-tool-installer").setup({
	ensure_installed = servers,
})

-- configs will automatically be read from lsp/. use these names
vim.lsp.enable({
	"ty",
	"ruff",
	"lua_ls",
	"ast_grep",
	"ts_ls",
	"svelte",
	"marksman",
	"tinymist",
	"cssls",
	"hls",
	"clangd",
	"rust_analyzer",
	"julials",
	"gopls",
})

vim.diagnostic.config({
	severity_sort = true,
	float = { border = "rounded", source = true },
	underline = false,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "x",
			[vim.diagnostic.severity.WARN] = "!",
			[vim.diagnostic.severity.INFO] = "i",
			[vim.diagnostic.severity.HINT] = "h",
		},
	},
	virtual_text = {
		source = true,
		spacing = 2,
		prefix = ">",
	},
})

-- colorscheme
require("rose-pine").setup({ styles = { transparency = false } })
vim.cmd.colorscheme("rose-pine-main")

-- oil
-- Declare a global function to retrieve the current directory
function _G.get_oil_winbar()
	local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local dir = require("oil").get_current_dir(bufnr)
	if dir then
		return vim.fn.fnamemodify(dir, ":~")
	else
		-- If there is no current directory (e.g. over ssh), just show the buffer name
		return vim.api.nvim_buf_get_name(0)
	end
end

require("oil").setup({
	default_file_explorer = true,
	columns = { "icon", "size", "mtime" },
	keymaps = {
		["<C-v>"] = { "actions.select", opts = { vertical = true } },
		["<C-s>"] = { "actions.select", opts = { horizontal = true } },
		["<C-h>"] = {},
		["gS"] = { "actions.change_sort", mode = "n" },
		["gy"] = { "actions.copy_to_system_clipboard", mode = "n" },
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
	win_options = {
		winbar = "%!v:lua.get_oil_winbar()",
	},
})

-- yazi
require("yazi").setup({
	keymaps = {
		open_file_in_horizontal_split = "<c-s>",
		grep_in_directory = "<c-x>",
	},
})

-- conform
require("conform").setup({
	formatters_by_ft = {
		python = { "ruff_format", "ruff_organize_imports" },
		lua = { "stylua" },
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
		svelte = { "prettier" },
		c = { "clang-format" },
		haskell = { "ormolu" },
		rust = { "rustfmt" },
		xml = { "xmlformatter" },
	},
})

-- snacks
require("snacks").setup({
	picker = {
		win = {
			input = {
				keys = {
					["<a-s>"] = { "flash", mode = { "n", "i" } },
					["s"] = { "flash" },
				},
			},
		},
		actions = {
			flash = function(picker)
				require("flash").jump({
					pattern = "^",
					label = { after = { 0, 0 } },
					search = {
						mode = "search",
						exclude = {
							function(win)
								return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
							end,
						},
					},
					action = function(match)
						local idx = picker.list:row2idx(match.pos[1])
						picker.list:_move(idx, true, true)
					end,
				})
			end,
		},
	},
	image = {
		doc = {
			max_height = 20,
		},
	},
	words = {},
	toggle = { map = vim.keymap.set },
	zen = {
		show = { statusline = true },
		toggles = { dim = false },
		win = {
			enter = true,
			fixbuf = false,
			minimal = false,
			width = 100,
			height = 0,
			backdrop = { transparent = false },
			keys = { q = false },
			zindex = 40,
			wo = {
				winhighlight = "NormalFloat:Normal",
			},
			w = {
				snacks_main = true,
			},
		},
	},
})

-- pickers
map("n", "<leader>p", function()
	Snacks.picker.pickers()
end, { desc = "pickers picker" })
map("n", "<leader><space>", function()
	Snacks.picker.smart()
end, { desc = "smart picker" })
map("n", "<leader>/", function()
	Snacks.picker.grep()
end, { desc = "grep" })
map("n", "<leader>sm", function()
	Snacks.picker.marks()
end, { desc = "marks" })
map("n", "<leader>su", function()
	Snacks.picker.undo()
end, { desc = "undotree" })
map("n", "<leader>sd", function()
	Snacks.picker.diagnostics_buffer()
end, { desc = "buffer Diagnostics" })
map("n", "<leader>sD", function()
	Snacks.picker.diagnostics()
end, { desc = "diagnostics" })
map("n", "<leader>ss", function()
	Snacks.picker.lsp_symbols()
end, { desc = "LSP symbols" })
map("n", "<leader>sS", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "LSP workspace symbols" })
map("n", "<leader>sr", function()
	Snacks.picker.lsp_references()
end, { desc = "LSP References" })
map("n", "<leader>sj", function()
	Snacks.picker.jumps()
end, { desc = "Jumps" })
map("n", "<leader>,", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>ff", function()
	Snacks.picker.files()
end, { desc = "files" })
map("n", "<leader>fF", function()
	Snacks.picker.files({ cwd = vim.fs.root(0, ".git") })
end, { desc = "files (git root)" })
map("n", "<leader>fc", function()
	Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "nvim config files" })
map("n", "<leader>fd", function()
	Snacks.picker.files({ cwd = vim.fn.stdpath("data") .. "/site/pack/core/opt/" })
end, { desc = "nvim data files" })
map("n", "<leader>f.", function()
	Snacks.picker.files({ cwd = vim.fn.expand("~/dotfiles") })
end, { desc = "dots" })
map("n", "<leader>fr", function()
	Snacks.picker.recent()
end, { desc = "recent" })
map("n", "<leader>sl", function()
	Snacks.picker.resume()
end, { desc = "last picker" })
map("n", "<leader>gf", function()
	Snacks.picker.git_log_file()
end, { desc = "git log (file)" })
map("n", "<leader>gl", function()
	Snacks.picker.git_log({ cwd = vim.fs.root(0, ".git") })
end, { desc = "git log (repo)" })
map("n", "<leader>gd", function()
	Snacks.picker.git_diff()
end, { desc = "git diff" })
map("n", "<leader>gs", function()
	Snacks.picker.git_status()
end, { desc = "git status" })

map("n", "<leader>gg", function()
	Snacks.lazygit({ cwd = vim.fs.root(0, ".git") })
end, { desc = "lazygit" })

-- snippets
local ls = require("luasnip")
map({ "i", "s" }, "<C-K>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end)
map({ "i", "s" }, "<C-L>", function()
	ls.jump(1)
end)
map({ "i", "s" }, "<C-J>", function()
	ls.jump(-1)
end)

local s = ls.snippet
local t = ls.text_node
local f = ls.function_node
local i = ls.insert_node

ls.add_snippets("python", {
	s("log", {
		t({ "import logging", "logger = logging.getLogger(name=__name__)" }),
	}),
})

ls.add_snippets("rust", {
	s("debug", {
		t({ 'println!("{:?}");' }),
	}),
})

ls.add_snippets("all", {
	s("date", { f(function()
		return os.date("%Y-%m-%d")
	end) }),
	s("time", { f(function()
		return os.date("%H:%M")
	end) }),
	s("dt", { f(function()
		return os.date("%Y-%m-%d %H:%M")
	end) }),
	s("iso", { f(function()
		return os.date("%Y-%m-%dT%H:%M:%S%z")
	end) }),
})

ls.add_snippets("all", {
	s("p", {
		t("<p>"),
		i(0),
		t("</p>"),
	}),
})

-- lualine
local lualine = require("lualine")

-- Color table for highlights
-- stylua: ignore
local colors = {
  bg       = '#202328',
  fg       = '#bbc2cf',
  yellow   = '#ECBE7B',
  cyan     = '#008080',
  darkblue = '#081633',
  green    = '#98be65',
  orange   = '#FF8800',
  violet   = '#a9a1e1',
  magenta  = '#c678dd',
  blue     = '#51afef',
  red      = '#ec5f67',
}
-- -- Function to get the current mode indicator
local function mode_str()
	-- Map of modes to their respective shorthand indicators
	local mode_map = {
		n = "normal", -- Normal mode
		i = "insert", -- Insert mode
		v = "visual", -- Visual mode
		[""] = "visual block", -- Visual block mode
		V = "visual line", -- Visual line mode
		c = "command line", -- Command-line mode
		no = "ninsert", -- NInsert mode
		s = "select", -- Select mode
		S = "select line", -- Select line mode
		ic = "insert (completion)", -- Insert mode (completion)
		R = "replace", -- Replace mode
		Rv = "virtual replace", -- Virtual Replace mode
		cv = "command-line", -- Command-line mode
		ce = "ex", -- Ex mode
		r = "prompt", -- Prompt mode
		rm = "more", -- More mode
		["r?"] = "confirm?", -- Confirm mode
		["!"] = "shell!", -- Shell mode
		t = "terminal", -- Terminal mode
	}
	return mode_map[vim.fn.mode()] or "[unknown]"
end

local conditions = {
	buffer_not_empty = function()
		return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
	end,
	hide_in_width = function()
		return vim.fn.winwidth(0) > 80
	end,
	check_git_workspace = function()
		local filepath = vim.fn.expand("%:p:h")
		local gitdir = vim.fn.finddir(".git", filepath .. ";")
		return gitdir and #gitdir > 0 and #gitdir < #filepath
	end,
}

-- Config
local config = {
	options = {
		globalstatus = true,
		-- Disable sections and component separators
		component_separators = "",
		section_separators = "",
		theme = {
			-- We are going to use lualine_c an lualine_x as left and
			-- right section. Both are highlighted by c theme .  So we
			-- are just setting default looks o statusline
			normal = { c = { fg = colors.fg, bg = colors.bg } },
			inactive = { c = { fg = colors.fg, bg = colors.bg } },
		},
	},
	sections = {
		-- these are to remove the defaults
		lualine_a = {},
		lualine_b = {},
		lualine_y = {},
		lualine_z = {},
		-- These will be filled later
		lualine_c = {},
		lualine_x = {},
	},
	inactive_sections = {
		-- these are to remove the defaults
		lualine_a = {},
		lualine_b = {},
		lualine_y = {},
		lualine_z = {},
		lualine_c = {},
		lualine_x = {},
	},
}

-- Inserts a component in lualine_c at left section
local function ins_left(component)
	table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x at right section
local function ins_right(component)
	table.insert(config.sections.lualine_x, component)
end

ins_left({
	function()
		return "▊"
	end,
	color = { fg = colors.blue }, -- Sets highlighting of component
	padding = { left = 0, right = 1 }, -- We don't need space before this
})

ins_left({
	-- mode component
	mode_str,
	color = function()
		-- auto change color according to neovims mode
		local mode_color = {
			n = colors.red,
			i = colors.green,
			v = colors.blue,
			[""] = colors.blue,
			V = colors.blue,
			c = colors.magenta,
			no = colors.red,
			s = colors.orange,
			S = colors.orange,
			[""] = colors.orange,
			ic = colors.yellow,
			R = colors.violet,
			Rv = colors.violet,
			cv = colors.red,
			ce = colors.red,
			r = colors.cyan,
			rm = colors.cyan,
			["r?"] = colors.cyan,
			["!"] = colors.red,
			t = colors.magenta,
		}
		return { fg = mode_color[vim.fn.mode()] }
	end,
	padding = { right = 1 },
})

ins_left({
	-- filesize component
	"filesize",
	cond = conditions.buffer_not_empty,
})

ins_left({
	"filename",
	cond = conditions.buffer_not_empty,
	color = { fg = colors.magenta, gui = "bold" },
})

ins_left({ "location" })

ins_left({ "progress", color = { fg = colors.fg, gui = "bold" } })

-- Insert mid section. You can make any number of sections in neovim :)
-- for lualine it's any number greater then 2
ins_left({
	function()
		return "%="
	end,
})

ins_left({
	-- Lsp server name .
	function()
		local msg = "no lsp"
		local lsps_found = {}
		local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
		local clients = vim.lsp.get_clients()
		if next(clients) == nil then
			return msg
		end
		for _, client in ipairs(clients) do
			local filetypes = client.config.filetypes
			if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
				table.insert(lsps_found, client.name)
			end
		end
		if #lsps_found == 0 then
			return msg
		end
		return table.concat(lsps_found, ", ")
	end,
	icon = "",
	color = { fg = "#ffffff", gui = "bold" },
})

ins_left({
	"diagnostics",
	sources = { "nvim_diagnostic" },
	symbols = { error = "x ", warn = "! ", info = "i ", hint = "h " },
	diagnostics_color = {
		error = { fg = colors.red },
		warn = { fg = colors.yellow },
		info = { fg = colors.cyan },
	},
})

-- Add components to right sections
ins_right({
	"o:encoding", -- option component same as &encoding in viml
	fmt = string.lower, -- I'm not sure why it's upper case either ;)
	cond = conditions.hide_in_width,
	color = { fg = colors.green, gui = "bold" },
})

ins_right({
	"branch",
	icon = "",
	color = { fg = colors.violet, gui = "bold" },
})

ins_right({
	"diff",
	symbols = { added = "+", modified = "~", removed = "-" },
	diff_color = {
		added = { fg = colors.green },
		modified = { fg = colors.orange },
		removed = { fg = colors.red },
	},
	cond = conditions.hide_in_width,
})

ins_right({
	function()
		return "▊"
	end,
	color = { fg = colors.blue },
	padding = { left = 1 },
})

-- Now don't forget to initialize lualine
lualine.setup(config)

-- nvim-web-devicons
require("nvim-web-devicons").setup()

-- persistence
require("persistence").setup()

map("n", "<leader>qs", function()
	require("persistence").load()
end, { desc = "Restore Session" })

-- indentline
local highlight = {
	"RainbowRed",
	"RainbowYellow",
	"RainbowBlue",
	"RainbowOrange",
	"RainbowGreen",
	"RainbowViolet",
	"RainbowCyan",
}

local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
	vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
	vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
	vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

require("ibl").setup({ indent = { highlight = highlight } })

-- blink
require("blink.cmp").build():wait(60000)
require("blink.cmp").setup({
	-- :h blink-cmp-config-keymap
	keymap = {
		preset = "default",
		["<C-k>"] = false,
		["<Tab>"] = {
			function(cmp)
				if cmp.snippet_active() then
					return cmp.accept()
				else
					return cmp.select_and_accept()
				end
			end,
			"snippet_forward",
			"fallback",
		},
	},
	cmdline = {
		keymap = {
			["<Tab>"] = { "show", "accept" },
		},
		completion = { menu = { auto_show = true } },
	},

	appearance = {
		nerd_font_variant = "mono",
	},

	completion = {
		documentation = { auto_show = true },
		list = {
			selection = {
				preselect = function(ctx)
					return not require("blink.cmp").snippet_active({ direction = 1 })
				end,
			},
		},
	},

	signature = { enabled = true },

	snippets = { preset = "luasnip" },

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},

	fuzzy = { implementation = "rust" },
})

-- gitsigns
require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "-" },
		topdelete = { text = "-" },
		changedelete = { text = "~" },
		untracked = { text = "?" },
	},
	signs_staged = {
		add = { text = "++" },
		change = { text = "~~" },
		delete = { text = "--" },
		topdelete = { text = "--" },
		changedelete = { text = "~~" },
	},
	on_attach = function(buffer)
		local gs = package.loaded.gitsigns

		local function gs_map(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
		end

      -- stylua: ignore start
      gs_map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next Hunk")
      gs_map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev Hunk")
      gs_map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
      gs_map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
      gs_map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
      gs_map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
      gs_map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
      gs_map("n", "<leader>ghd", gs.diffthis, "Diff This")
	end,
})

-- breadcrumbs
require("dropbar").setup()

-- which-key
require("which-key").setup({ delay = 500 })

-- flash
require("flash").setup({
	label = { rainbow = { enabled = true } },
	modes = { char = { enabled = false } },
})
map({ "n", "x", "v" }, "s", function()
	require("flash").jump()
end, { desc = "Flash Jump" })
map({ "n", "x", "v" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash Treesitter" })
map({ "x", "o" }, "r", function()
	require("flash").remote()
end, { desc = "Flash Remote" })

-- marks
require("marks").setup()

-- slime
vim.cmd('let g:slime_target = "tmux"')
vim.cmd('let g:slime_default_config = {"socket_name": "default", "target_pane": "{last}"}')
vim.cmd("let g:slime_bracketed_paste = 1")
vim.cmd("let g:slime_dont_ask_default = 1")

-- surround
require("mini.surround").setup({
	mappings = {
		add = "gsa", -- Add surrounding in Normal and Visual modes
		delete = "gsd", -- Delete surrounding
		find = "gsf", -- Find surrounding (to the right)
		find_left = "gsF", -- Find surrounding (to the left)
		highlight = "gsh", -- Highlight surrounding
		replace = "gsr", -- Replace surrounding
		update_n_lines = "gsn", -- Update `n_lines`
	},
})

-- bufferline
require("bufferline").setup()

-- dap
require("dapui").setup()
require("nvim-dap-virtual-text").setup({ enabled = true, virt_text_pos = "inline" })
require("dap-python").setup("uv")

local dap = require("dap")
local dapui = require("dapui")

map("n", "<leader>db", function()
	dap.set_breakpoint()
end, { desc = "Dap Breakpoint" })
map("n", "<leader>dB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Dap Breakpoint Condition" })
map("n", "<leader>dc", function()
	dap.continue()
end, { desc = "Dap Continue" })
map("n", "<leader>du", function()
	require("dapui").toggle()
end, { desc = "Dap UI" })

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open({})
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close({})
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close({})
end

-- octo
require("octo").setup({
	picker = "snacks",
	use_local_fs = false,
	mappings = {
		review_diff = {
			copy_sha = { lhs = "", desc = "disable C-e copy commit SHA to system clipboard" },
		},
	},
})

-- obsidian
require("obsidian").setup({
	legacy_commands = false, -- this will be removed in the next major release
	workspaces = {
		{
			name = "personal",
			path = "~/notes/personal",
		},
		{
			name = "work",
			path = "~/notes/work",
		},
	},
	frontmatter = {
		enabled = false,
		func = require("obsidian.builtin").frontmatter,
		sort = { "id", "aliases", "tags" },
	},
	attachments = {
		folder = ".",
		img_text_func = require("obsidian.builtin").img_text_func,
		img_name_func = function()
			return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
		end,
		confirm_img_paste = true,
	},
	note = {
		template = vim.NIL, -- disables the default note template and just use a blank note
	},
	note_id_func = function(title, path)
		return title
	end,
})

map("n", "<leader>nn", "<cmd>Obsidian<cr>", { desc = "Obsidian" })
map("n", "<leader>no", "<cmd>Obsidian new<cr>", { desc = "New Note" })
map("n", "<leader>nf", "<cmd>Obsidian quick_switch<cr>", { desc = "Find Notes" })
map("n", "<leader>ns", "<cmd>Obsidian search<cr>", { desc = "Search Notes" })
map("n", "<leader>nt", "<cmd>Obsidian today<cr>", { desc = "Today Note" })
map("n", "<leader>ny", ":Obsidian today -", { desc = "Past Note" })
map("n", "<leader>ni", "<cmd>Obsidian paste_img<cr>", { desc = "Paste Image" })

-- tableview
require("tableview").setup({
	max_rows = 100,
	column_width_cap = 50,
	auto_open = { "parquet", "arrow", "feather", "xlsx" },
})

-- ui2
require("vim._core.ui2").enable({
	enable = true, -- Whether to enable or disable the UI.
	msg = { -- Options related to the message module.
		---@type 'cmd'|'msg' Default message target, either in the
		---cmdline or in a separate ephemeral message window.
		---@type string|table<string, 'cmd'|'msg'|'pager'> Default message target
		---or table mapping |ui-messages| kinds and triggers to a target.
		targets = "cmd",
		cmd = { -- Options related to messages in the cmdline window.
			height = 0.5, -- Maximum height while expanded for messages beyond 'cmdheight'.
		},
		dialog = { -- Options related to dialog window.
			height = 0.5, -- Maximum height.
		},
		msg = { -- Options related to msg window.
			height = 0.5, -- Maximum height.
			timeout = 4000, -- Time a message is visible in the message window.
		},
		pager = { -- Options related to message window.
			height = 1, -- Maximum height.
		},
	},
})

-- typst preview
require("typst-preview").setup()
