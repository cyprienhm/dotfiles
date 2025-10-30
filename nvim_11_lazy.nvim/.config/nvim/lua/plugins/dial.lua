return {
	"monaqa/dial.nvim",
	config = function()
		local augend = require("dial.augend")
		require("dial.config").augends:register_group({
			-- default augends used when no group name is specified
			default = {
				augend.integer.alias.decimal, -- nonnegative decimal number (0, 1, 2, 3, ...)
				augend.integer.alias.hex, -- nonnegative hex number  (0x01, 0x1a1f, etc.)
				augend.date.alias["%Y/%m/%d"], -- date (2022/02/19, etc.)
				augend.date.alias["%d/%m/%Y"], -- date
				augend.constant.new({
					elements = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" },
					word = true,
					cyclic = true,
				}),
				augend.constant.new({
					elements = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
					word = true,
					cyclic = true,
				}),
				augend.constant.new({
					elements = {
						"January",
						"February",
						"March",
						"April",
						"May",
						"June",
						"July",
						"August",
						"September",
						"October",
						"November",
						"December",
					},
					word = true,
					cyclic = true,
				}),
				augend.constant.new({
					elements = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
					word = true,
					cyclic = true,
				}),
				augend.constant.new({
					elements = { "[ ]", "[x]" },
					word = false,
					cyclic = true,
				}),
				augend.constant.alias.bool, -- boolean value (true <-> false)
			},
		})
		vim.keymap.set("n", "<C-a>", function()
			require("dial.map").manipulate("increment", "normal")
		end)
		vim.keymap.set("n", "<C-x>", function()
			require("dial.map").manipulate("decrement", "normal")
		end)
		vim.keymap.set("n", "g<C-a>", function()
			require("dial.map").manipulate("increment", "gnormal")
		end)
		vim.keymap.set("n", "g<C-x>", function()
			require("dial.map").manipulate("decrement", "gnormal")
		end)
		vim.keymap.set("x", "<C-a>", function()
			require("dial.map").manipulate("increment", "visual")
		end)
		vim.keymap.set("x", "<C-x>", function()
			require("dial.map").manipulate("decrement", "visual")
		end)
		vim.keymap.set("x", "g<C-a>", function()
			require("dial.map").manipulate("increment", "gvisual")
		end)
		vim.keymap.set("x", "g<C-x>", function()
			require("dial.map").manipulate("decrement", "gvisual")
		end)
	end,
}
