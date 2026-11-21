require("options")
require("keymaps") -- sets the leader key, so it loads before plugins

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", { change_detection = { notify = false } })

-- matugen colors, reloaded live when matugen sends SIGUSR1
pcall(vim.cmd.colorscheme, "matugen")
vim.api.nvim_create_autocmd("Signal", {
    pattern = "SIGUSR1",
    callback = function() pcall(vim.cmd.colorscheme, "matugen") end,
})
