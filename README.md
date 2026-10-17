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

<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/033fde28-ad3a-421e-8231-4d4dca4cf69f" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/059b89e3-2030-4c76-837d-d9b102917237" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/3431fde7-13c2-4487-9cab-c6336ee562cc" width="100%"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/9a86153a-80bf-4a05-be05-5ec10418680a" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/447903ba-f902-4012-af74-48c1d5c5f4da" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/eaabbb78-64e0-4ec6-bf60-5a9c913e7a49" width="100%"></td>
  </tr>
</table>


A Quickshell shell for Hyprland 0.55+. Uses matugen colors, smart desktop clock widget, and provides its own notification/tray implementation. Configurable font with default Inter NerdFont.

## Features

- **Top bar** — Workspaces, window title, media controls, tray. Floating or hugging layout.
- **Quick settings** — NetworkManager, Pipewire volume, brightness, night light, caffeine toggle.
- **Launcher** — App search, emoji picker (`:`), clipboard (`;`). Context widgets for math, translation, colors, whois, unit conversions...
- **Desktop clock** — Horizontal, vertical, analog, or word (text) layouts. Auto positions finding the least busy spot for itself.
- **Wallpaper picker** — Directory browser with breadcrumb and image preview.
- **Overlays** — Power menu, volume OSD, optional rounded display corners.
- **Settings app** — Configure your bar, connectivity and other options with a visual interface.

## Configuration
Most things are configurable through the settings app now, and is auto generated.
config.json can be updated for finer control (some options may require a restart)

## IPC Targets

All handlers are called with `qs -c isra ipc call <target> <function> [args]`.

| Target | Functions | Notes |
|---|---|---|
| `settings` | `open(page)` | `overview`, `network`, `bar`, `floatingdock`, `background`, `clock`, `display`, `sound`, `gameoverlay`, `aiassistant`, `locale`, `system` |
| `launcher` | `toggle`, `openWith(prefix)` | `openWith ";"` clipboard, `openWith ":"` emoji picker |
| `media` | `togglePlaying`, `play`, `pause`, `next`, `previous` | Controls the displayed player |
| `screenshot` | `activate`, `region`, `window`, `screen`, `ocr`, `cts`, `record` | `activate` = smart screenshot, `record` toggles screen recording |
| `overview` | `toggle`, `open`, `close` | Workspace and window overview |
| `switcher` | `next`, `prev`, `commit` | Alt+Tab style window switcher, `commit` focuses the selected window |
| `lockscreen` | `lock` | |
| `gamemode` | `toggle` | |
| `voice` | `press`, `release`, `toggle`, `cancel` | Speech to text optionally using `wtype` and downloadable whisper models |
| `gameoverlay` | `toggle`, `crosshair(code)`, `unpin` | Crosshair, Performance, audio mixer, capture. `crosshair` takes a Valorant crosshair code, `unpin` unpins everything |
| `bedtime` | `toggle` | |
| `aiassistant` | `toggle` | |
| `powermenu` | `toggle` | |
| `wallpaperpicker` | `toggle` | Opens on the focused monitor |
| `quicksettings` | `toggle` | Opens on the focused monitor |
| `brightness` | `increment`, `decrement`, `sleepBegin`, `restoreAfterWake` | `sleepBegin`/`restoreAfterWake` are for hypridle DPMS hooks |
| `editmode` | `enable`, `disable`, `toggle` | Desktop widget edit mode |
| `system` | `open(page)`, `close`, `toggle`, `pages` | System app: `overview`, `packages`, `storage`, `system`, `screentime`, `settings` |
| `health` | `status`, `results`, `refresh`, `set(key, value)`, `run(action, arg)` | Health checks; `status` includes the detected platform |
| `screentime` | `status`, `today`, `pause`, `resume`, `toggle`, `set(key, value)`, `exportData` | |

## System app: distro support

The System app (`qs -c isra ipc call system open`) picks a package backend and a service backend on startup. They live in `isra/services/platform.js`. Run `qs -c isra ipc call health status` to see which ones it picked (`platform`), or look for the `[HealthService] platform:` line in `qs log`.

