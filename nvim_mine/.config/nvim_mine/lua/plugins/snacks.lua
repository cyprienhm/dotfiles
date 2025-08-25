local utils = require("utils")
return {
	"folke/snacks.nvim",
	keys = {
		{
			"<leader>fe",
			function()
				Snacks.explorer({ cwd = utils.git_root() })
			end,
			desc = "Explorer Snacks (root dir)",
		},
		{
			"<leader>fE",
			function()
				Snacks.explorer()
			end,
			desc = "Explorer Snacks (cwd)",
		},
		{ "<leader>e", "<leader>fe", desc = "Explorer Snacks (root dir)", remap = true },
		{ "<leader>E", "<leader>fE", desc = "Explorer Snacks (cwd)", remap = true },
		{
			"<c-/>",
			function()
				Snacks.terminal(nil, { cwd = utils.git_root() })
			end,
			desc = "Terminal (Root Dir)",
		},
		{
			"<c-_>",
			function()
				Snacks.terminal(nil, { cwd = utils.git_root() })
			end,
			desc = "which_key_ignore",
		},
		{ "<C-/>", "<cmd>close<cr>", desc = "Hide Terminal", mode = "t" },
		{ "<c-_>", "<cmd>close<cr>", desc = "which_key_ignore", mode = "t" },
		{
			"<leader>bd",
			function()
				Snacks.bufdelete()
			end,
			desc = "Delete Buffer",
		},
		{
			"<leader>bo",
			function()
				Snacks.bufdelete.other()
			end,
			desc = "Delete Other Buffers",
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit({ cwd = utils.git_root() })
			end,
			desc = "Lazygit (Root Dir)",
		},
		{
			"<leader>gG",
			function()
				Snacks.lazygit()
			end,
			desc = "Lazygit (cwd)",
		},
		{
			"<leader>gf",
			function()
				Snacks.picker.git_log_file()
			end,
			desc = "Git Current File History",
		},
		{
			"<leader>gl",
			function()
				Snacks.picker.git_log({ cwd = utils.git_root() })
			end,
			desc = "Git Log",
		},
		{
			"<leader>gL",
			function()
				Snacks.picker.git_log()
			end,
			desc = "Git Log (cwd)",
		},
	},
	opts = {
		explorer = {},
		toggle = { map = vim.keymap.set },
		animate = { enabled = false },
		scroll = { enabled = false },
		dashboard = {
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
	end,
}
