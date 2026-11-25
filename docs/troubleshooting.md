# Troubleshooting

## First checks

```sh
qs log | grep -iE "error|warn" | tail -20     # the shell's own messages
hyprctl reload                                # re-read Hyprland's config
qs ipc show                                   # the shell is running and answering
```

Run commands that start graphical programs (like `qs -d` or `killall quickshell`)
**in a terminal on the laptop**, not over SSH: an SSH session has no Wayland display,
so the shell would start nowhere. If the desktop vanished that way, log out and in,
or reboot; Hyprland starts the shell again.

## Common problems

| Symptom | Cause and fix |
|---|---|
| Shell doesn't start; log mentions `Colors` | the generated theme is missing: run the first-colors step in [install.md](install.md#3-first-colors) |
| Changing wallpaper doesn't recolor | run `matugen image -m dark --source-color-index 0 "$(cat ~/.local/state/wallpaper)"` and read its error; without `--source-color-index 0` matugen waits for input |
| A config file isn't picked up | it isn't linked: `cd ~/dotfiles && stow --restow .` (check with `ls -l ~/.config/<app>`) |
| Launcher finds no files | `fd` missing: `yay -S fd` |
| No Zen bookmarks in the launcher | run `browser/zen-install.sh` (it creates `~/.local/state/zen-profile`) |
| Desktop shows `--` for updates | `pacman-contrib` missing (`checkupdates`), or no network yet |
| No lyrics for a song | LRCLIB doesn't have it, or a video's title is too unusual to match; nothing wrong is shown, only nothing |
| Core doesn't beat with music | check cava is running (`pgrep -a cava` while music plays) and hears audio: `timeout 5 cava -p ~/.config/cava/quickshell.conf \| tail -3` should print changing numbers |
| Clipboard history empty | `wl-paste --watch cliphist store` isn't running; it starts with Hyprland (`autostart.lua`) |

## Measuring the shell's CPU use

```sh
top -b -n 3 -d 2 -p $(pgrep -d, quickshell) | awk '/^ *[0-9]+ /{l=$0} END{split(l,f," "); print f[9] "%"}'
```

Expected: about 0.5% with windows covering the desktop (the living core pauses),
a few percent on an empty workspace while it animates.

Per thread, and which graphics driver the shell uses:

```sh
P=$(pgrep -o quickshell)
top -H -b -n 1 -p $P | head -15
grep -o -E "iris_dri|llvmpipe|libgallium[^/ ]*" /proc/$P/maps | sort -u
ls -l /proc/$P/fd | grep -o "/dev/dri/[a-zA-Z0-9]*" | sort -u   # renderD128 = GPU in use
```

## Sensors

```sh
ls /sys/class/drm/card*/gt/gt0/rc6_residency_ms     # Intel GPU load (i915)
grep -l nvme /sys/class/hwmon/hwmon*/name           # NVMe temperature
```

If either is missing, that signal simply stays off.

## Undo

- Login screen: `greeter/install.sh` prints how to switch back to GDM.
- Boot splash: the undo steps are at the top of `boot/install.sh`.
- Configs: `cd ~/dotfiles && stow -D .` removes every link.