| Package manager | Updates | Orphans | Config merges | Cache | Integrity | News |
|---|---|---|---|---|---|---|
| pacman (+ `paru`/`yay` for AUR) | `checkupdates` (pacman-contrib) | ✓ | `.pacnew`/`.pacsave`, `pacdiff` if installed | `paccache` or `pacman -Sc` | `pacman -Dk` | Arch news |
| apt | `apt list --upgradable` (cached lists) | `autoremove` | `.dpkg-dist`/`.dpkg-new`/`.ucf-dist` | `apt-get autoclean` | `dpkg --audit` | |
| dnf | `dnf check-update` | `repoquery --unneeded` | `.rpmnew`/`.rpmsave`, `rpmconf` if installed | `dnf clean packages` | `dnf check` | |
| zypper | `zypper list-updates` (no refresh) | `packages --unneeded` | `.rpmnew`/`.rpmsave` | `zypper clean` | | |
| xbps | `xbps-install -Mun` | `xbps-query -O` | `.new-*` | `xbps-remove -O` | | |
| apk | `apk list -u` | | `.apk-new` | `apk cache clean` | | |

| Init system | Detected by | Service list | Actions |
|---|---|---|---|
| systemd | `/run/systemd/system` | running, failed, and enabled-but-stopped units | `systemctl`, logs via `journalctl` |
| runit | `runsvdir` running (service dir read from its command line) | every `runsv` | `sv`, logs from `/var/log/<name>/current` |
| s6 | `/run/s6-rc` | active or in the `default` bundle | `s6-rc`/`s6-svc` |
| openrc | `/run/openrc` | started, crashed, or in a runlevel | `rc-service` |
| dinit | `dinitctl` socket | everything `dinitctl --system list` prints | `dinitctl` |

Flatpak, disks, SMART, temperatures, battery, memory and time sync (`chronyc`, or `timedatectl` as a fallback) don't depend on the distro. Every fix action opens `kitty` and prints the command before running it. It uses `sudo`, or `doas` when sudo isn't installed. If no backend matches, those checks are hidden and the log says why. Actions that a backend can't do return an error from `health run`.

To add a distro, add an entry to `PKG` or `INIT` in `platform.js` and its name to `PKG_ORDER`/`INIT_ORDER`. A service list prints one `name<TAB>run|down|failed<TAB>enabled 0/1<TAB>uptime seconds` line per service. Update lists print `name<TAB>from<TAB>to`. Tests: `node isra/services/platform.test.cjs`.

Only pacman + runit is tested on real hardware. The other backends are checked against sample output.

## Dependencies

- **Core**: `quickshell`, `hyprland`, `hyprsunset`
- **Visuals**: `matugen`, `awww`, `cava`
- **Services**: `networkmanager`, `pipewire`, `wireplumber`, `bluez`, `bluez-utils`, `nvtop`
- **Qt6 Modules**: `qt6-declarative`, `qt6-5compat`, `qt6-svg`
- **Utilities**: `clipvault`, `rdap`, `kakasi`, `wl-clipboard`, `xdg-utils`, `pavucontrol`, `songrec`, `wl-screenrec`, `slurp`, `grim`, `hyprpicker`, `tesseract`, `ffmpeg`, `libnotify`, `jq`, `satty`, `file`, `brightnessctl`
- **Optional**: `ddcutil` — only if you want brightness control over external monitors
- **Python Stack**: `python`, `python-numpy`, `python-pillow`, `python-scipy`, `python-matplotlib`, `python-gtts`
- **Fonts**: `inter-font`, `ttf-roboto-mono` (fonts are configurable)
- **LocalSend**: [`localsendd`](https://pypi.org/project/localsendd/) — `uv tool install localsendd` or `pipx install localsendd` (not packaged, so not in the `yay -Q` line below)

```bash
yay -Q quickshell hyprland hyprsunset matugen awww cava \
        networkmanager pipewire wireplumber bluez bluez-utils nvtop \
        qt6-declarative qt6-5compat qt6-svg clipvault rdap kakasi \
        wl-clipboard xdg-utils pavucontrol inter-font \
        python python-numpy python-pillow python-scipy python-matplotlib python-gtts ttf-roboto-mono \
        songrec wl-screenrec slurp grim hyprpicker tesseract ffmpeg libnotify jq satty file \
        brightnessctl
```
i might have missed some. lmk.
