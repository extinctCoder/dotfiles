# Setup guide

Hyprland + Quickshell desktop for EndeavourOS / Arch. Minimal flat look, mono font, colors taken from the wallpaper. Keyboard first.

## Quick start

On a working EndeavourOS install (GNOME or no desktop):

```bash
git clone -b EndeavourOS https://github.com/extinctCoder/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

Then:

1. `gh auth login` so `git push` works.
2. Log out and pick **Hyprland** at the login screen.
3. You land on the lock screen. Type your password.
4. Press `Super + /` to see every keybind.

On a **clean install** (EndeavourOS "No Desktop", disk encryption on), run `./setup.sh --system` instead, then reboot. That adds zram swap and console autologin: power on → disk password → Hyprland → lock screen.

## What setup.sh does

1. Installs every package with `yay --needed` (asks before changing anything).
2. Enables bluetooth, power profiles and the `pkgfile` database.
3. Creates `~/.config` and `~/Pictures/...` as real folders, so stow links files *inside* them.
4. Moves any existing file that would block stow to `~/.dotfiles-backup/<date>/`.
5. Links the repo with `stow --no-folding`. Generated files (colors) stay out of the repo.
6. Switches your shell to zsh, installs the tmux plugin manager.
7. Generates colors from the first wallpaper in `~/Pictures/wallpapers`, sets the dark GTK theme.

Safe to run again; it skips what's already done.

## Keybinds

`Super + /` shows all of them, searchable. The important ones:

| Keys | Action |
| --- | --- |
| `Super + Return` | terminal |
| `Super + Space` | app launcher |
| `Super + V` | clipboard history |
| `Super + D` | leader menu: then `t` terminal, `b` browser, `f` files, `e` editor, `w` wifi, `h` bluetooth, `a` audio, `m` monitor, `p` next wallpaper, `s` screenshot, `l` lock, `z` sleep |
| `Super + Q` | close window |
| `Super + H/J/K/L` | focus left/down/up/right |
| `Super + Shift + H/J/K/L` | move window |
| `Super + 1..9` | workspace |
| `Super + Shift + 1..9` | send window to workspace |
| `Super + T` / `Super + F` | float / fullscreen |
| `Super + Esc` | lock |
| `Super + N` | clear notifications |
| `Print` / `Shift + Print` | screenshot region / screen |

To change a bind, edit `.config/hypr/keymap.lua`. The cheatsheet reads the same file, so it updates itself.

## Changing the wallpaper

`Super + D` then `p` picks a random one from `~/Pictures/wallpapers`. Or:

```bash
qs ipc call wallpaper set ~/Pictures/wallpapers/<file>
```

Every color (bar, terminal, Neovim, tmux, GTK apps, borders) follows.

## Where things live

| Path | What |
| --- | --- |
| `.config/hypr/` | Hyprland (Lua): `keymap.lua` binds, `look.lua`, `input.lua`, `rules.lua`, `autostart.lua`, `hypridle.conf` |
| `.config/quickshell/` | bar, launcher, notifications, lock, wallpaper, OSD, music card, cheatsheet (QML) |
| `.config/matugen/` | color templates for every app |
| `.config/nvim/` | Neovim (lazy.nvim, LSP, telescope, treesitter) |
| `.zshrc`, `.config/ohmyposh/` | shell and prompt |
| `.config/ghostty/`, `.config/tmux/`, `.config/mpv/` | terminal, multiplexer, video |
| `system/` | zram + autologin, copied by `--system` only |

After adding a new file to the repo, relink: `stow --no-folding --restow --target="$HOME" .`

Secrets (API keys) go in `~/.secrets.zsh`. It's sourced by `.zshrc` and never committed.

## When something breaks

| Symptom | Fix |
| --- | --- |
| No bar, wallpaper or lock | `killall quickshell; quickshell` in a terminal prints QML errors with file and line |
| `Colors` is undefined | Run `matugen image -m dark ~/Pictures/wallpapers/<file>` |
| A bind does nothing | Hyprland shows a "bind failed" notification naming it; or test with `qs ipc call launcher toggle` |
| Red error bar at the top | Hyprland config error; it names the Lua file and line |
| Locked out after wrong passwords | `Ctrl + Alt + F3`, log in, `faillock --user $USER --reset` |
| Broken lock screen | `Ctrl + Alt + F3`, log in, `hyprctl --instance 0 dispatch "hl.dsp.exec_cmd('quickshell')"`, back with `Ctrl + Alt + F1` |
| Quickshell crashes after an update | `yay -S quickshell --rebuild` (it must be rebuilt after Qt updates) |
| Cheatsheet empty | `lua` missing, or a typo in `keymap.lua`: run `lua ~/.config/hypr/keymap.lua` |

Hyprland 0.55+ uses Lua: `hyprctl dispatch` now takes Lua, like `hyprctl dispatch "hl.dsp.window.close()"`. Old-style `hyprctl dispatch killactive` silently fails.
