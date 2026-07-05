<div align="center">
<pre>
▗▄▄▄▖ ▗▄▄▖▗▄▄▖  ▗▄▖  ▗▄▄▖▗▖ ▗▖▗▄▄▄▖▗▖   ▗▖   
  █  ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌   ▐▌   ▐▌   
  █   ▝▀▚▖▐▛▀▚▖▐▛▀▜▌ ▝▀▚▖▐▛▀▜▌▐▛▀▀▘▐▌   ▐▌   
▗▄█▄▖▗▄▄▞▘▐▌ ▐▌▐▌ ▐▌▗▄▄▞▘▐▌ ▐▌▐▙▄▄▖▐▙▄▄▖▐▙▄▄▖
</pre>
</div>

> [!NOTE]
> This is my Quickshell configuration **alone**, you'll have to configure your system around it / edit it to your liking.
> 
> Full dots will probably be available at some point along with an install script.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Distro](https://img.shields.io/badge/optimized_for-Arch_Linux-1793d1.svg?logo=arch-linux)
![Compositor](https://img.shields.io/badge/compositor-Hyprland-brightgreen.svg)


<details>
<summary><b>📷 Screenshots</b></summary>
<br>
<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/c69f75ea-e886-48ea-a32e-86bbb0829aef" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/055668bf-24a6-496c-8927-300f42cb8b3c" width="100%"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/5a79ac19-a0f0-4c84-ab42-b3852192b268" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/cb233eeb-7078-4e86-90db-7ea8fec2dd19" width="100%"></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img src="https://github.com/user-attachments/assets/5a8d74c3-1f82-440a-84ce-d48ca19d84d3" width="50%"></td>
  </tr>
</table>
</details>


A Quickshell shell for Hyprland 0.55+. Uses matugen colors, smart desktop clock widget, and provides its own notification/tray implementation. Configurable font with default Inter NerdFont.

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
hl.bind(mainMod .. " + S", hl.dsp.global("quickshell:openQuickSettings"))
hl.bind(mainMod .. " + M", hl.dsp.global("quickshell:openPowerMenu"))
hl.bind(mainMod .. " + W", hl.dsp.global("quickshell:openWallpaperPicker"))

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs ipc -c isra call lockscreen lock"))

hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("qs -c isra ipc call launcher toggle"), {
    release = true
})
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd('qs -c isra ipc call launcher openWith ";"'))
hl.bind(mainMod .. " + Period", hl.dsp.exec_cmd('qs -c isra ipc call launcher openWith ":"'))


hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("qs -c isra ipc call media next"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("qs -c isra ipc call media togglePlaying"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("qs -c isra ipc call media previous"))


hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("qs -c isra ipc call settings open overview"))

# open settings into a page
# $ qs -c isra ipc call settings open network
# overview | network | bar | clock | display | sound | locale | system

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("qs -c isra ipc call screenshot activate"))


# screenshot has the following modes
# activate | region | window | screen | ocr | cts | record
# activate ig if you dont want to write region at this point, they're the same

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("qs -c isra ipc call screenshot activate"))

hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("qs -c isra ipc call gamemode toggle"))
```

## Dependencies

- **Core**: `quickshell`, `hyprland`, `hyprsunset`, `hypridle`
- **Visuals**: `matugen`, `awww`, `cava`
- **Services**: `networkmanager`, `blueman`, `pipewire`, `wireplumber`, `bluez`, `bluez-utils`
- **Qt6 Modules**: `qt6-declarative`, `qt6-5compat`, `qt6-svg`
- **Utilities**: `clipvault`, `rdap`, `kakasi`, `mpv`, `wl-clipboard`, `xdg-utils`, `pavucontrol`, `songrec`, `wl-screenrec`, `slurp`, `grim`, `hyprpicker`, `tesseract`, `ffmpeg`, `libnotify`, `jq`, `satty`, `file`
- **Python Stack**: `python`, `python-numpy`, `python-pillow`, `python-scipy`, `python-matplotlib`, `python-gtts`
- **Fonts**: `inter-font`, `ttf-roboto-mono` (fonts are configurable)

```bash
yay -Q quickshell hyprland hyprsunset hypridle matugen awww cava\
        networkmanager blueman pipewire wireplumber bluez bluez-utils \
        qt6-declarative qt6-5compat qt6-svg clipvault rdap kakasi \
        mpv wl-clipboard xdg-utils pavucontrol inter-font \
        python python-numpy python-pillow python-scipy python-matplotlib python-gtts ttf-roboto-mono \
        songrec wl-screenrec slurp grim hyprpicker tesseract ffmpeg libnotify jq satty file
```
i might have missed some. lmk.
