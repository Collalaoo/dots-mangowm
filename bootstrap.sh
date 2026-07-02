#!/usr/bin/env bash
set -e

# ── dots-mangowm bootstrap ─────────────────────────────────────────
# Run: bash <(curl -fsSL https://raw.githubusercontent.com/Collalaoo/dots-mangowm/main/bootstrap.sh)
# ────────────────────────────────────────────────────────────────────

REPO="Collalaoo/dots-mangowm"
BRANCH="main"
DOTDIR="$HOME/.dotfiles"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}::${NC} $1"; }
ok()    { echo -e "${GREEN}==>${NC} $1"; }
err()   { echo -e "${RED}!!${NC} $1"; exit 1; }

# ── distro detection ────────────────────────────────────────────────
detect_pkg() {
  if   command -v pacman &>/dev/null; then echo "arch"
  elif command -v dnf    &>/dev/null; then echo "fedora"
  elif command -v zypper &>/dev/null; then echo "opensuse"
  elif command -v apt    &>/dev/null; then echo "debian"
  elif command -v xbps-install &>/dev/null; then echo "void"
  elif command -v emerge &>/dev/null; then echo "gentoo"
  elif command -v nix-env &>/dev/null || [ -f /etc/nixos/configuration.nix ]; then echo "nixos"
  else echo "unknown"; fi
}

install_mangowm() {
  info "Installing MangoWM..."
  case "$1" in
    arch)
      if command -v paru &>/dev/null; then
        paru -S --needed mangowm-git
      elif command -v yay &>/dev/null; then
        yay -S --needed mangowm-git
      else
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/mangowm-git.git /tmp/mangowm
        cd /tmp/mangowm && makepkg -si --noconfirm && cd -
      fi
      ;;
    fedora|opensuse|debian|void|gentoo)
      err "MangoWM + Quickshell must be built from source on $1"
      echo "  See: https://github.com/mangowm/mangowm"
      echo "  See: https://quickshell.outfoxxed.me/"
      exit 1
      ;;
    nixos)
      echo "  Add this to flake.nix:"
      echo '    inputs.mangowm.url = "github:mangowm/mangowm";'
      exit 0
      ;;
  esac
}

install_quickshell() {
  info "Installing Quickshell..."
  case "$1" in
    arch)
      if command -v paru &>/dev/null; then
        paru -S --needed quickshell-git
      elif command -v yay &>/dev/null; then
        yay -S --needed quickshell-git
      else
        git clone https://aur.archlinux.org/quickshell-git.git /tmp/quickshell
        cd /tmp/quickshell && makepkg -si --noconfirm && cd -
      fi
      ;;
  esac
}

install_deps() {
  info "Installing dependencies..."
  case "$1" in
    arch)
      sudo pacman -S --needed --noconfirm \
        foot kitty fuzzel swaylock swayidle wl-clipboard cliphist \
        playerctl brightnessctl grim slurp hyprpicker matugen \
        python python-pip gobject-introspection
      ;;
    fedora)
      sudo dnf install -y foot kitty fuzzel swaylock swayidle wl-clipboard \
        cliphist playerctl brightnessctl grim slurp hyprpicker matugen ||
        info "Some packages may not be available, install manually"
      ;;
    debian)
      sudo apt install -y foot kitty fuzzel swaylock swayidle wl-clipboard \
        playerctl brightnessctl grim slurp python3 python3-pip ||
        info "Some packages may not be available, install manually"
      ;;
    *)
      info "Please install: foot, kitty, fuzzel, swaylock, swayidle, wl-clipboard, cliphist, playerctl, brightnessctl, grim, slurp"
      ;;
  esac
}

link_configs() {
  info "Linking configs..."
  mkdir -p "$HOME/.config"
  for dir in mango quickshell foot kitty fuzzel matugen mpv wlogout swaylock fish fontconfig; do
    target="$HOME/.config/$dir"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      bak="$target.bak.$(date +%s)"
      mv "$target" "$bak"
      info "  Backed up $target → $bak"
    fi
    ln -sf "$DOTDIR/dots/.config/$dir" "$target" 2>/dev/null || true
  done
  # scripts
  mkdir -p "$HOME/.config/hypr"
  ln -sf "$DOTDIR/dots/.config/hypr/hyprland/scripts" "$HOME/.config/hypr/hyprland/scripts"
  ok "Configs linked!"
}

run_patch() {
  info "Patching QML imports for MangoWM..."
  if [ -f "$HOME/.config/hypr/hyprland/scripts/mangowm-patch.sh" ]; then
    bash "$HOME/.config/hypr/hyprland/scripts/mangowm-patch.sh"
    ok "QML files patched!"
  else
    info "Patch script not found, skipping"
  fi
}

# ── main ────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}══════════════════════════════════${NC}"
echo -e "${CYAN}  dots-mangowm bootstrap${NC}"
echo -e "${CYAN}  Port of end-4/dots-hyprland → MangoWM${NC}"
echo -e "${CYAN}══════════════════════════════════${NC}"
echo ""

DISTRO=$(detect_pkg)
info "Detected: ${DISTRO}"

# clone / update
if [ -d "$DOTDIR/.git" ]; then
  info "Updating existing dotfiles..."
  cd "$DOTDIR" && git pull && cd -
else
  info "Cloning ${REPO}..."
  git clone --depth 1 "https://github.com/${REPO}.git" "$DOTDIR"
fi

install_mangowm "$DISTRO"
install_quickshell "$DISTRO"
install_deps "$DISTRO"
link_configs
run_patch

echo ""
ok "Done! Restart MangoWM or run: mangoctl reload"
echo "  Keybind cheatsheet: Super + /"
echo "  Terminal:           Super + Enter"
echo "  App launcher:       Super + Space"
