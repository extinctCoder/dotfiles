return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- the setup below is the master-branch API
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
        })
    end,
}
