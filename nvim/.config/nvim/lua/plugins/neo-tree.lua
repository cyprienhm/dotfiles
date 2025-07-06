return {
  "nvim-neo-tree/neo-tree.nvim",
  cmd = "Neotree",
  opts = {
    window = {
      mappings = {
        ["<tab>"] = function(state)
          state.commands["open"](state)
          vim.cmd("Neotree reveal")
        end,
        ["n"] = function(state)
          local node = state.tree:get_node()
          if node and node.path then
            local filename = vim.fn.fnamemodify(node.path, ":t")
            vim.fn.setreg("+", filename)
            vim.notify("Yanked: " .. filename)
          end
        end,
      },
    },
  },
}
