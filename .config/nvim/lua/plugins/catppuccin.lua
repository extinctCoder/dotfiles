return {{
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
        vim.cmd.colorscheme "catppuccin-mocha" -- latte, frappe, macchiato, mocha
    end
}}
-- return {
--     "catppuccin/nvim",
--     name = "catppuccin",
--     priority = 1000,
--     lazy = false,
--     config = function()
--         require("catppuccin").setup({
--             integrations = {
--                 bufferline = true,
--                 treesitter = true
--                 -- other integrations like treesitter, lualine, etc.
--             }
--         })
--         vim.cmd.colorscheme("catppuccin-mocha") -- or latte/frappe/macchiato
--     end
-- }
