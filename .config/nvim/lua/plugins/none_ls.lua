return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        'jayp0521/mason-null-ls.nvim',
    },

    config = function()
        local null_ls = require("null-ls")
        local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

        require('mason-null-ls').setup {
            ensure_installed = {
                'black',
                'isort',
                'shfmt',
                'checkmake',
                'prettier',
                'stylua',
            },
            automatic_installation = true,
        }

        null_ls.setup({
            sources = {
                null_ls.builtins.diagnostics.checkmake,

                null_ls.builtins.formatting.black,
                null_ls.builtins.formatting.isort,
                null_ls.builtins.formatting.shfmt.with { args = { '-i', '2' } },
                null_ls.builtins.formatting.prettier.with { filetypes = { 'html', 'json', 'yaml', 'markdown' } },
                null_ls.builtins.formatting.stylua,
            },
            on_attach = function(client, bufnr)
                if client.supports_method 'textDocument/formatting' then
                    vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
                    vim.api.nvim_create_autocmd('BufWritePre', {
                        group = augroup,
                        buffer = bufnr,
                        callback = function()
                            vim.lsp.buf.format { async = false }
                        end,
                    })
                end
            end,
        })

        vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
    end,
}
