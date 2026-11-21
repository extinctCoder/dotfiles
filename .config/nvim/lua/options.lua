local opt = vim.opt

-- line numbers
opt.number = true
opt.relativenumber = true

-- tabs and indentation (formatters override per language)
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- wrap long lines
opt.wrap = true

-- search
opt.ignorecase = true
opt.smartcase = true

-- look
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes" -- no text shifting when diagnostics appear
opt.scrolloff = 8

-- behavior
opt.backspace = "indent,eol,start"
opt.clipboard:append("unnamedplus") -- system clipboard (wl-clipboard)
opt.splitright = true
opt.splitbelow = true
opt.iskeyword:append("-")
opt.undofile = true
opt.updatetime = 250
