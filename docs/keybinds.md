# Keybinds

Generated from [`.config/hypr/config/keymap.lua`](../.config/hypr/config/keymap.lua), the single source
of truth: Hyprland binds from it, and the shell's cheatsheet (`Super + /`) and leader menu read it too.
Edit that file, not this page, then regenerate: `lua docs/keybinds.lua > docs/keybinds.md`.

Directions follow vim: `H` left, `J` down, `K` up, `L` right.

## Apps

| Keys | Action |
|---|---|
| `Super + Enter` | terminal |
| `Super + B` | browser |
| `Super + E` | files |
| `Super + C` | editor |
| `Super + M` | monitor |

## Shell

| Keys | Action |
|---|---|
| `Super + Space` | launcher |
| `Super + V` | clipboard history |
| `Super + D` | leader menu |
| `Super + /` | keybind cheatsheet |
| `Super + N` | clear notifications |
| `Super + A` | quick settings + notifications |
| `Super + I` | dashboard |
| `Super + Tab` | window overview |
| `Super + W` | wallpaper picker |

## Windows

| Keys | Action |
|---|---|
| `Super + Q` | close window |
| `Super + F` | fullscreen |
| `Super + T` | toggle floating |
| `Super + X` | flip split direction |
| `Super + H/J/K/L` | focus left / down / up / right |
| `Super + Shift + H/J/K/L` | move window left / down / up / right |
| `Super + Ctrl + H/J/K/L` | resize left / down / up / right *(hold to repeat)* |

## Workspaces

| Keys | Action |
|---|---|
| `Super + 1 … 9` | go to workspace 1 … 9 |
| `Super + Shift + 1 … 9` | send window to workspace 1 … 9 |
| `Super + scroll down` | next workspace |
| `Super + scroll up` | previous workspace |
| `Super + S` | show / hide scratchpad |
| `Super + Shift + S` | send to scratchpad |

## System

| Keys | Action |
|---|---|
| `Super + Esc` | lock screen |
| `Super + Shift + E` | log out of Hyprland |
| `Super + Shift + Esc` | power menu |
| `Print` | screenshot region |
| `Shift + Print` | screenshot screen |

## Media and laptop keys

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume` | volume up *(hold to repeat; works on the lock screen)* |
| `XF86AudioLowerVolume` | volume down *(hold to repeat; works on the lock screen)* |
| `XF86AudioMute` | mute *(works on the lock screen)* |
| `XF86AudioMicMute` | mic mute *(works on the lock screen)* |
| `XF86MonBrightnessUp` | brightness up *(hold to repeat; works on the lock screen)* |
| `XF86MonBrightnessDown` | brightness down *(hold to repeat; works on the lock screen)* |
| `XF86AudioPlay` | play / pause *(works on the lock screen)* |
| `XF86AudioNext` | next track *(works on the lock screen)* |
| `XF86AudioPrev` | previous track *(works on the lock screen)* |

## Leader menu

Press `Super + D`, then one key. `Esc` cancels.

| Key | Action |
|---|---|
| `t` | terminal |
| `b` | browser |
| `f` | files |
| `e` | editor |
| `w` | wifi |
| `h` | bluetooth |
| `a` | audio |
| `m` | monitor |
| `p` | wallpaper picker |
| `P` | random wallpaper |
| `s` | screenshot |
| `l` | lock |
| `z` | sleep |
| `r` | reboot |
| `x` | shut down |

## Inside the shell's own windows

| Where | Keys |
|---|---|
| Launcher (`Super + Space`) | type to search; `↑`/`↓` or `Tab` to move; `Enter` runs; `Esc` closes. Prefixes: `>` actions, `/` files, `@` Zen bookmarks and history, `=` calculator, `?` web search, `yt ` YouTube. A pasted link offers *play in mpv*. |
| Clipboard (`Super + V`) | the same box on clipboard history; `Enter` copies the entry |
| Overview (`Super + Tab`) | type to filter, `Enter` jumps to the first match; click a window to jump to it; drag it onto another workspace to move it |
| Wallpaper picker (`Super + W`) | arrows or `H/J/K/L` to move, `Enter` or click applies it (and recolors everything) |
| Power menu (`Super + Shift + Esc`) | the letter of an action, or arrows/`J`/`K` + `Enter`; reboot and shut down ask `[y/n]` |
| Notifications | left click: default action and close; right click: close; `Super + N` clears all |
| Zen | `Ctrl + Alt + C` toggles compact mode |
