print("hi")
vim.cmd.colorscheme("tokyonight-night")
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 2 -- Size of an indent
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.number = true -- Print line number
opt.relativenumber = true -- Relative line numbers
opt.wrap = false -- Disable line wrap
