# **israshell**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Distro](https://img.shields.io/badge/optimized_for-Arch_Linux-1793d1.svg?logo=arch-linux)
![Compositor](https://img.shields.io/badge/compositor-Hyprland-brightgreen.svg)

https://github.com/user-attachments/assets/a8801fbd-5926-4c2e-8c5f-b0d1f30682bb

A Quickshell shell for Hyprland. Uses matugen colors, smart desktop clock widget, and provides its own notification/tray implementation. Configurable font with default Inter NerdFont.

## Features

- **Top bar** — Workspaces, window title, media controls, tray. Floating or hugging layout.
- **Quick settings** — NetworkManager, Blueman, Pipewire volume, hyprsunset night light, caffeine toggle.
- **Launcher** — App search, emoji picker (`:`), clipboard (`;`). Context widgets for math, translation, colors, whois, unit conversions...
- **Desktop clock** — Horizontal, vertical, analog, or word (text) layouts. Auto positions finding the least busy spot for itself.
- **Wallpaper picker** — Directory browser with breadcrumb and image preview.
- **Overlays** — Power menu, volume OSD, optional rounded display corners.
- **Settings app** — Configure your bar, connectivity and other options with a visual interface.

## Configuration
Most things are configurable through the settings app now, and is auto generated.
config.json can be updated for finer control (some options may require a restart)

## Hyprland binds

All available binds, this is my config:

```ini
bind = $mainMod, O, global, quickshell:openQuickSettings
bind = $mainMod, M, global, quickshell:openPowerMenu
bind = $mainMod, W, global, quickshell:openWallpaperPicker

bindr = $mainMod, super_l, exec, qs ipc call launcher toggle
bind = $mainMod, V, exec, qs ipc call launcher openWith ";"
bind = $mainMod, Period, exec, qs ipc call launcher openWith ":"

bind = $mainMod SHIFT, N, exec, qs ipc call media next
bind = $mainMod SHIFT, P, exec, qs ipc call media togglePlaying
bind = $mainMod SHIFT, B, exec, qs ipc call media previous

bind = $mainMod, I, exec, qs -n -p ~/.config/quickshell/settings.qml

# open settings into a page
# bind = $mainMod, N, exec, QS_PAGE=network qs -n -p ~/.config/quickshell/settings.qml 
# overview | network | bar | clock | display | sound | immeria | system
# immeria being ai btw.
```

## Dependencies

- **Core**: `quickshell`, `hyprland`, `hyprsunset`, `hypridle`
- **Visuals**: `matugen`, `awww`
- **Services**: `networkmanager`, `blueman`, `pipewire`, `wireplumber`, `bluez`, `bluez-utils`
- **Qt6 Modules**: `qt6-declarative`, `qt6-5compat`, `qt6-svg`
- **Utilities**: `clipvault`, `rdap`, `kakasi`, `mpv`, `wl-clipboard`, `xdg-utils`, `pavucontrol`, `songrec`, `wl-screenrec`, `slurp`, `grim`, `hyprpicker`, `tesseract`, `ffmpeg`, `libnotify`, `jq`, `satty`, `file`
- **Python Stack**: `python`, `python-numpy`, `python-pillow`, `python-scipy`, `python-matplotlib`, `python-gtts`
- **Fonts**: `inter-font`, `ttf-roboto-mono`

```bash
yay -Q quickshell hyprland hyprsunset hypridle matugen awww \
        networkmanager blueman pipewire wireplumber bluez bluez-utils \
        qt6-declarative qt6-5compat qt6-svg clipvault rdap kakasi \
        mpv wl-clipboard xdg-utils pavucontrol inter-font \
        python python-numpy python-pillow python-scipy python-matplotlib python-gtts ttf-roboto-mono \
        songrec wl-screenrec slurp grim hyprpicker tesseract ffmpeg libnotify jq satty file
```
i might have missed some. lmk.