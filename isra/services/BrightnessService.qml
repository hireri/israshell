pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.style

Singleton {
    id: root

    property list<BrightnessMonitor> monitors: []
    property var ddcMonitors: []
    property string backlightDevice: ""
    property bool backlightDetectionReady: false
    property int _bestBacklightMax: 0

    readonly property bool _isHyprland: CompositorService.backendName === "hyprland"

    property var lastValidBrightness: ({})
    property bool asleep: false

    function sleepBegin(): void {
        root.asleep = true;
    }

    function restoreAfterWake(): void {
        root.asleep = false;
        root.monitors.forEach(m => m.restoreLastGood());
    }

    function _syncMonitors(): void {
        const prev = Array.from(root.monitors);
        const next = Quickshell.screens.map(screen => {
            const existing = prev.find(m => m.screen === screen) ?? prev.find(m => m.screen?.name === screen?.name);
            if (existing) {
                existing.screen = screen;
                return existing;
            }
            return monitorComp.createObject(root, { screen });
        });
        root.monitors = next;
        for (const m of prev) {
            if (!next.includes(m))
                m.destroy();
        }
    }

    function _detectBacklight(): void {
        root.backlightDetectionReady = false;
        root.backlightDevice = "";
        root._bestBacklightMax = 0;
        backlightDetectProc.running = false;
        backlightDetectProc.running = true;
    }

    Component.onCompleted: {
        _syncMonitors();
        _detectBacklight();
        ddcProc.running = true;
    }

    Connections {
        target: Quickshell
        function onScreensChanged(): void {
            if (root.asleep)
                return;
            root._syncMonitors();
            root._detectBacklight();
            ddcProc.running = true;
        }
    }

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.screen === screen);
    }

    readonly property var focused: monitors.find(m => m.screen?.name === CompositorService.focusedMonitor?.name) ?? monitors[0] ?? null

    readonly property real value: focused?.brightness ?? 1.0
    readonly property real from: 0.01
    readonly property real to: 1.0

    function setBrightness(val: real): void {
        if (Config.linkMonitorBrightness)
            root.monitors.forEach(m => m.setBrightness(val));
        else
            focused?.setBrightness(val);
    }

    function increaseBrightness(): void {
        if (!focused)
            return;
        setBrightness((focused.brightness ?? 0) + 0.05);
    }

    function decreaseBrightness(): void {
        if (!focused)
            return;
        setBrightness((focused.brightness ?? 0) - 0.05);
    }

    Process {
        id: backlightDetectProc
        command: ["brightnessctl", "-l", "-m", "-c", "backlight"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const parts = line.trim().split(",");
                if (parts.length < 5 || parts[1] !== "backlight")
                    return;
                const max = Number(parts[4]);
                if (!Number.isFinite(max) || max <= 0)
                    return;
                if (max > root._bestBacklightMax) {
                    root._bestBacklightMax = max;
                    root.backlightDevice = parts[0];
                }
            }
        }
        onExited: {
            root.backlightDetectionReady = true;
            root.monitors.forEach(m => {
                if (!m.isDdc)
                    m.initialize();
            });
        }
    }

    property var _ddcNext: []

    Process {
        id: ddcProc
        command: ["ddcutil", "detect", "--brief"]
        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: data => {
                if (!data.startsWith("Display "))
                    return;
                const lines = data.split("\n").map(l => l.trim());
                const modelLine = lines.find(l => l.startsWith("Monitor:"));
                const busLine = lines.find(l => l.startsWith("I2C bus:"));
                if (!modelLine || !busLine)
                    return;
                root._ddcNext.push({
                    model: modelLine.split(":")[2]?.trim() ?? "",
                    busNum: busLine.split("/dev/i2c-")[1]
                });
            }
        }
        onRunningChanged: {
            if (running)
                root._ddcNext = [];
        }
        onExited: {
            root.ddcMonitors = root._ddcNext;
            root._ddcNext = [];
            root.monitors.forEach(m => {
                if (m.isDdc)
                    m.initialize();
            });
        }
    }

    component BrightnessMonitor: QtObject {
        id: monitor

        required property ShellScreen screen
        readonly property bool isDdc: !!root.ddcMonitors.find(m => screen?.model?.includes(m.model))
        readonly property string busNum: root.ddcMonitors.find(m => screen?.model?.includes(m.model))?.busNum ?? ""
        readonly property bool useGamma: !isDdc && root.backlightDetectionReady && root.backlightDevice === "" && root._isHyprland

        property int rawMaxBrightness: 100
        property real brightness: 1.0
        property bool ready: false
        property bool writePending: false

        Behavior on brightness {
            enabled: !monitor.isDdc && !monitor.useGamma
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        onBrightnessChanged: {
            if (!monitor.ready)
                return;
            monitor.writePending = true;
            if (!setTimer.running)
                setTimer.start();
        }

        function restoreLastGood(): void {
            const screenName = monitor.screen?.name ?? "";
            const lastGood = root.lastValidBrightness[screenName];
            const value = (typeof lastGood === "number" && lastGood >= 0.01) ? lastGood : monitor.brightness;
            if (!Number.isFinite(value))
                return;
            if (screenName)
                root.lastValidBrightness[screenName] = value;
            monitor.brightness = value;
            monitor.syncBrightness();
        }

        function initialize(): void {
            monitor.ready = false;
            if (isDdc) {
                initProc.command = ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"];
            } else if (root.backlightDevice.length > 0) {
                initProc.command = ["/bin/sh", "-c", "printf '%s %s\\n' \"$(brightnessctl -d \"$1\" g)\" \"$(brightnessctl -d \"$1\" m)\"", "_", root.backlightDevice];
            } else if (root.backlightDetectionReady && root._isHyprland) {
                initProc.command = ["hyprctl", "hyprsunset", "gamma"];
            } else {
                monitor.ready = true;
                return;
            }
            initProc.running = true;
        }

        readonly property Process initProc: Process {
            stdout: SplitParser {
                onRead: data => {
                    const screenName = monitor.screen?.name ?? "";
                    const lastGood = root.lastValidBrightness[screenName];
                    if (monitor.useGamma) {
                        const v = parseInt(data.trim());
                        monitor.rawMaxBrightness = 100;
                        if (!isNaN(v) && v > 0) {
                            monitor.brightness = v / 100.0;
                            if (screenName)
                                root.lastValidBrightness[screenName] = monitor.brightness;
                        } else {
                            monitor.brightness = (typeof lastGood === "number") ? lastGood : 1.0;
                        }
                    } else {
                        const parts = data.trim().split(/\s+/);
                        const current = Number(parts[parts.length - 2]);
                        const max = Number(parts[parts.length - 1]);
                        if (Number.isFinite(max) && max > 0) {
                            monitor.rawMaxBrightness = max;
                            const value = current / max;
                            if (Number.isFinite(value) && value >= 0.01) {
                                monitor.brightness = Math.min(1, value);
                                if (screenName)
                                    root.lastValidBrightness[screenName] = monitor.brightness;
                            } else if (typeof lastGood === "number") {
                                monitor.brightness = lastGood;
                                monitor.writePending = true;
                                if (!setTimer.running)
                                    setTimer.start();
                            }
                        }
                    }
                    monitor.ready = true;
                }
            }
            onExited: monitor.ready = true;
        }

        property var setTimer: Timer {
            id: setTimer
            interval: monitor.isDdc ? 300 : (monitor.useGamma ? 0 : 32)
            onTriggered: {
                if (!monitor.writePending)
                    return;
                monitor.writePending = false;
                monitor.syncBrightness();
            }
        }

        function syncBrightness(): void {
            const v = Math.max(0, Math.min(1, monitor.brightness));
            if (isDdc) {
                if (!busNum)
                    return;
                const raw = Math.max(Math.floor(v * monitor.rawMaxBrightness), 1);
                Quickshell.execDetached(["ddcutil", "-b", busNum, "setvcp", "10", `${raw}`]);
            } else if (root.backlightDevice.length > 0) {
                const raw = Math.max(Math.floor(v * monitor.rawMaxBrightness), 1);
                Quickshell.execDetached(["brightnessctl", "-d", root.backlightDevice, "s", `${raw}`, "--quiet"]);
            } else if (monitor.useGamma) {
                const gammaVal = Math.round(Math.max(1, v * 100));
                Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma", `${gammaVal}`]);
            }
        }

        function setBrightness(value: real): void {
            const v = Math.max(0, Math.min(1, value));
            monitor.brightness = v;
            if (v >= 0.01) {
                const screenName = monitor.screen?.name ?? "";
                if (screenName)
                    root.lastValidBrightness[screenName] = v;
            }
        }

        Component.onCompleted: initialize()
        onBusNumChanged: initialize()
    }

    Component {
        id: monitorComp
        BrightnessMonitor {}
    }
}
