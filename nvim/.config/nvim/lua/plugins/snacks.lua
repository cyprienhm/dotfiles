local utils = require("utils")
return {
	"folke/snacks.nvim",
	lazy = false,
  -- stylua: ignore
	keys = {
		{ "<leader><space>", function() Snacks.picker.smart() end, desc = "Find Files (Root Dir)", },
		{ "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep", },
		{ "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps", },
    { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages", },
		{ "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks", },
		{ "<leader>su", function() Snacks.picker.undo() end, desc = "Undotree", },
		{ "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages", },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
		{ "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics", },
		{ "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics", },
		{ "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols", },
		{ "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols", },
		{ "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers", },
		{ "<leader>fe", function() Snacks.explorer({ cwd = utils.git_root() }) end, desc = "Explorer Snacks (root dir)", },
		{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent", },
		{ "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent (cwd)", },
		{ "<leader>fE", function() Snacks.explorer() end, desc = "Explorer Snacks (cwd)", },
		{ "<C-/>", "<cmd>close<cr>", desc = "Hide Terminal", mode = "t" },
		{ "<c-_>", "<cmd>close<cr>", desc = "which_key_ignore", mode = "t" },
		{ "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Delete Other Buffers", },
		{ "<leader>gg", function() Snacks.lazygit({ cwd = utils.git_root() }) end, desc = "Lazygit (Root Dir)", },
		{ "<leader>gG", function() Snacks.lazygit() end, desc = "Lazygit (cwd)", },
		{ "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Current File History", },
		{ "<leader>gl", function() Snacks.picker.git_log({ cwd = utils.git_root() }) end, desc = "Git Log", },
		{ "<leader>gL", function() Snacks.picker.git_log() end, desc = "Git Log (cwd)", },
		{ "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)", },
	},
	opts = {
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
		dashboard = {
			enabled = false,
			preset = {
				header = [[
                                                                      
                                            :`.            .--._      
                                              `.`-.        /  ',-""""'
                                                `. ``~-._.'_."/       
                                                  `~-._ .` `~;        
                                                      ;.    /         
                                                      /     /         
                                                ,_.-';_,.'`           
                                                  `"-;`/              
                                                    ,'`               
                                                                    
      ████ ██████           █████      ██                 btw 
     ███████████             █████                             
     █████████ ███████████████████ ███   ███████████   
    █████████  ███    █████████████ █████ ██████████████   
   █████████ ██████████ █████████ █████ █████ ████ █████   
 ███████████ ███    ███ █████████ █████ █████ ████ █████  
██████  █████████████████████ ████ █████ █████ ████ ██████ 
]],
       -- stylua: ignore
       ---@type snacks.dashboard.Item[]
       keys = {
         { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
         { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
         { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
         { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
         { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
         { icon = " ", key = "s", desc = "Restore Session", section = "session" },
         { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
         { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
         { icon = " ", key = "q", desc = "Quit", action = ":qa" },
       },
			},
		},
	},
	config = function(_, opts)
		require("snacks").setup(opts)
		Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")
		Snacks.toggle.zen():map("<leader>uz")
		Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
	end,
}
