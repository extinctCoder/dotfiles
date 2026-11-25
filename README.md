# dotfiles · EndeavourOS + Hyprland + Quickshell

A keyboard-first Wayland desktop: flat, monospaced, square-cornered, and colored
entirely by the wallpaper. Change the wallpaper and the bar, terminal, apps,
browser, video player and login screen all follow.

Built around a few rules:

- **Real data only.** Every number, graph and animation comes from a live source;
  when there is none, it shows `--` or nothing. Nothing moves without a cause.
- **One look.** Mono font (FiraCode Nerd Font), square corners, flat shapes, one
  accent color in different strengths, all generated from the wallpaper by matugen.
- **Calm when idle, cheap when hidden.** The animated desktop pauses whenever
  windows cover it.

## What's inside

| Part | What it is |
|---|---|
| **Hyprland** | tiling compositor, configured in Lua; vim-style keys |
| **Bar** | workspaces with app icons · an *island* (song, volume, notifications, window title) · status items with popups (network, CPU, memory, volume, battery, calendar + weather + world clock) · mic/camera indicators |
| **Quick settings** (`Super + A`) | Wi-Fi, Bluetooth, night light, silent, stay awake, power mode; volume, brightness and text-size sliders; notification history |
| **Launcher** (`Super + Space`) | apps, actions, calculator, files, Zen bookmarks and history, YouTube, web search, clipboard history |
| **Window overview** (`Super + Tab`) | live previews of every workspace; type to jump; drag windows between workspaces |
| **Desktop** | the **living core** (a creature drawn on the GPU from live system data and music), clock, synced lyrics, drives, disk activity, CPU heat, network, sun arc and weather, world timeline, battery curve |
| **Login and boot** | greetd + a Quickshell login screen; a minimal Plymouth splash with a quiet boot |
| **Apps** | Ghostty, Zen (live wallpaper colors), mpv with YouTube (uosc controls, SponsorBlock), yazi, btop, lazygit, Neovim colors, GTK and Qt apps |

## Quick start

On an EndeavourOS install (details, optional parts and undo steps in
[docs/install.md](docs/install.md)):

```sh
yay -S --needed hyprland quickshell matugen ghostty stow \
  hypridle hyprsunset hyprshot hyprpolkitagent cliphist wl-clipboard \
  ttf-firacode-nerd papirus-icon-theme adw-gtk-theme qt6ct \
  brightnessctl playerctl cava pacman-contrib fd curl sqlite lua \
  yazi btop bluetui wiremix
git clone -b EndeavourOS https://github.com/extinctCoder/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow .
mkdir -p ~/.local/state && w=~/Pictures/wallpapers/derrick-cooper.jpg
echo "$w" > ~/.local/state/wallpaper && matugen image -m dark --source-color-index 0 "$w"
```

Then log in to Hyprland on TTY 1 (`.zprofile` starts it), or set up the login screen.

## Everyday use

| Keys | Does |
|---|---|
| `Super + Space` | launcher (`>` actions · `/` files · `@` bookmarks · `=` math · `?` web · `yt ` YouTube) |
| `Super + Enter` | terminal |
| `Super + A` | quick settings and notifications |
| `Super + Tab` | window overview |
| `Super + W` | wallpaper picker (recolors everything) |
| `Super + D` | leader menu: one more key runs an action |
| `Super + /` | searchable cheatsheet of every keybind |

All keybinds: [docs/keybinds.md](docs/keybinds.md).

## Repository layout

```
.config/
  hypr/          Hyprland (Lua): hyprland.lua + config/ (keymap.lua = every keybind)
  quickshell/    the shell: shell.qml, modules/ (UI), services/ (data), theme/, shaders/
  matugen/       wallpaper -> colors: config.toml, templates/, hooks/
  ghostty/ yazi/ btop/ bat/ qt6ct/ mpv/ cava/ zen-theme/ ohmyposh/ ...
Pictures/wallpapers/   wallpapers for the picker
greeter/       login screen (greetd + Quickshell); not stowed, has install.sh
boot/          Plymouth theme and quiet boot; not stowed, has install.sh
browser/       Zen setup (zen-install.sh); Helium setup (install.sh, legacy)
media/         mpv + YouTube setup (install.sh)
docs/          documentation
```

The home-folder parts are linked into place with [GNU Stow](https://www.gnu.org/software/stow/);
`greeter/`, `boot/`, `browser/` and `media/` are skipped by Stow (`.stow-local-ignore`)
and installed by their own scripts.

## Documentation

| Page | Covers |
|---|---|
| [install.md](docs/install.md) | packages, linking, first start, optional parts (login screen, boot splash, Zen, mpv), undo |
| [keybinds.md](docs/keybinds.md) | every keybind, generated from `keymap.lua` |
| [shell.md](docs/shell.md) | how the Quickshell config is built: services, modules, IPC, adding things |
| [living-core.md](docs/living-core.md) | the desktop creature: anatomy, signals, music, rendering and cost |
| [theming.md](docs/theming.md) | the wallpaper-to-colors pipeline and every app it reaches |
| [troubleshooting.md](docs/troubleshooting.md) | logs, common problems, measuring CPU, quick checks |
