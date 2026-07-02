# dots-mangowm

Port of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (15k ★) from Hyprland → **MangoWM**.

## What's ported

| Component | Status |
|-----------|--------|
| **MangoWM config** (keybinds, rules, animations, blur, shadows) | ✅ Done |
| **Quickshell shell** (bar, sidebars, lock, background, notifications, media, etc.) | ✅ IPC rewritten (`mmsg` API) |
| **Material You colors** (matugen) | ✅ Unchanged |
| **App configs** (kitty, foot, fuzzel, mpv, gtk, fish) | ✅ Unchanged |
| **Tiling layout switcher** | ✅ Added |
| **Lock screen** (swaylock) | ✅ Configured |
| **Startup scripts** | ✅ Ported |

## Structure

```
dots/.config/
├── mango/              MangoWM compositor config
│   ├── Keybinds.conf   All keybinds from end-4 (ported)
│   ├── General.conf    Gaps, borders, input, gestures
│   ├── Blur.conf       Blur settings
│   ├── Shadows.conf    Shadow settings
│   ├── Animations.conf Animation curves & presets
│   ├── Rules.conf      Window & layer rules
│   ├── Env.conf        Environment variables
│   └── autostart.conf  Startup programs
├── quickshell/ii/      The graphical shell (unchanged from end-4)
│   └── services/       IPC services using real mmsg commands (tag‑based WM, plain‑text)
├── swaylock/           Lock screen config
├── matugen/            Color generation (unchanged)
├── (kitty, foot, fuzzel, mpv, etc.) — all unchanged
```

## Requirements

- [MangoWM](https://github.com/mangowm/mangowm) — tiling Wayland compositor
- [Quickshell](https://quickshell.outfoxxed.me/) — QtQuick widget system
- Python deps: `matugen` (Material color generation)

## Install

**One-liner (recommended):**
```sh
bash <(curl -fsSL https://raw.githubusercontent.com/Collalaoo/dots-mangowm/main/bootstrap.sh)
```

**Or manually:**
```sh
git clone https://github.com/Collalaoo/dots-mangowm.git ~/.dotfiles
cd ~/.dotfiles
bash bootstrap.sh
```

## Credits

Based on [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — all credit for the shell design goes to end-4.
