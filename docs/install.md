# Install

Written for **EndeavourOS** (Arch) with `yay`, systemd-boot and dracut, on a laptop
with an Intel GPU. Most of it applies to any Arch system; the boot splash script
assumes systemd-boot and EndeavourOS's `reinstall-kernels`.

## 1. Packages

```sh
# compositor, shell, colors, terminal
yay -S --needed hyprland quickshell matugen ghostty stow
# Hyprland helpers
yay -S --needed hypridle hyprsunset hyprshot hyprpolkitagent cliphist wl-clipboard
# look
yay -S --needed ttf-firacode-nerd papirus-icon-theme adw-gtk-theme qt6ct
# what the shell reads and runs
yay -S --needed brightnessctl playerctl cava pacman-contrib fd curl sqlite lua
# terminal apps used by the keybinds
yay -S --needed yazi btop bluetui wiremix neovim
```

What needs what:

| Package | Used for |
|---|---|
| `cava` | the music spectrum and beats (living core, lyrics timing is separate) |
| `pacman-contrib` | `checkupdates`: the pending-updates count on the desktop |
| `fd` | file search in the launcher |
| `sqlite` | Zen bookmarks and history in the launcher |
| `lua` | the cheatsheet and leader menu read `keymap.lua` with plain `lua` |
| `curl` | weather (Open-Meteo), lyrics (LRCLIB), album covers |
| `cliphist` + `wl-clipboard` | clipboard history (`Super + V`) |
| `brightnessctl`, `playerctl` | brightness and media keys |
| `hyprshot` | screenshots (`Print`, `Shift + Print`) |

NetworkManager, PipeWire, UPower, power-profiles-daemon and BlueZ come with a
normal EndeavourOS install; the shell talks to them directly.

## 2. Link the configs

```sh
git clone -b EndeavourOS https://github.com/extinctCoder/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow .
```

Stow refuses to overwrite real files. If it reports conflicts, move those files
away (for example `mv ~/.config/hypr ~/.config/hypr.old`) and run `stow .` again.
After pulling changes later: `stow --restow .` (needed only when files are added
or removed).

## 3. First colors

Several files are generated from the wallpaper and are not in git (the theme for
the shell, Hyprland, Ghostty, GTK, Qt, btop, lazygit, mpv and Zen). Generate them
once before the first start:

```sh
mkdir -p ~/.local/state
w=~/Pictures/wallpapers/derrick-cooper.jpg
echo "$w" > ~/.local/state/wallpaper
matugen image -m dark --source-color-index 0 "$w"
```

`--source-color-index 0` matters: without it matugen asks which color to use and
fails when no terminal is attached. From then on, the wallpaper picker
(`Super + W`) does this for you.

## 4. Start

Log in on **TTY 1**: `.zprofile` starts Hyprland there. Hyprland starts the shell,
a hidden Ghostty (so `Super + Enter` is instant), hypridle, hyprsunset, the polkit
agent and the clipboard watcher (`.config/hypr/config/autostart.lua`).

Screen: `.config/hypr/config/monitors.lua` uses the panel's native mode at scale 1.
Run `hyprctl monitors` to see your output's name and modes.

Idle (`.config/hypr/hypridle.conf`): dim after 5 min, lock after 10, suspend after 20.

## 5. Optional parts

Each has its own script with comments at the top explaining exactly what it does.

### Login screen (greetd + Quickshell)

```sh
~/dotfiles/greeter/install.sh
```

Installs greetd and the login screen, but does **not** switch display managers;
the script prints the command for that. `Tab` on the login screen cycles sessions
(GNOME stays available as a fallback). The login screen follows your wallpaper and
colors: matugen's hook copies them to `/var/lib/qs-greeter`.

### Boot splash and quiet boot

```sh
~/dotfiles/boot/install.sh
```

A minimal Plymouth theme (your laptop maker's logo, the EndeavourOS logo, a progress
bar), quiet kernel options in `/etc/kernel/cmdline`, and a hidden boot menu
(hold `Space` while booting to show it; it remembers the last choice).
The undo steps are at the top of the script.

### Zen browser

1. `yay -S zen-browser-bin`, open Zen once, finish its welcome screens, close it.
2. Run `~/dotfiles/browser/zen-install.sh`: links `user.js` and `userChrome.css`
   into the profile, sets up Pywalfox, makes Zen the default browser.
3. In Zen, install **Pywalfox**, **uBlock Origin** and **Bitwarden** (links are
   printed), then press *Fetch Pywal colors* in Pywalfox.

Zen ≥ 1.18.6b keeps profiles in `~/.config/zen` (not `~/.zen`); the script handles that.

### YouTube in mpv

```sh
~/dotfiles/media/install.sh
```

mpv + yt-dlp (best quality), mpv-mpris (the bar's island, lyrics, media keys),
uosc controls in your colors, SponsorBlock, and ff2mpv. Then install the **ff2mpv**
extension in Zen for *right-click → Play in MPV*. In the launcher, `yt <words>`
searches YouTube and plays the pick in mpv.

### Single-color app icons

```sh
~/dotfiles/icons/install.sh
```

Installs YAMIS (Yet Another Monochrome Icon Set, GPL-3.0) and writes a copy in
your accent, `~/.local/share/icons/YAMIS-matugen`, which matugen rewrites on every
wallpaper change (about half a second). GTK apps use it; Papirus-Dark stays the
fallback for icons YAMIS doesn't have. The shell paints YAMIS icons in the live
accent itself. Apps that are already open pick up new icons when restarted.

### Helium (legacy)

`browser/install.sh` and the `helium` matugen template come from before Zen. They do
nothing unless Helium is installed and can be removed.

## Updating

```sh
cd ~/dotfiles && git pull && stow --restow .
```

The shell reloads itself when its files change. Hyprland reloads with `hyprctl reload`.
