-- Writes docs/keybinds.md from the real keymap (the single source of truth):
--   lua docs/keybinds.lua > docs/keybinds.md      (run from the repo root)
local M = dofile(".config/hypr/config/keymap.lua")

local names = { SUPER = "Super", SHIFT = "Shift", CTRL = "Ctrl", ["return"] = "Enter", space = "Space",
    slash = "/", escape = "Esc", tab = "Tab", print = "Print", mouse_down = "scroll down", mouse_up = "scroll up" }
local function pretty(keys)
    local parts = {}
    for p in keys:gmatch("[^+]+") do
        p = p:match("^%s*(.-)%s*$")
        parts[#parts + 1] = names[p] or (#p == 1 and p:upper() or p)
    end
    return table.concat(parts, " + ")
end
local function note(flags)
    if not flags then return "" end
    if flags.repeating and flags.locked then return " *(hold to repeat; works on the lock screen)*" end
    if flags.repeating then return " *(hold to repeat)*" end
    if flags.locked then return " *(works on the lock screen)*" end
    return ""
end

local out = {}
local function w(s) out[#out + 1] = s or "" end
w("# Keybinds"); w()
w("Generated from [`.config/hypr/config/keymap.lua`](../.config/hypr/config/keymap.lua), the single source")
w("of truth: Hyprland binds from it, and the shell's cheatsheet (`Super + /`) and leader menu read it too.")
w("Edit that file, not this page, then regenerate: `lua docs/keybinds.lua > docs/keybinds.md`."); w()
w("Directions follow vim: `H` left, `J` down, `K` up, `L` right."); w()

local order = { "apps", "shell", "windows", "workspaces", "system", "media" }
local titles = { apps = "Apps", shell = "Shell", windows = "Windows", workspaces = "Workspaces", system = "System", media = "Media and laptop keys" }
local dirs = { left = true, right = true, up = true, down = true }
for _, g in ipairs(order) do
    w("## " .. titles[g]); w(); w("| Keys | Action |"); w("|---|---|")
    local seen = {}
    for _, b in ipairs(M.binds) do
        local keys, _, desc, group, flags = b[1], b[2], b[3], b[4], b[5]
        if group == g then
            local k, d = pretty(keys), desc
            local family, last = desc:match("^(.-)%s(%S+)$")
            if g == "workspaces" and desc:match("^workspace %d$") then
                k, d = "Super + 1 … 9", "go to workspace 1 … 9"
            elseif g == "workspaces" and desc:match("^send to workspace %d$") then
                k, d = "Super + Shift + 1 … 9", "send window to workspace 1 … 9"
            elseif g == "windows" and last and dirs[last] then
                k, d = k:gsub(" %+ [HJKL]$", "") .. " + H/J/K/L", family .. " left / down / up / right"
            end
            if not seen[d] then
                seen[d] = true
                w("| `" .. k .. "` | " .. d .. note(flags) .. " |")
            end
        end
    end
    w()
end

w("## Leader menu"); w(); w("Press `Super + D`, then one key. `Esc` cancels."); w()
w("| Key | Action |"); w("|---|---|")
for _, l in ipairs(M.leader) do w("| `" .. l[1] .. "` | " .. l[3] .. " |") end
w()
w("## Inside the shell's own windows"); w()
w("| Where | Keys |"); w("|---|---|")
w("| Launcher (`Super + Space`) | type to search; `↑`/`↓` or `Tab` to move; `Enter` runs; `Esc` closes. Prefixes: `>` actions, `/` files, `@` Zen bookmarks and history, `=` calculator, `?` web search, `yt ` YouTube. A pasted link offers *play in mpv*. |")
w("| Clipboard (`Super + V`) | the same box on clipboard history; `Enter` copies the entry |")
w("| Overview (`Super + Tab`) | type to filter, `Enter` jumps to the first match; click a window to jump to it; drag it onto another workspace to move it |")
w("| Wallpaper picker (`Super + W`) | arrows or `H/J/K/L` to move, `Enter` or click applies it (and recolors everything) |")
w("| Power menu (`Super + Shift + Esc`) | the letter of an action, or arrows/`J`/`K` + `Enter`; reboot and shut down ask `[y/n]` |")
w("| Notifications | left click: default action and close; right click: close; `Super + N` clears all |")
w("| Zen | `Ctrl + Alt + C` toggles compact mode |")
io.write(table.concat(out, "\n") .. "\n")
