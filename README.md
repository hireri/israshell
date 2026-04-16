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

## Configuration

example `config.json` (what i use):

```json
{
{
    "spinningCover": true,
    "showSeconds": false,
    "hourFormat": 1,
    "carouselSpeed": 30,
    "transparentBar": false,
    "fontFamily": "Inter",
    "trayBlacklist": [
        "spotify",
        "blueman",
        "Network"
    ],
    "tintTrayIcons": true,
    "nightLightTemp": 4000,
    "dayLightTemp": 6500,
    "floatingBar": false,
    "huggingBar": true,
    "screenCorners": true,
    "dateFormat": 0,
    "osdPosition": 1,
    "darkMode": true,
    "desktopClock": true,
    "clock": {
        "fontFamily": "Nunito ExtraBold", // yay -S ttf-nunito
        "layout": "vertical",
        "showSeconds": true,
        "hourSize": 100,
        "minuteSize": 100,
        "hourWeight": 75,
        "minuteWeight": 75,
        "dateSize": 25,
        "timeSpacing": -50,
        "dateSpacing": -15,
        "showDate": true,
        "align": "left",
        "colorRole": "primary",
        "subColorRole": "secondary",
        "shadowBlur": 16
    },
    "clockPositions": {
        "DP-2": {
            "x": 1941,
            "y": 836
        },
        "HDMI-A-1": {
            "x": 1420,
            "y": 682
        }
    }
}
}
```

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
```

## Dependencies

- **Core**: `quickshell`, `hyprland`, `hyprsunset`, `hypridle`
- **Visuals**: `matugen`, `awww`
- **Services**: `networkmanager`, `blueman`, `pipewire`, `wireplumber`, `bluez`, `bluez-utils`
- **Qt6 Modules**: `qt6-declarative`, `qt6-5compat`, `qt6-svg`
- **Utilities**: `clipvault`, `rdap`, `kakasi`, `mpv`, `wl-clipboard`, `xdg-utils`, `pavucontrol`
- **Python Stack**: `python`, `python-numpy`, `python-pillow`, `python-scipy`, `python-matplotlib`, `python-gtts`
- **Fonts**: `inter-font`, `ttf-roboto-mono`

```bash
yay -Q quickshell hyprland hyprsunset hypridle matugen awww \
        networkmanager blueman pipewire wireplumber bluez bluez-utils \
        qt6-declarative qt6-5compat qt6-svg clipvault rdap kakasi \
        mpv wl-clipboard xdg-utils pavucontrol inter-font \
        python python-numpy python-pillow python-scipy python-matplotlib python-gtts ttf-roboto-mono
```
i might have missed some. lmk.