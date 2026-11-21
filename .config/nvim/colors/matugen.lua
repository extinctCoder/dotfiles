vim.cmd("highlight clear")
vim.g.colors_name = "matugen"
vim.o.background = "dark"
local c = {
    bg = "#11140e",
    bg2 = "#1d211a",
    bg3 = "#282b24",
    fg = "#e1e3d9",
    muted = "#c4c8bb",
    line = "#44483e",
    accent = "#acd28e",
    accent2 = "#a0cfce",
    red = "#ffb4a4",
    green = "#acd28f",
    yellow = "#dbc66e",
    cyan = "#80d5cf",
}
local hl = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = c.bg2 })
hl("FloatBorder", { fg = c.line, bg = c.bg2 })
hl("CursorLine", { bg = c.bg2 })
hl("LineNr", { fg = c.line })
hl("CursorLineNr", { fg = c.accent, bold = true })
hl("Visual", { bg = c.bg3 })
hl("Search", { fg = c.bg, bg = c.yellow })
hl("StatusLine", { fg = c.fg, bg = c.bg2 })
hl("Pmenu", { fg = c.fg, bg = c.bg2 })
hl("PmenuSel", { fg = c.bg, bg = c.accent })
hl("WinSeparator", { fg = c.line })
hl("Comment", { fg = c.muted, italic = true })
hl("String", { fg = c.green })
hl("Constant", { fg = c.yellow })
hl("Number", { fg = c.yellow })
hl("Keyword", { fg = c.accent2 })
hl("Statement", { fg = c.accent2 })
hl("Function", { fg = c.accent })
hl("Type", { fg = c.cyan })
hl("Identifier", { fg = c.fg })
hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.yellow })
hl("DiagnosticInfo", { fg = c.cyan })
hl("DiagnosticHint", { fg = c.muted })
