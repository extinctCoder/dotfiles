return {
    { "williamboman/mason.nvim", lazy = false, opts = {} },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        opts = { ensure_installed = { "lua_ls", "pyright", "ruff", "bashls", "codebook" } },
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            vim.lsp.config("*", {
                capabilities = require("cmp_nvim_lsp").default_capabilities(),
            })
            vim.lsp.config("lua_ls", {
                settings = { Lua = { diagnostics = { globals = { "vim" } } } },
            })
            vim.lsp.enable({ "lua_ls", "pyright", "ruff", "bashls", "codebook" })

            -- Python: ruff formats on save (replaces black + isort)
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.name == "ruff" then
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer = args.buf,
                            callback = function()
                                vim.lsp.buf.format({ bufnr = args.buf, name = "ruff" })
                            end,
                        })
                    end
                end,
            })

            vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "hover docs" })
            vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "go to definition" })
            vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, { desc = "references" })
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "code action" })
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "rename symbol" })
        end,
    },
}
