return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      python = { "ruff_format", "ruff_organize_imports" },
      lua = { "stylua" },
      fish = { "fish_indent" },
      sh = { "shfmt" },
      go = { "gofmt" },
      html = { "prettier" },
      css = { "prettier" },
      json = { "prettier" },
      md = { "prettier" },
      yaml = { "prettier" },
      javascript = { "prettier" },
    },
  },
}
