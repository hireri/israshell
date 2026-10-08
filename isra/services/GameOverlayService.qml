pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import qs.style
import "../components/gameoverlay/crosshair.js" as Crosshair

Singleton {
    id: root
    property bool visible: false
    readonly property bool excludeFromBarOverlay: true

    property string gameTitle: ""
    property string gameMonitor: ""
    property string gameAppId: ""

    property var clickableItems: []

    readonly property var catalog: [
        { id: "crosshair", icon: "crosshair", titleKey: "gameOverlay.crosshair", ax: 0.5, ay: 0.5, framed: false, resizable: false, centerButton: true, centerBody: true, canClick: false, dim: false },
        { id: "resources", icon: "equalizer", titleKey: "gameOverlay.performance", ax: 0.96, ay: 0.7 },
        { id: "volumeMixer", icon: "volume-up", titleKey: "gameOverlay.audio", ax: 0.04, ay: 0.3, clickthrough: false },
        { id: "recorder", icon: "screenshot", titleKey: "gameOverlay.capture", ax: 0.04, ay: 0.08, clickthrough: false },
        { id: "notes", icon: "edit", titleKey: "gameOverlay.notes", ax: 0.96, ay: 0.04 },
        { id: "fpsLimiter", icon: "speed-3", titleKey: "gameOverlay.fps_limiter", ax: 0.96, ay: 0.4, clickthrough: false },
        { id: "nowPlaying", icon: "music-note", titleKey: "gameOverlay.now_playing", ax: 0.5, ay: 0.96, clickthrough: false, framed: false, resizable: false },
        { id: "sessionTimer", icon: "analog-clock", titleKey: "gameOverlay.session_timer", ax: 0.04, ay: 0.55, clickthrough: false },
        { id: "ping", icon: "network-ping", titleKey: "gameOverlay.ping", ax: 0.96, ay: 0.55, clickthrough: false },
        { id: "devices", icon: "battery", titleKey: "gameOverlay.devices", ax: 0.96, ay: 0.25 },
        { id: "temperatures", icon: "thermostat", titleKey: "gameOverlay.temperatures", ax: 0.96, ay: 0.85 },
        { id: "discordVoice", icon: "discord", titleKey: "gameOverlay.discord", ax: 0.04, ay: 0.7, framed: false, resizable: false, canClick: false }
    ]

    readonly property var crosshair: Crosshair.parse(Config.gameOverlay.crosshairCode)
    readonly property var openWidgets: catalog.filter(w => Config.gameOverlay.open.includes(w.id))
    readonly property bool hasPinned: openWidgets.some(w => pinnedActive(w.id))

    property bool timerRunning: false
    property real timerBase: 0
    property real timerSince: 0
    property int _timerPid: 0

    function timerElapsed(now) {
        return Math.max(0, timerBase + (timerRunning ? now - timerSince : 0));
    }

    function timerToggle() {
        const now = Date.now();
        if (timerRunning)
            timerBase += now - timerSince;
        timerSince = now;
        timerRunning = !timerRunning;
    }

    function timerReset() {
        timerBase = 0;
        timerSince = Date.now();
    }

    function _syncTimer(pid) {
        if (pid > 0 && pid !== _timerPid) {
            _timerPid = pid;
            ageProc.command = ["ps", "-o", "etimes=", "-p", String(pid)];
            ageProc.running = true;
        } else if (pid <= 0 && timerSince === 0) {
            timerToggle();
        }
    }

    Process {
        id: ageProc
        stdout: StdioCollector {
            onStreamFinished: {
                const secs = parseInt(text.trim());
                root.timerBase = isNaN(secs) ? 0 : secs * 1000;
                root.timerSince = Date.now();
                root.timerRunning = true;
            }
        }
    }

    readonly property bool keepsUnderCapture: true
    property bool suspended: false
    property bool instantHidden: false
    readonly property bool _recording: ScreencapService.isRecording

    signal centerRequested(string id)

    property int _previews: 0
    readonly property bool previewing: _previews > 0

    function previewOpened() {
        _previews++;
    }

    function previewClosed() {
        _previews = Math.max(0, _previews - 1);
    }

    function previewReset() {
        _previews = 0;
    }

    function closeInstantly() {
        if (!visible)
            return;
        instantHidden = true;
        visible = false;
        instantTimer.restart();
    }

    Timer {
        id: instantTimer
        interval: 2500
        onTriggered: root.instantHidden = root._recording
    }

    on_RecordingChanged: if (!_recording && !instantTimer.running)
        instantHidden = false

    onVisibleChanged: {
        if (visible) {
            _syncTimer(CompositorService.activeWindow.pid);
            instantHidden = false;
            gameTitle = CompositorService.activeWindow.title;
            gameAppId = CompositorService.activeWindow.appId;
            gameMonitor = CompositorService.focusedMonitor.name;
            PanelService.opened(root);
        } else {
            PanelService.closed(root);
        }
    }

    function close() {
        visible = false;
    }

    function toggle() {
        visible = !visible;
    }

    function widgetState(id) {
        return Config.gameOverlay.widgets[id] ?? {};
    }

    function isOpen(id) {
        return Config.gameOverlay.open.includes(id);
    }

    function isClickthrough(id) {
        const meta = catalog.find(w => w.id === id);
        return meta?.canClick === false || (widgetState(id).clickthrough ?? meta?.clickthrough ?? true);
    }

    function _update(patch) {
        Config.update({ gameOverlay: Object.assign({}, Config.gameOverlay, patch) });
    }

    function setOption(key, value) {
        _update({ [key]: value });
    }

    function setCrosshair(code) {
        setOption("crosshairCode", Crosshair.serialize(Crosshair.parse(code)));
    }

    function editCrosshair(mutate) {
        const s = Crosshair.parse(Config.gameOverlay.crosshairCode);
        mutate(s);
        setCrosshair(Crosshair.serialize(s));
    }

    function toggleWidget(id) {
        const open = Config.gameOverlay.open.filter(i => i !== id);
        if (open.length === Config.gameOverlay.open.length)
            open.push(id);
        _update({ open: open });
    }

    function setWidgetState(id, patch) {
        const widgets = Object.assign({}, Config.gameOverlay.widgets);
        widgets[id] = Object.assign({}, widgets[id], patch);
        _update({ widgets: widgets });
    }

    function pinnedActive(id) {
        const s = widgetState(id);
        return s.pinned === true && (!s.pinnedFor || s.pinnedFor === CompositorService.activeWindow.appId);
    }

    function togglePinned(id) {
        const pin = widgetState(id).pinned !== true;
        setWidgetState(id, { pinned: pin, pinnedFor: pin ? gameAppId : "" });
    }

    function toggleClickthrough(id) {
        setWidgetState(id, { clickthrough: !isClickthrough(id) });
    }

    function unpinAll() {
        const widgets = {};
        for (const id in Config.gameOverlay.widgets)
            widgets[id] = Object.assign({}, Config.gameOverlay.widgets[id], { pinned: false });
        _update({ widgets: widgets });
        clickableItems = [];
    }

    function setClickable(item, on) {
        const list = clickableItems.filter(i => i !== item);
        if (on)
            list.push(item);
        clickableItems = list;
    }
}
