pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import qs.services
import qs.icons
import qs.components.qstiles

Singleton {
    id: root

    readonly property var sizeSteps: [25, 50, 75, 100]

    function openSettings(page: string): void {
        PanelService.closeAll();
        appletProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", page];
        appletProc.running = true;
    }

    function runScreencap(verb: string): void {
        PanelService.closeAll(true);
        captureProc.command = ["qs", "-c", "isra", "ipc", "call", "screenshot", verb];
        captureProc.running = true;
    }

    function runColorPicker(): void {
        PanelService.closeAll(true);
        colorPickerProc.running = true;
    }

    Component {
        id: wifiCompactComp
        CompactToggleTile {
            iconComponent: WifiIcon {
                iconSize: 16
                mode: (NetworkService.wifiEnabled && NetworkService.wifiConnected) ? "wifi" : (NetworkService.ethConnected ? "ethernet" : "disconnected")
                strength: NetworkService.wifiSignal
                secured: {
                    if (!NetworkService.activeNetwork) return false;
                    const sec = NetworkService.activeNetwork.security;
                    return sec !== "" && sec !== "--";
                }
            }
            active: NetworkService.wifiEnabled || NetworkService.ethConnected
            onToggled: NetworkService.toggle()
            onRightClicked: root.openSettings("network")
        }
    }

    Component {
        id: wifiWideComp
        WideActionTile {
            offSecondary: true
            active: NetworkService.wifiEnabled || NetworkService.ethConnected
            label: {
                if (NetworkService.wifiEnabled) {
                    if (NetworkService.wifiConnecting)
                        return "Connecting...";
                    if (NetworkService.wifiConnected && NetworkService.wifiSsid !== "")
                        return NetworkService.wifiSsid;
                    return "Not Connected";
                }
                if (NetworkService.ethConnected)
                    return "Ethernet";
                return "Wi-Fi Off";
            }
            sublabel: {
                if (NetworkService.wifiConnected)
                    return NetworkService.wifiSignal + "% signal";
                if (NetworkService.ethConnected && !NetworkService.wifiEnabled)
                    return "Wired";
                return "";
            }
            iconComponent: WifiIcon {
                iconSize: 22
                mode: (NetworkService.wifiEnabled && NetworkService.wifiConnected) ? "wifi" : (NetworkService.ethConnected ? "ethernet" : "disconnected")
                strength: NetworkService.wifiSignal
                secured: {
                    if (!NetworkService.activeNetwork) return false;
                    const sec = NetworkService.activeNetwork.security;
                    return sec !== "" && sec !== "--";
                }
            }
            onToggled: NetworkService.toggle()
            onRightClicked: root.openSettings("network")
        }
    }

    Component {
        id: bluetoothCompactComp
        CompactToggleTile {
            iconComponent: BluetoothIcon {
                iconSize: 16
                enabled: BluetoothService.enabled
                discovering: BluetoothService.discovering
                connected: BluetoothService.connectedDevices.length > 0
            }
            active: BluetoothService.enabled
            onToggled: BluetoothService.toggle()
            onRightClicked: root.openSettings("network")
        }
    }

    Component {
        id: bluetoothWideComp
        WideActionTile {
            offSecondary: true
            active: BluetoothService.enabled
            iconComponent: BluetoothIcon {
                iconSize: 22
                connected: BluetoothService.connectedDevices.length > 0
                enabled: BluetoothService.enabled
                discovering: BluetoothService.discovering
            }
            label: {
                if (!BluetoothService.enabled)
                    return "Bluetooth Off";
                const dev = BluetoothService.firstConnected;
                if (dev)
                    return dev.name;
                if (BluetoothService.discovering)
                    return "Scanning...";
                return "Bluetooth On";
            }
            sublabel: {
                const dev = BluetoothService.firstConnected;
                if (dev && dev.battery > 0) {
                    let pct = Math.round(dev.battery * 100);
                    return BluetoothService.batteryIcon(pct) + " " + pct + "%";
                }
                const n = BluetoothService.connectedCount;
                if (n > 1)
                    return n + " devices";
                return "";
            }
            onToggled: BluetoothService.toggle()
            onRightClicked: root.openSettings("network")
        }
    }

    Component {
        id: caffeineCompactComp
        CompactToggleTile {
            active: CaffeineService.active
            iconComponent: MaterialIcon {
                name: "caffeine"
                iconSize: 22
                filled: CaffeineService.active
                transitionType: "wipe-up"
            }
            onToggled: CaffeineService.toggle()
        }
    }

    Component {
        id: caffeineWideComp
        SimpleIconLabelTile {
            active: CaffeineService.active
            label: "Caffeine"
            iconComponent: MaterialIcon {
                name: "caffeine"
                iconSize: 22
                filled: CaffeineService.active
                transitionType: "wipe-up"
            }
            onToggled: CaffeineService.toggle()
        }
    }

    Component {
        id: nightlightCompactComp
        CompactToggleTile {
            active: NightLightService.active
            iconComponent: MaterialIcon {
                name: "nightlight"
                iconSize: 22
                filled: NightLightService.active
            }
            onToggled: NightLightService.toggle()
            onRightClicked: root.openSettings("display")
        }
    }

    Component {
        id: nightlightWideComp
        NightLightWideTile {
            offSecondary: true
            active: NightLightService.active
            label: "Night Light"
            iconComponent: MaterialIcon {
                name: "nightlight"
                iconSize: 22
                filled: NightLightService.active
            }
            onToggled: NightLightService.toggle()
            onRightClicked: root.openSettings("display")
        }
    }

    Component { id: powerProfileCompactComp; PowerProfileCompactTile {} }
    Component { id: powerProfileWideComp; PowerProfileWideTile {} }

    Component { id: mediaMiniCompactComp; MediaMiniCompactTile {} }
    Component { id: mediaMiniWideComp; MediaMiniWideTile {} }

    Component {
        id: localsendCompactComp
        CompactToggleTile {
            active: Config.localsend.enabled
            iconComponent: MaterialIcon {
                name: "wifi-tethering"
                iconSize: 22
            }
            onToggled: LocalSendService.setEnabled(!Config.localsend.enabled)
            onRightClicked: root.openSettings("system")
        }
    }

    Component {
        id: localsendWideComp
        WideActionTile {
            active: Config.localsend.enabled
            label: "LocalSend"
            sublabel: {
                if (!Config.localsend.enabled)
                    return "";
                if (!LocalSendService.reachable)
                    return "Starting...";
                if (LocalSendService.transferring)
                    return "Transferring...";
                if (LocalSendService.devices.length > 0)
                    return LocalSendService.devices.length + " nearby";
                return "Ready";
            }
            iconComponent: MaterialIcon {
                name: "wifi-tethering"
                iconSize: 22
            }
            onToggled: LocalSendService.setEnabled(!Config.localsend.enabled)
            onRightClicked: root.openSettings("system")
        }
    }

    Component {
        id: screenshotCompactComp
        CompactToggleTile {
            active: false
            iconComponent: MaterialIcon {
                name: "screenshot"
                iconSize: 22
            }
            onToggled: root.runScreencap("activate")
        }
    }

    Component {
        id: screenshotWideComp
        SimpleIconLabelTile {
            active: false
            label: "Screenshot"
            iconComponent: MaterialIcon {
                name: "screenshot"
                iconSize: 22
            }
            onToggled: root.runScreencap("activate")
        }
    }

    Component {
        id: colorPickerCompactComp
        CompactToggleTile {
            active: false
            iconComponent: MaterialIcon {
                name: "colorize"
                iconSize: 22
                transitionType: "none"
            }
            onToggled: root.runColorPicker()
        }
    }

    Component {
        id: colorPickerWideComp
        SimpleIconLabelTile {
            active: false
            label: "Color Picker"
            iconComponent: MaterialIcon {
                name: "colorize"
                iconSize: 22
                transitionType: "none"
            }
            onToggled: root.runColorPicker()
        }
    }

    Component {
        id: ctsCompactComp
        CompactToggleTile {
            active: false
            iconComponent: MaterialIcon {
                name: "image-search"
                iconSize: 22
            }
            onToggled: root.runScreencap("cts")
        }
    }

    Component {
        id: ctsWideComp
        SimpleIconLabelTile {
            active: false
            label: "Circle to Search"
            iconComponent: MaterialIcon {
                name: "image-search"
                iconSize: 22
            }
            onToggled: root.runScreencap("cts")
        }
    }

    Component {
        id: ocrCompactComp
        CompactToggleTile {
            active: false
            iconComponent: MaterialIcon {
                name: "ocr"
                iconSize: 22
            }
            onToggled: root.runScreencap("ocr")
        }
    }

    Component {
        id: ocrWideComp
        SimpleIconLabelTile {
            active: false
            label: "OCR Text"
            iconComponent: MaterialIcon {
                name: "ocr"
                iconSize: 22
            }
            onToggled: root.runScreencap("ocr")
        }
    }

    Component {
        id: recordCompactComp
        RecordCompactTile {
            active: ScreencapService.isRecording
            onToggled: root.runScreencap("record")
        }
    }

    Component {
        id: recordWideComp
        RecordWideTile {
            active: ScreencapService.isRecording
            label: "Record"
            iconComponent: MaterialIcon {
                name: "record"
                iconSize: 22
                transitionType: "none"
            }
            onToggled: root.runScreencap("record")
        }
    }

    Component {
        id: darkThemeCompactComp
        CompactToggleTile {
            active: WallpaperService.isDark
            iconComponent: MaterialIcon {
                name: "contrast"
                iconSize: 22
                filled: WallpaperService.isDark
                transitionType: "none"
            }
            onToggled: WallpaperService.isDark = !WallpaperService.isDark
            onRightClicked: root.openSettings("display")
        }
    }

    Component {
        id: darkThemeWideComp
        DarkThemeWideTile {
            active: WallpaperService.isDark
            label: "Dark Theme"
            iconComponent: MaterialIcon {
                name: "contrast"
                iconSize: 22
                filled: WallpaperService.isDark
            }
            onToggled: WallpaperService.isDark = !WallpaperService.isDark
            onRightClicked: root.openSettings("display")
        }
    }

    Component {
        id: gameModeCompactComp
        CompactToggleTile {
            active: GameModeService.active
            iconComponent: MaterialIcon {
                name: "game-mode"
                iconSize: 22
                filled: GameModeService.active
                transitionType: "wipe-up"
            }
            onToggled: GameModeService.toggle()
        }
    }

    Component {
        id: gameModeWideComp
        SimpleIconLabelTile {
            active: GameModeService.active
            label: "Game Mode"
            iconComponent: MaterialIcon {
                name: "game-mode"
                iconSize: 22
                filled: GameModeService.active
                transitionType: "wipe-up"
            }
            onToggled: GameModeService.toggle()
        }
    }

    Process { id: appletProc }
    Process { id: captureProc }
    Process { id: colorPickerProc; command: ["hyprpicker", "--autocopy"] }

    readonly property var definitions: [
        { id: "wifi",         label: "Wi-Fi",          compactComponent: wifiCompactComp,         wideComponent: wifiWideComp },
        { id: "bluetooth",    label: "Bluetooth",      compactComponent: bluetoothCompactComp,    wideComponent: bluetoothWideComp },
        { id: "caffeine",     label: "Caffeine",       compactComponent: caffeineCompactComp,      wideComponent: caffeineWideComp },
        { id: "nightlight",   label: "Night Light",    compactComponent: nightlightCompactComp,    wideComponent: nightlightWideComp },
        { id: "powerProfile", label: "Power Profile",  compactComponent: powerProfileCompactComp,  wideComponent: powerProfileWideComp },
        { id: "gameMode",     label: "Game Mode",      compactComponent: gameModeCompactComp,      wideComponent: gameModeWideComp },
        { id: "localsend",    label: "LocalSend",      compactComponent: localsendCompactComp,     wideComponent: localsendWideComp },
        { id: "screenshot",   label: "Screenshot",     compactComponent: screenshotCompactComp,    wideComponent: screenshotWideComp },
        { id: "record",       label: "Record",         compactComponent: recordCompactComp,        wideComponent: recordWideComp },
        { id: "colorPicker",  label: "Color Picker",   compactComponent: colorPickerCompactComp,   wideComponent: colorPickerWideComp },
        { id: "cts",          label: "Circle to Search", compactComponent: ctsCompactComp,         wideComponent: ctsWideComp },
        { id: "ocr",          label: "OCR Text",       compactComponent: ocrCompactComp,           wideComponent: ocrWideComp },
        { id: "darkTheme",    label: "Dark Theme",     compactComponent: darkThemeCompactComp,     wideComponent: darkThemeWideComp },
        { id: "mediaMini",    label: "Media Player",   compactComponent: mediaMiniCompactComp,     wideComponent: mediaMiniWideComp }
    ]

    readonly property var allIds: definitions.map(d => d.id)

    readonly property var defaultDisabledIds: ["localsend", "screenshot", "record", "colorPicker", "cts", "ocr", "darkTheme", "mediaMini"]

    readonly property var compactComponentMap: {
        const m = {};
        for (const d of definitions)
            m[d.id] = d.compactComponent;
        return m;
    }

    readonly property var wideComponentMap: {
        const m = {};
        for (const d of definitions)
            m[d.id] = d.wideComponent;
        return m;
    }

    readonly property var labelMap: {
        const m = {};
        for (const d of definitions)
            m[d.id] = d.label;
        return m;
    }

    function defaultLayout() {
        const disabled = new Set(defaultDisabledIds);
        return {
            active: definitions.filter(d => !disabled.has(d.id)).map(d => ({ id: d.id, size: (d.id === "wifi" || d.id === "bluetooth") ? 100 : 50 })),
            removed: definitions.filter(d => disabled.has(d.id)).map(d => d.id)
        };
    }

    function reconcile(tilesConfig) {
        const valid = new Set(allIds);
        const active = (tilesConfig?.active ?? []).filter(t => valid.has(t.id));
        const removed = (tilesConfig?.removed ?? []).filter(id => valid.has(id));

        const known = new Set([...active.map(t => t.id), ...removed]);
        const missing = allIds.filter(id => !known.has(id));

        const droppedCount = (tilesConfig?.active?.length ?? 0) + (tilesConfig?.removed?.length ?? 0);
        const keptCount = active.length + removed.length;

        if (missing.length === 0 && droppedCount === keptCount)
            return tilesConfig;

        const disabled = new Set(defaultDisabledIds);
        const appended = missing.filter(id => !disabled.has(id)).map(id => ({ id, size: (id === "wifi" || id === "bluetooth") ? 100 : 50 }));
        const appendedRemoved = missing.filter(id => disabled.has(id));

        return {
            active: [...active, ...appended],
            removed: [...removed, ...appendedRemoved]
        };
    }
}
