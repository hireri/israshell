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

    function openSettings(page: string): void {
        PanelService.closeAll();
        appletProc.command = ["qs", "-c", "isra", "ipc", "call", "settings", "open", page];
        appletProc.running = true;
    }

    function _formatHourMinute(timeStr) {
        const parts = timeStr.split(":");
        const h = parseInt(parts[0], 10);
        const m = parts[1];
        if (Config.hourFormat === 0)
            return String(h).padStart(2, '0') + ":" + m;
        const hDisp = h % 12 || 12;
        const ap = h >= 12 ? "PM" : "AM";
        return hDisp + ":" + m + " " + (Config.hourFormat === 2 ? ap : ap.toLowerCase());
    }

    function runScreencap(verb: string, closePanel: bool): void {
        if (closePanel)
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
                iconSize: 22
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
                        return Localization.t("networkPage.connecting");
                    if (NetworkService.wifiConnected && NetworkService.wifiSsid !== "")
                        return NetworkService.wifiSsid;
                    return Localization.t("networkPage.not_connected");
                }
                if (NetworkService.ethConnected)
                    return Localization.t("networkPage.ethernet");
                return Localization.t("qsTileService.wifi_off");
            }
            sublabel: {
                if (NetworkService.wifiConnected)
                    return Localization.t("qsTileService.signal_percent").arg(NetworkService.wifiSignal);
                if (NetworkService.ethConnected && !NetworkService.wifiEnabled)
                    return Localization.t("qsTileService.wired");
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
                iconSize: 22
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
                    return Localization.t("qsTileService.bluetooth_off");
                const dev = BluetoothService.firstConnected;
                if (dev)
                    return dev.name;
                if (BluetoothService.discovering)
                    return Localization.t("networkPage.scanning");
                return Localization.t("qsTileService.bluetooth_on");
            }
            sublabel: {
                const dev = BluetoothService.firstConnected;
                if (dev && dev.battery > 0) {
                    let pct = Math.round(dev.battery * 100);
                    return BluetoothService.batteryIcon(pct) + " " + pct + "%";
                }
                const n = BluetoothService.connectedCount;
                if (n > 1)
                    return Localization.t("qsTileService.devices_count").arg(n);
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
            label: Localization.t("qsTileService.caffeine")
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
        WideActionTile {
            offSecondary: true
            active: NightLightService.active
            label: Localization.t("qsTileService.night_light")
            sublabelForOn: on => Config.nightLight.scheduleEnabled
                ? Localization.t(on ? "qsTileService.off_at" : "qsTileService.on_at").arg(root._formatHourMinute(on ? Config.nightLight.sunrise : Config.nightLight.sunset))
                : ""
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
                name: (Config.localsend.enabled && !LocalSendService.reachable) ? "wifi-tethering-error" : "wifi-tethering"
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
            label: Localization.t("qsTileService.localsend")
            sublabel: {
                if (!Config.localsend.enabled)
                    return "";
                if (!LocalSendService.reachable)
                    return Localization.t("qsTileService.starting");
                if (LocalSendService.transferring)
                    return Localization.t("qsTileService.transferring");
                if (LocalSendService.devices.length > 0)
                    return Localization.t("qsTileService.nearby_count").arg(LocalSendService.devices.length);
                return Localization.t("qsTileService.ready");
            }
            iconComponent: MaterialIcon {
                name: (Config.localsend.enabled && !LocalSendService.reachable) ? "wifi-tethering-error" : "wifi-tethering"
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
            onToggled: root.runScreencap("activate", true)
        }
    }

    Component {
        id: screenshotWideComp
        SimpleIconLabelTile {
            active: false
            label: Localization.t("qsTileService.screenshot")
            iconComponent: MaterialIcon {
                name: "screenshot"
                iconSize: 22
            }
            onToggled: root.runScreencap("activate", true)
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
            label: Localization.t("qsTileService.color_picker")
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
            onToggled: root.runScreencap("cts", true)
        }
    }

    Component {
        id: ctsWideComp
        SimpleIconLabelTile {
            active: false
            label: Localization.t("qsTileService.circle_to_search")
            iconComponent: MaterialIcon {
                name: "image-search"
                iconSize: 22
            }
            onToggled: root.runScreencap("cts", true)
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
            onToggled: root.runScreencap("ocr", true)
        }
    }

    Component {
        id: ocrWideComp
        SimpleIconLabelTile {
            active: false
            label: Localization.t("qsTileService.ocr_text")
            iconComponent: MaterialIcon {
                name: "ocr"
                iconSize: 22
            }
            onToggled: root.runScreencap("ocr", true)
        }
    }

    Component {
        id: recordCompactComp
        CompactToggleTile {
            active: ScreencapService.isRecording
            accentColor: Colors.md3.error
            onAccentColor: Colors.md3.on_error
            iconComponent: MaterialIcon {
                name: "record"
                iconSize: 22
                transitionType: "none"
            }
            onToggled: root.runScreencap("record", !ScreencapService.isRecording)
        }
    }

    Component {
        id: recordWideComp
        SimpleIconLabelTile {
            active: ScreencapService.isRecording
            label: Localization.t("qsTileService.record")
            accentColor: Colors.md3.error
            onAccentColor: Colors.md3.on_error
            sublabelForOn: on => on ? ScreencapService.recordingTime : null
            iconComponent: MaterialIcon {
                name: "record"
                iconSize: 22
                transitionType: "none"
            }
            onToggled: root.runScreencap("record", !ScreencapService.isRecording)
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
        WideActionTile {
            active: WallpaperService.isDark
            label: Localization.t("qsTileService.dark_theme")
            sublabelForOn: on => Config.nightLight.autoDarkMode
                ? Localization.t(on ? "qsTileService.light_at" : "qsTileService.dark_at").arg(root._formatHourMinute(on ? Config.nightLight.sunrise : Config.nightLight.sunset))
                : ""
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
        id: dnsCompactComp
        CompactToggleTile {
            active: DnsService.enabled
            iconComponent: DnsProviderIcon {
                iconSize: 20
                provider: DnsService.enabled ? DnsService.currentProvider.id : "off"
            }
            onToggled: DnsService.cycle()
            onRightClicked: DnsService.disable()
        }
    }

    Component {
        id: dnsWideComp
        SimpleIconLabelTile {
            active: DnsService.enabled
            label: DnsService.enabled ? DnsService.currentProvider.label : Localization.t("qsTileService.dns_off")
            iconComponent: DnsProviderIcon {
                iconSize: 22
                provider: DnsService.enabled ? DnsService.currentProvider.id : "off"
            }
            onToggled: DnsService.cycle()
            onRightClicked: DnsService.disable()
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
            label: Localization.t("qsTileService.game_mode")
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
        { id: "wifi",         label: Localization.t("qsTileService.wifi"),          compactComponent: wifiCompactComp,         wideComponent: wifiWideComp },
        { id: "bluetooth",    label: Localization.t("qsTileService.bluetooth"),     compactComponent: bluetoothCompactComp,    wideComponent: bluetoothWideComp },
        { id: "caffeine",     label: Localization.t("qsTileService.caffeine"),      compactComponent: caffeineCompactComp,      wideComponent: caffeineWideComp },
        { id: "nightlight",   label: Localization.t("qsTileService.night_light"),   compactComponent: nightlightCompactComp,    wideComponent: nightlightWideComp },
        { id: "powerProfile", label: Localization.t("qsTileService.power_profile"), compactComponent: powerProfileCompactComp,  wideComponent: powerProfileWideComp },
        { id: "gameMode",     label: Localization.t("qsTileService.game_mode"),     compactComponent: gameModeCompactComp,      wideComponent: gameModeWideComp },
        { id: "localsend",    label: Localization.t("qsTileService.localsend"),     compactComponent: localsendCompactComp,     wideComponent: localsendWideComp },
        { id: "dns",          label: Localization.t("qsTileService.dns"),          compactComponent: dnsCompactComp,           wideComponent: dnsWideComp },
        { id: "screenshot",   label: Localization.t("qsTileService.screenshot"),    compactComponent: screenshotCompactComp,    wideComponent: screenshotWideComp },
        { id: "record",       label: Localization.t("qsTileService.record"),        compactComponent: recordCompactComp,        wideComponent: recordWideComp },
        { id: "colorPicker",  label: Localization.t("qsTileService.color_picker"),  compactComponent: colorPickerCompactComp,   wideComponent: colorPickerWideComp },
        { id: "cts",          label: Localization.t("qsTileService.circle_to_search"), compactComponent: ctsCompactComp,        wideComponent: ctsWideComp },
        { id: "ocr",          label: Localization.t("qsTileService.ocr_text"),      compactComponent: ocrCompactComp,           wideComponent: ocrWideComp },
        { id: "darkTheme",    label: Localization.t("qsTileService.dark_theme"),    compactComponent: darkThemeCompactComp,     wideComponent: darkThemeWideComp },
        { id: "mediaMini",    label: Localization.t("qsTileService.media_player"),  compactComponent: mediaMiniCompactComp,     wideComponent: mediaMiniWideComp }
    ]

    readonly property var allIds: definitions.map(d => d.id)

    readonly property var defaultDisabledIds: ["localsend", "screenshot", "record", "colorPicker", "cts", "ocr", "darkTheme", "mediaMini", "dns"]

    function _indexBy(key) {
        const m = {};
        for (const d of definitions)
            m[d.id] = d[key];
        return m;
    }

    readonly property var compactComponentMap: _indexBy("compactComponent")
    readonly property var wideComponentMap: _indexBy("wideComponent")

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
