-- return {
--     'nvim-lualine/lualine.nvim',
--     dependencies = { 'nvim-tree/nvim-web-devicons' },
--     config = function()
--         require('lualine').setup({
--             options = {
--                 theme = 'catppuccin'
--             }
--         })
--     end
-- }
return {
    "nvim-lualine/lualine.nvim",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        require("lualine").setup({
            options = {
                theme = "catppuccin",
                section_separators = "",
                component_separators = ""
            },
            sections = {
                lualine_a = {"mode"},
                lualine_b = {"branch"},
                lualine_c = {{
                    "buffers",
                    show_filename_only = true,
                    hide_filename_extension = false,
                    show_modified_status = true,
                    mode = 2, -- 0: ID, 1: name, 2: relative path
                    symbols = {
                        modified = " ●",
                        alternate_file = "#",
                        directory = ""
                    }
                }},
                lualine_x = {"filetype"},
                lualine_y = {"progress"},
                lualine_z = {"location"}
            }
        })
    end
}
