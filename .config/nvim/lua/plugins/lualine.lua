return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("lualine").setup({
            options = { theme = "auto", section_separators = "", component_separators = "" },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch" },
                lualine_c = { {
                    "buffers",
                    show_filename_only = true,
                    show_modified_status = true,
                    mode = 2,
                    symbols = { modified = " ●", alternate_file = "#", directory = "" },
                } },
                lualine_x = { "diagnostics", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        })
    end,
}
