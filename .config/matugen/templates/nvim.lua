vim.cmd("highlight clear")
vim.g.colors_name = "matugen"
vim.o.background = "dark"
local c = {
    bg = "{{colors.surface.default.hex}}",
    bg2 = "{{colors.surface_container.default.hex}}",
    bg3 = "{{colors.surface_container_high.default.hex}}",
    fg = "{{colors.on_surface.default.hex}}",
    muted = "{{colors.on_surface_variant.default.hex}}",
    line = "{{colors.outline_variant.default.hex}}",
    accent = "{{colors.primary.default.hex}}",
    accent2 = "{{colors.tertiary.default.hex}}",
    red = "{{colors.red.default.hex}}",
    green = "{{colors.green.default.hex}}",
    yellow = "{{colors.yellow.default.hex}}",
    cyan = "{{colors.cyan.default.hex}}",
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
