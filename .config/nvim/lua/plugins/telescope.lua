return {
    { "nvim-telescope/telescope-ui-select.nvim" },
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x", -- stable branch instead of the old 0.1.5 tag
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
                },
            })
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "find files" })
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "find files" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "grep text" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "buffers" })
            vim.keymap.set("n", "<leader><leader>", builtin.oldfiles, { desc = "recent files" })
            require("telescope").load_extension("ui-select")
        end,
    },
}
