local opt = vim.opt -- for conciseness

-- LINE Numbers

opt.relativenumber = true
opt.number = true

-- Tab SIZE & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- LINE wrapping
opt.wrap = false

-- settings SEARCH
opt.ignorecase = true
opt.smartcase = true

-- Cursor LINE
opt.cursorline = true

-- APPEARANCE settings
opt.termguicolors = true
opt.background = 'dark'
opt.signcolumn = 'yes'

-- BACKSPACE configuration
opt.backspace = 'indent,eol,start'

--clipboard CONFIG
opt.clipboard:append('unnamedplus')

-- SPLIT Screen
opt.splitright = true
opt.splitbelow = true

-- SPACE char CONFIG
opt.iskeyword:append('-')