---@diagnostic disable: undefined-global
local keymap = require("keymap")

-- "hl.…" text becomes a Lua dispatcher; anything else runs as a shell command
local function action(a)
    if a:sub(1, 3) == "hl." then
        return assert(load("return " .. a))()
    end
    return hl.dsp.exec_cmd(a)
end

for _, b in ipairs(keymap.binds) do
    local ok, err = pcall(function() hl.bind(b[1], action(b[2])) end)
    if not ok then
        pcall(hl.notification.create, { text = "bind failed: " .. b[1] .. " (" .. tostring(err) .. ")" })
    end
end

-- SUPER + left drag moves a window, SUPER + right drag resizes it
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
pcall(function()
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
end)
