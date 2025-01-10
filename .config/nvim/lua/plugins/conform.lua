return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      python = { "isort", "black" },
      lua = { "stylua" },
      fish = { "fish_indent" },
      sh = { "shfmt" },
    },
  },
}
