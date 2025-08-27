vim.cmd.colorscheme("tokyonight-night")
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.b.autoformat = true
local opt = vim.opt

opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 2 -- Size of an indent
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.number = true -- Print line number
opt.relativenumber = true -- Relative line numbers
opt.wrap = false -- Disable line wrap
opt.splitbelow = true -- Put new windows below current
opt.splitright = true -- Put new windows right of current
opt.termguicolors = true -- True color support
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
opt.undofile = true
opt.undolevels = 10000
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.signcolumn = "yes"
