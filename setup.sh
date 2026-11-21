#!/usr/bin/env bash
# Dotfiles setup for EndeavourOS / Arch.
#   ./setup.sh            install packages, link dotfiles, first colors (Phase A)
#   ./setup.sh --system   also install zram + console autologin (Phase B, clean install only)
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
WITH_SYSTEM=false
[[ "${1:-}" == "--system" ]] && WITH_SYSTEM=true

say() { printf '\n[setup] %s\n' "$*"; }
die() { printf '\n[fail] %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "run as your user, not root"
command -v pacman >/dev/null || die "this script is for Arch-based systems"
command -v yay >/dev/null || die "yay not found (EndeavourOS ships it; install it first)"

PACKAGES=(
  # desktop
  hyprland hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  hyprpolkitagent qt5-wayland qt6-wayland quickshell matugen-bin
  # look
  ttf-firacode-nerd adw-gtk-theme
  # terminal and shell
  ghostty zsh oh-my-posh-bin neovim stow git lua
  zoxide fzf ripgrep bat eza fd yazi btop fastfetch lazygit git-delta github-cli tmux
  # desktop helpers
  cliphist wl-clipboard hyprshot grim slurp cava brightnessctl playerctl upower libnotify
  # system TUIs and services
  bluez bluez-utils bluetui wiremix power-profiles-daemon pkgfile
  # media
  mpv mpv-mpris yt-dlp
  # neovim language servers (mason) need these
  nodejs npm unzip
  # browser
  helium-browser
)

say "installing packages (yay will ask before changing anything)"
yay -S --needed "${PACKAGES[@]}"

say "enabling services"
sudo systemctl enable --now bluetooth power-profiles-daemon pkgfile-update.timer
sudo pkgfile -u || true

say "making real folders first, so stow links files inside them instead of whole folders"
mkdir -p "$HOME/.config" "$HOME/Pictures/Screenshots" "$HOME/Pictures/wallpapers"

say "backing up existing files that would block stow -> $BACKUP"
cd "$REPO"
while IFS= read -r f; do
  target="$HOME/$f"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    mv "$target" "$BACKUP/$f"
    echo "  moved ~/$f"
  fi
done < <(git ls-files | grep -vE '^(README|SETUP\.md|setup\.sh|system/|\.gitignore|\.stow-local-ignore)')

say "linking dotfiles"
stow --no-folding --restow --target="$HOME" .

if [[ "$SHELL" != *zsh ]]; then
  say "switching your shell to zsh"
  chsh -s /usr/bin/zsh
fi

if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
  say "installing tmux plugin manager"
  git clone -q https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

say "generating colors from a wallpaper"
wall="$(find "$HOME/Pictures/wallpapers" -type f | grep -iE '[.](jpe?g|png|webp)$' | head -n1 || true)"
if [[ -n "$wall" ]]; then
  matugen image -m dark "$wall"
else
  echo "  no wallpaper found in ~/Pictures/wallpapers; add one and run: matugen image -m dark <file>"
fi

say "dark GTK theme"
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark || true
gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true

if $WITH_SYSTEM; then
  say "zram swap"
  sudo cp "$REPO/system/zram-generator.conf" /etc/systemd/zram-generator.conf
  sudo systemctl daemon-reload
  sudo systemctl start systemd-zram-setup@zram0.service || true

  say "console autologin for $USER (only safe with disk encryption)"
  sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
  sed "s/USERNAME/$USER/" "$REPO/system/autologin.conf" \
    | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null
fi

say "done. Next:"
cat <<'MSG'
  1. gh auth login            (git push over https)
  2. log out, pick Hyprland at the login screen (or reboot after --system)
  3. you land on the lock screen: type your password
  4. Super + /  shows every keybind
  If something is missing: killall quickshell; quickshell   (prints QML errors)
MSG
