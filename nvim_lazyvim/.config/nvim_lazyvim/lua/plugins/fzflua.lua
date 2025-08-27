return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  keys = {
    {
      "<leader>ss",
      function()
        require("fzf-lua").lsp_document_symbols()
      end,
      desc = "Goto Symbol",
    },
    {
      "<leader>sS",
      function()
        require("fzf-lua").lsp_live_workspace_symbols()
      end,
      desc = "Goto Symbol (Workspace)",
    },
  },
}
