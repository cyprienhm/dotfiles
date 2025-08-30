return {
	"L3MON4D3/LuaSnip",
	config = function()
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

		vim.keymap.set({ "i", "s" }, "<C-O>", function()
			if ls.choice_active() then
				ls.change_choice(1)
			end
		end, { silent = true })
		require("config.snippets")
	end,
}
