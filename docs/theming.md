# Theming: wallpaper → colors

One wallpaper decides every color. [matugen](https://github.com/InioX/matugen)
derives a Material You dark palette from it and fills templates for each app.

## The flow

1. Pick a wallpaper (`Super + W`, or `qs ipc call wallpaper set <path>`).
2. `services/Wall.qml` saves its path to `~/.local/state/wallpaper` and runs
   `matugen image -m dark --source-color-index 0 <path>`.
3. matugen writes every template below and runs their hooks.
4. Each app picks the new colors up, most of them live.

Wallpapers live in `~/Pictures/wallpapers` (`.jpg`, `.png`, `.webp`).

## What gets colored

From `.config/matugen/config.toml`:

| Template | Written to | Applied |
|---|---|---|
| `Colors.qml` | `~/.config/quickshell/theme/Colors.qml` | live (the shell reloads on change); also synced to the login screen |
| `colors.lua` | `~/.config/hypr/theme/colors.lua` | `hyprctl reload` (borders, background) |
| `ghostty` | `~/.config/ghostty/themes/matugen` | live (`SIGUSR2` to Ghostty) |
| `gtk3.css`, `gtk4.css` | `~/.config/gtk-3.0/gtk.css`, `~/.config/gtk-4.0/gtk.css` | when GTK apps start |
| `nvim.lua` | `~/.config/nvim/colors/matugen.lua` | live in running Neovim (`SIGUSR1`) |
| `btop.theme` | `~/.config/btop/themes/matugen.theme` | when btop starts |
| `lazygit.yml` | `~/.config/lazygit/config.yml` | when lazygit starts |
| `qt6ct.conf` | `~/.config/qt6ct/colors/matugen.conf` | when Qt apps start |
| `uosc.conf` | `~/.config/mpv/script-opts/uosc.conf` | when mpv starts |
| `pywal-colors.json` | `~/.cache/wal/colors.json` | live in Zen (`pywalfox update`) |
| `helium-color.json` | `/etc/helium/policies/managed/color.json` | legacy, only if Helium is set up |

Generated files are listed in `.gitignore`; they are never committed.

Other apps follow without a template: yazi and fzf use the terminal's 16 colors,
bat uses its `ansi` theme, and the login screen gets the shell's colors through
`.config/matugen/hooks/greeter-sync`.

## The style the shell uses

The colors come in a few roles (`theme/Colors.qml`): `bg`, `panel`, `raised`,
`border`, `fg`, `fgMuted`, `accent`, `accentFg`, `secondary`, `tertiary`, `alert`, `ok`.
The shell mostly uses **one accent in different strengths** (`opacity`, mixing toward
`fg`); `alert` and `ok` are for warnings and good states.

Sizes and fonts are in `theme/Style.qml`: FiraCode Nerd Font, square corners
(`radius 0`), 1 px borders.

## Text size

One knob for everything: the text-size slider in quick settings, or
`qs ipc call textsize set 1.15`. It sets the shell's scale
(`~/.local/state/textscale`), GTK's fonts (11 pt × scale, through gsettings) and
Ghostty's font size (`~/.config/ghostty/size.conf`, reloaded live).

## Adding an app

1. Write a template in `.config/matugen/templates/` using matugen's syntax,
   e.g. `{{colors.primary.default.hex}}`.
2. Add a `[templates.<name>]` section to `config.toml` with `input_path`,
   `output_path` and, if the app can reload live, a `post_hook`.
3. Add the output to `.gitignore`.
4. Change wallpaper once to generate it.
