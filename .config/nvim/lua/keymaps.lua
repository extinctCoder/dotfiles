vim.g.mapleader = " "
local map = vim.keymap.set

map("n", "<esc>", "<cmd>nohlsearch<cr>", { desc = "clear search highlight" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "save" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "quit" })
map("n", "x", '"_x', { desc = "delete char without yanking" })

-- splits (your old commented-out set, now on)
map("n", "<leader>sv", "<C-w>v", { desc = "split vertical" })
map("n", "<leader>sh", "<C-w>s", { desc = "split horizontal" })
map("n", "<leader>se", "<C-w>=", { desc = "equal splits" })
map("n", "<leader>sx", "<cmd>close<cr>", { desc = "close split" })
