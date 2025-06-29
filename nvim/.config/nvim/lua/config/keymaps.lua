-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>fo", function()
  require("oil").open()
end, { desc = "Open Oil", noremap = true, silent = true })

vim.keymap.set("n", "<leader>zn", function()
  local title = vim.fn.input("Title: ")
  if title ~= "" then
    require("zk.commands").get("ZkNew")({ title = title })
  end
end, { desc = "ZkNew with title" })

vim.keymap.set("n", "<leader>zj", function()
  require("zk.commands").get("ZkNew")({ dir = "journal/daily" })
end, { desc = "ZkNew journal/daily" })
