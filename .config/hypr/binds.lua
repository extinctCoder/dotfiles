---@diagnostic disable: undefined-global

local keymap = require("keymap")
for _, b in ipairs(keymap.binds) do
    hl.bind(b[1], hl.dsp.exec_cmd(b[2]))
end
-- SUPER + left drag moves a window, SUPER + right drag resizes it
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
pcall(function()
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
end)
