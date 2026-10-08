pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Shapes
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    readonly property real windowPad: 4
    readonly property color crosshairColor: Colors.md3.primary
    readonly property color surfaceColor: Colors.md3.surface_container

    property bool active: false
    readonly property bool suppressNotificationPopups: true
    readonly property bool excludeFromBarOverlay: true
    property string forcedAction: "smart"
    property string activeTool: "screenshot"
    property string _capturedPath: ""
    property bool _closing: false

    readonly property bool isCapture: true

    onActiveChanged: {
        if (active) {
            PanelService.opened(root);
            GameOverlayService.suspended = GameOverlayService.visible;
        } else {
            PanelService.closed(root);
            GameOverlayService.suspended = false;
            GameOverlayService.closeInstantly();
        }
    }

    function _teardown() {
        uiLoader.active = false;
        root._closing = false;
        if (root.useGrimCapture)
            root._cleanupGrimFiles();
    }

    Timer {
        id: teardownTimer
        interval: 250
        repeat: false
        onTriggered: root._teardown()
    }

    function _closeOverlay(immediate = false) {
        if (immediate) {
            teardownTimer.stop();
            root.active = false;
            root._teardown();
            return;
        }

        if (root._closing)
            return;
        root.active = false;
        root._closing = true;
        teardownTimer.restart();
    }

    function close() {
        if (root.active)
            root._closeOverlay();
    }

    readonly property var pillTools: toolList.filter(t => t.id === "screenshot" || t.id === "record")
    readonly property var toolList: ([
            {
                id: "screenshot",
                cmd: Config.screencap.screenshotPath
            },
            {
                id: "record",
                cmd: Config.screencap.recordPath
            },
            {
                id: "cts",
                cmd: Config.screencap.ctsPath
            },
            {
                id: "ocr",
                cmd: Config.screencap.ocrPath
            },
        ])

    readonly property bool modeLocked: root.activeTool === "record" && ScreencapService.isRecording

    function selectTool(id) {
        root.activeTool = id;
        if (id === "record")
            ScreencapService.refresh();
    }

    function cycleTool() {
        const i = root.pillTools.findIndex(t => t.id === root.activeTool);
        if (i >= 0)
            root.selectTool(root.pillTools[(i + 1) % root.pillTools.length].id);
    }

    function envFor(id) {
        switch (id) {
        case "screenshot":
            return {
                NOTIFY_SCREENSHOT_ERROR_TITLE: Localization.t("screenshotScript.error_title"),
                NOTIFY_SCREENSHOT_ERROR_BODY: Localization.t("screenshotScript.error_body")
            };
        case "record":
            return {
                NOTIFY_OPTIMIZE_FAILED_TITLE: Localization.t("recordScript.optimize_failed_title"),
                NOTIFY_OPTIMIZE_FAILED_BODY: Localization.t("recordScript.optimize_failed_body"),
                NOTIFY_CONVERTING_GIF_TITLE: Localization.t("recordScript.converting_gif_title"),
                NOTIFY_GIF_SAVED_TITLE: Localization.t("recordScript.gif_saved_title"),
                NOTIFY_OPEN_GIF_ACTION: Localization.t("recordScript.open_gif_action"),
                NOTIFY_VIEW_FOLDER_ACTION: Localization.t("recordScript.view_folder_action"),
                NOTIFY_GIF_FAILED_TITLE: Localization.t("recordScript.gif_failed_title"),
                NOTIFY_GIF_FAILED_BODY: Localization.t("recordScript.gif_failed_body"),
                NOTIFY_RECORDING_SAVED_TITLE: Localization.t("recordScript.recording_saved_title"),
                NOTIFY_SAVED_TO_BODY: Localization.t("recordScript.saved_to_body"),
                NOTIFY_PROCESSING_TITLE: Localization.t("recordScript.processing_title"),
                NOTIFY_DOWNSCALING_BODY: Localization.t("recordScript.downscaling_body"),
                NOTIFY_OPEN_ACTION: Localization.t("recordScript.open_action"),
                NOTIFY_TO_GIF_ACTION: Localization.t("recordScript.to_gif_action"),
                NOTIFY_WARNING_TITLE: Localization.t("recordScript.warning_title"),
                NOTIFY_NO_AUDIO_BODY: Localization.t("recordScript.no_audio_body"),
                NOTIFY_LIMIT_REACHED_TITLE: Localization.t("recordScript.limit_reached_title"),
                NOTIFY_AUTO_STOPPING_BODY: Localization.t("recordScript.auto_stopping_body"),
                NOTIFY_RECORDING_STARTED_TITLE: Localization.t("recordScript.recording_started_title"),
                NOTIFY_RECORDING_REGION_BODY: Localization.t("recordScript.recording_region_body")
            };
        case "cts":
            return {
                NOTIFY_UPLOAD_FAILED_TITLE: Localization.t("ctsScript.upload_failed_title"),
                NOTIFY_UPLOAD_FAILED_BODY: Localization.t("ctsScript.upload_failed_body")
            };
        case "ocr":
            return {
                NOTIFY_OCR_TITLE: Localization.t("ocrScript.title"),
                NOTIFY_NO_TEXT_FOUND_BODY: Localization.t("ocrScript.no_text_found_body"),
                NOTIFY_COPIED_BODY: Localization.t("ocrScript.copied_body")
            };
        default:
            return ({});
        }
    }

    ScreenshotPreview {
        id: screenshotPreview
    }

    Timer {
        id: captureDelay
        interval: 150
        repeat: false
        onTriggered: captureProc.running = true
    }

    Process {
        id: stopRecordingProc
        command: ["sh", "-c", Config.screencap.recordPath]
        environment: root.envFor("record")
        running: false
        onExited: {
            ScreencapService.refresh();
        }
    }

    IpcHandler {
        target: "screenshot"

        function activate(): void {
            if (root.active)
                return;
            root.forcedAction = "smart";
            root.activeTool = "screenshot";
            root._openOverlay();
        }
        function region(): void {
            if (root.active)
                return;
            root.activeTool = "screenshot";
            root.forcedAction = "smart";
            root._openOverlay();
        }
        function window(): void {
            if (root.active)
                return;
            root.forcedAction = "window";
            root.activeTool = "screenshot";
            root._openOverlay();
        }
        function screen(): void {
            if (root.active)
                return;
            root.forcedAction = "fullscreen";
            root.activeTool = "screenshot";
            root._openOverlay();
        }
        function ocr(): void {
            if (root.active)
                return;
            root.forcedAction = "smart";
            root.activeTool = "ocr";
            root._openOverlay();
        }
        function cts(): void {
            if (root.active)
                return;
            root.forcedAction = "smart";
            root.activeTool = "cts";
            root._openOverlay();
        }

        function record(): void {
            if (root.active)
                return;
            if (ScreencapService.isRecording) {
                stopRecordingProc.running = true;
            } else {
                root.forcedAction = "smart";
                root.activeTool = "record";
                root._openOverlay();
            }
        }
    }

    readonly property bool useGrimCapture: SystemInfo.compositor === "niri"
    property var _grimPaths: ({})

    property var _readyScreens: ({})
    property bool _forceBackingReady: false
    readonly property bool backingReady: root.activeTool === "record" || root._forceBackingReady || Object.keys(root._readyScreens).length >= Quickshell.screens.length

    function _markScreenReady(screenName) {
        if (root._readyScreens[screenName])
            return;
        root._readyScreens[screenName] = true;
        root._readyScreens = Object.assign({}, root._readyScreens);
    }

    Timer {
        interval: 500
        running: uiLoader.active && !root.backingReady
        onTriggered: root._forceBackingReady = true
    }

    function _openOverlay() {
        if (root._closing || uiLoader.active)
            return;
        if (!CompositorService.focusedMonitor)
            return;

        root.active = true;
        ScreencapService.refresh();

        root._readyScreens = {};
        root._forceBackingReady = false;
        root._frozenClientRects = root.clientRects;

        uiLoader.active = true;

        if (root.useGrimCapture) {
            root._grimPaths = {};
            for (let i = 0; i < Quickshell.screens.length; i++) {
                const scr = Quickshell.screens[i];
                grimCaptureComp.createObject(root, { screenName: scr.name });
            }
        }
    }

    Component {
        id: grimCaptureComp
        Process {
            id: grimProc
            required property string screenName
            property string outPath: `/tmp/qs-screenshot-${screenName}-${Date.now()}.png`
            running: true
            command: ["bash", "-c", `grim -o '${screenName.replace(/'/g, "'\\''")}' '${outPath}'`]
            onExited: (exitCode) => {
                if (exitCode === 0) {
                    root._grimPaths[screenName] = outPath;
                    root._grimPaths = Object.assign({}, root._grimPaths);
                } else {
                    console.error("[Screenshot] grim capture failed for", screenName);
                }
                root._markScreenReady(grimProc.screenName);
                grimProc.destroy();
            }
        }
    }

    function _cleanupGrimFiles() {
        const paths = Object.values(root._grimPaths);
        if (paths.length > 0)
            Quickshell.execDetached(["rm", "-f", ...paths]);
        root._grimPaths = {};
    }

    function captureGlobal(gx, gy, gw, gh) {
        const geom = `${Math.round(gx)},${Math.round(gy)} ${Math.round(gw)}x${Math.round(gh)}`;
        const tool = root.toolList.find(t => t.id === root.activeTool);

        captureProc.environment = root.envFor(root.activeTool);
        captureProc.command = ["sh", "-c", `${tool?.cmd ?? ""} '${geom}'`];

        if (uiLoader.item)
            uiLoader.item.capturing = true;

        if (root.activeTool !== "screenshot")
            root._closeOverlay();
        captureDelay.start();
    }

    function clampToScreenAxis(v, horizontal) {
        const screens = Quickshell.screens;
        let best = v;
        let bestDist = Infinity;
        for (let i = 0; i < screens.length; i++) {
            const scr = screens[i];
            const lo = horizontal ? scr.x : scr.y;
            const hi = horizontal ? lo + scr.width : lo + scr.height;
            if (v >= lo && v <= hi)
                return v;
            const d = v < lo ? lo - v : v - hi;
            if (d < bestDist) {
                bestDist = d;
                best = v < lo ? lo : hi;
            }
        }
        return best;
    }

    function clampRectEdge(unpadded, padded, center, horizontal) {
        const screens = Quickshell.screens;
        let bestLo = 0;
        let bestHi = 0;
        let bestDist = Infinity;
        for (let i = 0; i < screens.length; i++) {
            const scr = screens[i];
            const lo = horizontal ? scr.x : scr.y;
            const hi = horizontal ? lo + scr.width : lo + scr.height;
            if (unpadded < lo || unpadded > hi)
                continue;
            if (center >= lo && center <= hi)
                return Math.max(lo, Math.min(hi, padded));
            const d = center < lo ? lo - center : center - hi;
            if (d < bestDist) {
                bestDist = d;
                bestLo = lo;
                bestHi = hi;
            }
        }
        return bestDist === Infinity ? padded : Math.max(bestLo, Math.min(bestHi, padded));
    }

    function screenAt(x, y) {
        return Quickshell.screens.find(s => x >= s.x && x <= s.x + s.width && y >= s.y && y <= s.y + s.height) ?? null;
    }

    function rectBetween(ax, ay, bx, by) {
        return {
            x: Math.min(ax, bx),
            y: Math.min(ay, by),
            w: Math.abs(bx - ax),
            h: Math.abs(by - ay)
        };
    }

    function screenBounds() {
        const s = Quickshell.screens;
        return {
            l: Math.min(...s.map(c => c.x)),
            t: Math.min(...s.map(c => c.y)),
            r: Math.max(...s.map(c => c.x + c.width)),
            b: Math.max(...s.map(c => c.y + c.height))
        };
    }

    function dragRect(px, py, mx, my, square) {
        if (!square)
            return root.rectBetween(px, py, mx, my);
        const b = root.screenBounds();
        const sx = mx < px ? -1 : 1;
        const sy = my < py ? -1 : 1;
        const size = Math.min(Math.max(Math.abs(mx - px), Math.abs(my - py)), sx > 0 ? b.r - px : px - b.l, sy > 0 ? b.b - py : py - b.t);
        return root.rectBetween(px, py, px + sx * size, py + sy * size);
    }

    readonly property var clientRects: {
        const pad = root.windowPad;
        const rawRects = CompositorService.clientRects;
        const rects = [];
        if (Array.isArray(rawRects)) {
            for (let i = 0; i < rawRects.length; i++) {
                const r = rawRects[i];
                if (r && typeof r.x === "number") {
                    const cx = r.x + r.w / 2;
                    const cy = r.y + r.h / 2;
                    const x1 = root.clampRectEdge(r.x, r.x - pad, cx, true);
                    const y1 = root.clampRectEdge(r.y, r.y - pad, cy, false);
                    const x2 = root.clampRectEdge(r.x + r.w, r.x + r.w + pad, cx, true);
                    const y2 = root.clampRectEdge(r.y + r.h, r.y + r.h + pad, cy, false);
                    rects.push({
                        x: x1,
                        y: y1,
                        w: x2 - x1,
                        h: y2 - y1,
                        title: r.title ?? "",
                        appId: r.appId ?? ""
                    });
                }
            }
        }
        return rects;
    }

    property var _frozenClientRects: []
    readonly property var effectiveClientRects: root.activeTool === "record" ? root.clientRects : root._frozenClientRects

    Process {
        id: captureProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._capturedPath = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.length)
                console.error("captureProc:", text)
        }
        onExited: {
            root._closeOverlay(true);

            if (root.activeTool === "screenshot" && root._capturedPath !== "") {
                SoundService.screenshot();
                screenshotPreview.show(root._capturedPath);
                root._capturedPath = "";
            }
        }
    }

    Loader {
        id: uiLoader
        active: false

        sourceComponent: Component {
            Item {
                id: sessionRoot

                property bool dragging: false
                property bool pressing: false
                property bool hovering: false
                property bool cancelled: false
                property bool capturing: false

                readonly property string effectiveAction: root.forcedAction

                property real globalHlX: 0
                property real globalHlY: 0
                property real globalHlW: 0
                property real globalHlH: 0
                property real globalTargetX: 0
                property real globalTargetY: 0
                property real globalTargetW: 0
                property real globalTargetH: 0
                property real globalPressX: 0
                property real globalPressY: 0
                property real globalMouseX: 0
                property real globalMouseY: 0
                property var pointerScreen: null
                property var pressScreen: null
                readonly property var keyboardScreen: dragging ? pressScreen : pointerScreen
                property bool spaceHeld: false

                property bool hlSeeded: false
                property string hoverTitle: ""
                property string hoverSubtitle: ""

                readonly property real selX: dragging ? globalTargetX : globalHlX
                readonly property real selY: dragging ? globalTargetY : globalHlY
                readonly property real selW: dragging ? globalTargetW : globalHlW
                readonly property real selH: dragging ? globalTargetH : globalHlH
                readonly property real cornerX: globalPressX <= selX + 0.5 ? selX + selW : selX
                readonly property real cornerY: globalPressY <= selY + 0.5 ? selY + selH : selY

                property real animHlX: 0
                property real animHlY: 0
                property real animHlW: 0
                property real animHlH: 0

                Behavior on animHlX {
                    enabled: sessionRoot.hlSeeded
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on animHlY {
                    enabled: sessionRoot.hlSeeded
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on animHlW {
                    enabled: sessionRoot.hlSeeded
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on animHlH {
                    enabled: sessionRoot.hlSeeded
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                function resetDrag() {
                    cancelled = pressing;
                    spaceHeld = false;
                    dragging = false;
                    pressing = false;
                    hovering = false;
                    globalTargetX = 0;
                    globalTargetY = 0;
                    globalTargetW = 0;
                    globalTargetH = 0;
                    globalHlX = 0;
                    globalHlY = 0;
                    globalHlW = 0;
                    globalHlH = 0;
                }

                function setMode(action) {
                    if (root.modeLocked)
                        return;
                    root.forcedAction = action;
                    updateHover();
                }

                function updateHover() {
                    const scr = pointerScreen;
                    if (cancelled || !scr)
                        return;
                    let found = false;
                    let tx = 0, ty = 0, tw = 0, th = 0;
                    let title = "", subtitle = "";

                    if (effectiveAction === "fullscreen") {
                        found = true;
                        tx = scr.x;
                        ty = scr.y;
                        tw = scr.width;
                        th = scr.height;
                        title = scr.name;
                    } else {
                        const win = windowAtGlobal(globalMouseX, globalMouseY);
                        if (win) {
                            found = true;
                            tx = win.x;
                            ty = win.y;
                            tw = win.w;
                            th = win.h;
                            title = win.title || win.appId;
                            subtitle = win.title ? win.appId : "";
                        }
                    }

                    if (found && !pressing && !dragging) {
                        globalHlX = tx;
                        globalHlY = ty;
                        globalHlW = tw;
                        globalHlH = th;
                        animHlX = tx;
                        animHlY = ty;
                        animHlW = tw;
                        animHlH = th;
                        hoverTitle = title;
                        hoverSubtitle = subtitle;
                        hovering = true;
                        hlSeeded = true;
                    } else {
                        hovering = false;
                    }
                }

                function captureHovered() {
                    if (hovering && globalHlW > 0 && globalHlH > 0) {
                        root.captureGlobal(globalHlX, globalHlY, globalHlW, globalHlH);
                    } else if (effectiveAction !== "window" && pointerScreen) {
                        root.captureGlobal(pointerScreen.x, pointerScreen.y, pointerScreen.width, pointerScreen.height);
                    } else {
                        return false;
                    }
                    return true;
                }

                function moveSelection(dx, dy) {
                    const b = root.screenBounds();
                    const mx = Math.max(b.l - globalTargetX, Math.min(b.r - globalTargetX - globalTargetW, dx));
                    const my = Math.max(b.t - globalTargetY, Math.min(b.b - globalTargetY - globalTargetH, dy));
                    globalTargetX += mx;
                    globalTargetY += my;
                    globalPressX += mx;
                    globalPressY += my;
                }

                function finishPress() {
                    if (!pressing && !cancelled)
                        return;
                    pressing = false;
                    if (cancelled) {
                        cancelled = false;
                        return;
                    }
                    if (dragging) {
                        if (globalTargetW < 4 || globalTargetH < 4)
                            resetDrag();
                        else
                            root.captureGlobal(globalTargetX, globalTargetY, globalTargetW, globalTargetH);
                    } else if (!captureHovered()) {
                        resetDrag();
                    }
                }

                function windowAtGlobal(gx, gy) {
                    const rects = root.effectiveClientRects;
                    for (let i = rects.length - 1; i >= 0; i--) {
                        const r = rects[i];
                        if (gx >= r.x && gx < r.x + r.w && gy >= r.y && gy < r.y + r.h)
                            return r;
                    }
                    return null;
                }

                Instantiator {
                    model: Quickshell.screens

                    PanelWindow {
                        id: overlay
                        required property var modelData
                        screen: modelData
                        color: "transparent"
                        anchors {
                            top: true
                            bottom: true
                            left: true
                            right: true
                        }
                        exclusionMode: ExclusionMode.Ignore
                        WlrLayershell.layer: WlrLayer.Overlay
                        WlrLayershell.keyboardFocus: modelData === sessionRoot.keyboardScreen && !sessionRoot.capturing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                        WlrLayershell.namespace: "quickshell:screenshot"

                        readonly property bool isPointer: sessionRoot.pointerScreen === modelData
                        property real monX: modelData.x
                        property real monY: modelData.y
                        property int cornerRadius: sessionRoot.dragging ? 10 : 22

                        Component.onCompleted: {
                            if (CompositorService.focusedMonitor?.name === modelData.name)
                                sessionRoot.pointerScreen = modelData;
                        }

                        Shortcut {
                            enabled: !sessionRoot.capturing
                            sequence: "Escape"
                            onActivated: root._closeOverlay()
                        }

                        Item {
                            focus: true
                            onActiveFocusChanged: if (!activeFocus)
                                sessionRoot.spaceHeld = false

                            Keys.onPressed: event => {
                                if (event.isAutoRepeat || sessionRoot.capturing)
                                    return;
                                event.accepted = true;
                                switch (event.key) {
                                case Qt.Key_Space:
                                    sessionRoot.spaceHeld = sessionRoot.dragging;
                                    break;
                                case Qt.Key_1:
                                    sessionRoot.setMode("smart");
                                    break;
                                case Qt.Key_2:
                                    sessionRoot.setMode("window");
                                    break;
                                case Qt.Key_3:
                                    sessionRoot.setMode("fullscreen");
                                    break;
                                case Qt.Key_Tab:
                                    root.cycleTool();
                                    break;
                                case Qt.Key_Return:
                                case Qt.Key_Enter:
                                    if (!sessionRoot.pressing)
                                        sessionRoot.captureHovered();
                                    break;
                                default:
                                    event.accepted = false;
                                }
                            }
                            Keys.onReleased: event => {
                                if (event.key === Qt.Key_Space && !event.isAutoRepeat)
                                    sessionRoot.spaceHeld = false;
                            }
                        }

                        Loader {
                            id: backgroundViewLoader
                            anchors.fill: parent
                            visible: root.activeTool !== "record"
                            z: -1
                            sourceComponent: root.useGrimCapture ? grimImageComp : screencopyViewComp

                            Component {
                                id: screencopyViewComp
                                ScreencopyView {
                                    id: screencopyView
                                    captureSource: overlay.screen
                                    live: false
                                    onHasContentChanged: if (hasContent)
                                    root._markScreenReady(overlay.screen.name)
                                }
                            }
                            Component {
                                id: grimImageComp
                                Image {
                                    source: root._grimPaths[overlay.screen.name] ? "file://" + root._grimPaths[overlay.screen.name] : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: false
                                    cache: false
                                }
                            }
                        }

                        Item {
                            id: selectionUi
                            anchors.fill: parent
                            visible: !sessionRoot.capturing && root.backingReady
                            z: 1

                            QtObject {
                                id: currentHole
                                readonly property bool active: sessionRoot.dragging || sessionRoot.hovering
                                readonly property real x: Math.round(active ? (sessionRoot.dragging ? sessionRoot.globalTargetX : sessionRoot.animHlX) : 0) - overlay.monX
                                readonly property real y: Math.round(active ? (sessionRoot.dragging ? sessionRoot.globalTargetY : sessionRoot.animHlY) : 0) - overlay.monY
                                readonly property real w: Math.round(active ? (sessionRoot.dragging ? sessionRoot.globalTargetW : sessionRoot.animHlW) : 0)
                                readonly property real h: Math.round(active ? (sessionRoot.dragging ? sessionRoot.globalTargetH : sessionRoot.animHlH) : 0)
                            }

                            CornerDim {
                                type: 0
                                visible: currentHole.active
                                x: currentHole.x
                                y: currentHole.y
                            }
                            CornerDim {
                                type: 1
                                visible: currentHole.active
                                x: currentHole.x + currentHole.w - radiusSize
                                y: currentHole.y
                            }
                            CornerDim {
                                type: 2
                                visible: currentHole.active
                                x: currentHole.x
                                y: currentHole.y + currentHole.h - radiusSize
                            }
                            CornerDim {
                                type: 3
                                visible: currentHole.active
                                x: currentHole.x + currentHole.w - radiusSize
                                y: currentHole.y + currentHole.h - radiusSize
                            }

                            Item {
                                anchors.fill: parent
                                Rectangle {
                                    color: "#8C000000"
                                    x: 0
                                    y: 0
                                    width: parent.width
                                    height: currentHole.active ? Math.max(0, Math.min(parent.height, currentHole.y)) : parent.height
                                }
                                Rectangle {
                                    color: "#8C000000"
                                    x: 0
                                    width: parent.width
                                    y: currentHole.active ? Math.max(0, Math.min(parent.height, currentHole.y + currentHole.h)) : parent.height
                                    height: currentHole.active ? Math.max(0, parent.height - y) : 0
                                }
                                Rectangle {
                                    color: "#8C000000"
                                    x: 0
                                    y: currentHole.active ? Math.max(0, Math.min(parent.height, currentHole.y)) : 0
                                    width: currentHole.active ? Math.max(0, Math.min(parent.width, currentHole.x)) : 0
                                    height: currentHole.active ? Math.max(0, Math.min(parent.height, currentHole.y + currentHole.h) - y) : 0
                                }
                                Rectangle {
                                    color: "#8C000000"
                                    x: currentHole.active ? Math.max(0, Math.min(parent.width, currentHole.x + currentHole.w)) : parent.width
                                    y: currentHole.active ? Math.max(0, Math.min(parent.height, currentHole.y)) : 0
                                    width: currentHole.active ? Math.max(0, parent.width - x) : 0
                                    height: currentHole.active ? Math.max(0, Math.min(parent.height, currentHole.y + currentHole.h) - y) : 0
                                }
                            }

                            Rectangle {
                                id: selectionOutline
                                visible: currentHole.active
                                x: currentHole.x
                                y: currentHole.y
                                width: currentHole.w
                                height: currentHole.h
                                color: "transparent"
                                radius: overlay.cornerRadius
                                border.color: root.crosshairColor
                                border.width: 1
                            }

                            Shape {
                                visible: overlay.isPointer && !sessionRoot.dragging
                                anchors.fill: parent
                                ShapePath {
                                    id: crosshairPath
                                    readonly property real cx: Math.floor(sessionRoot.globalMouseX - overlay.monX) + 0.5
                                    readonly property real cy: Math.floor(sessionRoot.globalMouseY - overlay.monY) + 0.5
                                    strokeColor: Qt.alpha(root.crosshairColor, 0.35)
                                    strokeWidth: 1
                                    strokeStyle: ShapePath.DashLine
                                    dashPattern: [4, 8]
                                    fillColor: "transparent"
                                    PathMove { x: 0; y: crosshairPath.cy }
                                    PathLine { x: overlay.width; y: crosshairPath.cy }
                                    PathMove { x: crosshairPath.cx; y: 0 }
                                    PathLine { x: crosshairPath.cx; y: overlay.height }
                                }
                            }
                            Shape {
                                visible: sessionRoot.dragging
                                anchors.fill: parent
                                ShapePath {
                                    id: edgePath
                                    readonly property real l: currentHole.x + 0.5
                                    readonly property real r: currentHole.x + currentHole.w - 0.5
                                    readonly property real u: currentHole.y + 0.5
                                    readonly property real d: currentHole.y + currentHole.h - 0.5
                                    strokeColor: Qt.alpha(root.crosshairColor, 0.55)
                                    strokeWidth: 1
                                    strokeStyle: ShapePath.DashLine
                                    dashPattern: [4, 8]
                                    fillColor: "transparent"
                                    PathMove { x: 0; y: edgePath.u }
                                    PathLine { x: overlay.width; y: edgePath.u }
                                    PathMove { x: 0; y: edgePath.d }
                                    PathLine { x: overlay.width; y: edgePath.d }
                                    PathMove { x: edgePath.l; y: 0 }
                                    PathLine { x: edgePath.l; y: overlay.height }
                                    PathMove { x: edgePath.r; y: 0 }
                                    PathLine { x: edgePath.r; y: overlay.height }
                                }
                            }

                            MouseArea {
                                id: pointerArea
                                readonly property real reach: 16384
                                x: -reach
                                y: -reach
                                width: parent.width + reach * 2
                                height: parent.height + reach * 2
                                hoverEnabled: true
                                cursorShape: sessionRoot.spaceHeld ? Qt.SizeAllCursor : Qt.CrossCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onPositionChanged: mouse => {
                                    const gmx = root.clampToScreenAxis(overlay.monX + mouse.x - pointerArea.reach, true);
                                    const gmy = root.clampToScreenAxis(overlay.monY + mouse.y - pointerArea.reach, false);
                                    const moveX = gmx - sessionRoot.globalMouseX;
                                    const moveY = gmy - sessionRoot.globalMouseY;
                                    sessionRoot.globalMouseX = gmx;
                                    sessionRoot.globalMouseY = gmy;
                                    if (!(mouse.buttons & Qt.LeftButton))
                                        sessionRoot.cancelled = false;
                                    sessionRoot.pointerScreen = root.screenAt(gmx, gmy) ?? sessionRoot.pointerScreen;

                                    if (pressed && (mouse.buttons & Qt.LeftButton)) {
                                        if (sessionRoot.cancelled)
                                            return;
                                        const action = sessionRoot.effectiveAction;
                                        if (!sessionRoot.dragging && action !== "window" && action !== "fullscreen") {
                                            const dx = gmx - sessionRoot.globalPressX;
                                            const dy = gmy - sessionRoot.globalPressY;
                                            if (Math.sqrt(dx * dx + dy * dy) >= 8)
                                                sessionRoot.dragging = true;
                                        }
                                        if (sessionRoot.dragging && sessionRoot.spaceHeld) {
                                            sessionRoot.moveSelection(moveX, moveY);
                                        } else if (sessionRoot.dragging) {
                                            const r = root.dragRect(sessionRoot.globalPressX, sessionRoot.globalPressY, gmx, gmy, !!(mouse.modifiers & Qt.ShiftModifier));
                                            sessionRoot.globalTargetX = r.x;
                                            sessionRoot.globalTargetY = r.y;
                                            sessionRoot.globalTargetW = r.w;
                                            sessionRoot.globalTargetH = r.h;
                                        }
                                        return;
                                    }

                                    sessionRoot.updateHover();
                                }

                                onPressed: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        sessionRoot.resetDrag();
                                        return;
                                    }
                                    if (mouse.button === Qt.LeftButton) {
                                        const gmx = overlay.monX + mouse.x - pointerArea.reach;
                                        const gmy = overlay.monY + mouse.y - pointerArea.reach;
                                        sessionRoot.cancelled = false;
                                        sessionRoot.pressing = true;
                                        sessionRoot.pressScreen = overlay.screen;
                                        sessionRoot.globalPressX = gmx;
                                        sessionRoot.globalPressY = gmy;
                                        sessionRoot.globalTargetX = gmx;
                                        sessionRoot.globalTargetY = gmy;
                                        sessionRoot.globalTargetW = 0;
                                        sessionRoot.globalTargetH = 0;
                                        sessionRoot.dragging = false;
                                    }
                                }

                                onReleased: mouse => {
                                    if (mouse.button === Qt.LeftButton)
                                        sessionRoot.finishPress();
                                }

                                onCanceled: {
                                    sessionRoot.resetDrag();
                                    sessionRoot.cancelled = false;
                                }
                            }

                            Item {
                                id: tip
                                readonly property real cx: sessionRoot.globalMouseX - overlay.monX
                                readonly property real cy: sessionRoot.globalMouseY - overlay.monY
                                readonly property real targetW: tipContent.implicitWidth + 24
                                readonly property real targetH: tipContent.implicitHeight + 20
                                readonly property bool flipX: cx + 16 + targetW > parent.width - 16
                                readonly property bool flipY: cy + 16 + targetH > parent.height - 16

                                visible: opacity > 0
                                opacity: overlay.isPointer ? 1 : 0
                                scale: overlay.isPointer ? 1 : 0.94
                                transformOrigin: flipX ? (flipY ? Item.BottomRight : Item.TopRight) : (flipY ? Item.BottomLeft : Item.TopLeft)
                                width: targetW
                                height: targetH

                                property real flipBlendX: flipX ? 1 : 0
                                property real flipBlendY: flipY ? 1 : 0
                                x: cx + 16 - flipBlendX * (width + 32)
                                y: cy + 16 - flipBlendY * (height + 32)
                                Behavior on flipBlendX {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on flipBlendY {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on width {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on height {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    topLeftRadius: !tip.flipX && !tip.flipY ? 8 : 20
                                    topRightRadius: tip.flipX && !tip.flipY ? 8 : 20
                                    bottomLeftRadius: !tip.flipX && tip.flipY ? 8 : 20
                                    bottomRightRadius: tip.flipX && tip.flipY ? 8 : 20
                                    color: root.surfaceColor
                                    border.width: 1
                                    border.color: Colors.md3.outline_variant
                                }

                                ColumnLayout {
                                    id: tipContent
                                    x: 12
                                    y: 10
                                    spacing: 6

                                    ColumnLayout {
                                        visible: sessionRoot.hovering && !sessionRoot.dragging && sessionRoot.hoverTitle !== ""
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.maximumWidth: 280
                                            text: sessionRoot.hoverTitle
                                            elide: Text.ElideRight
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: Colors.md3.on_surface
                                        }
                                        Text {
                                            visible: sessionRoot.hoverSubtitle !== ""
                                            Layout.fillWidth: true
                                            Layout.maximumWidth: 280
                                            text: sessionRoot.hoverSubtitle
                                            elide: Text.ElideRight
                                            font.pixelSize: 10
                                            color: Colors.md3.on_surface_variant
                                        }
                                    }
                                    Row {
                                        id: sizeRow
                                        visible: sessionRoot.dragging || sessionRoot.hovering
                                        spacing: 4
                                        Text {
                                            id: sizeText
                                            text: Math.round(sessionRoot.selW) + " × " + Math.round(sessionRoot.selH)
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: Colors.md3.on_surface
                                        }
                                        Text {
                                            anchors.baseline: sizeText.baseline
                                            text: Localization.t("screenshot.px")
                                            font.pixelSize: 9
                                            color: Colors.md3.outline
                                        }
                                    }
                                    Rectangle {
                                        visible: sizeRow.visible
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 1
                                        color: Colors.md3.outline_variant
                                        opacity: 0.5
                                    }
                                    Grid {
                                        columns: 2
                                        columnSpacing: 6
                                        rowSpacing: 4
                                        verticalItemAlignment: Grid.AlignVCenter

                                        Text {
                                            visible: sessionRoot.dragging
                                            text: Localization.t("screenshot.from")
                                            font.pixelSize: 8
                                            font.letterSpacing: 1
                                            color: Colors.md3.outline
                                        }
                                        Text {
                                            visible: sessionRoot.dragging
                                            text: Math.round(sessionRoot.globalPressX) + ",  " + Math.round(sessionRoot.globalPressY)
                                            font.pixelSize: 10
                                            font.family: Config.fontMonospace
                                            color: Colors.md3.on_surface_variant
                                        }
                                        Text {
                                            text: sessionRoot.dragging ? Localization.t("screenshot.to") : Localization.t("screenshot.pos")
                                            font.pixelSize: 8
                                            font.letterSpacing: 1
                                            color: Colors.md3.outline
                                        }
                                        Text {
                                            text: sessionRoot.dragging ? Math.round(sessionRoot.cornerX) + ",  " + Math.round(sessionRoot.cornerY) : Math.round(sessionRoot.globalMouseX) + ",  " + Math.round(sessionRoot.globalMouseY)
                                            font.pixelSize: 10
                                            font.family: Config.fontMonospace
                                            color: Colors.md3.on_surface_variant
                                        }
                                    }
                                    Text {
                                        visible: !sessionRoot.dragging && !sessionRoot.hovering && sessionRoot.effectiveAction === "smart"
                                        text: Localization.t("screenshot.hint_screen")
                                        font.pixelSize: 10
                                        color: Colors.md3.outline
                                    }
                                    Text {
                                        visible: sessionRoot.dragging
                                        text: Localization.t("screenshot.hint_move")
                                        font.pixelSize: 10
                                        color: sessionRoot.spaceHeld ? Colors.md3.primary : Colors.md3.outline
                                    }
                                }
                            }
                        }

                        Item {
                            id: floatingPill
                            z: 2

                            property bool showPill: overlay.isPointer && !sessionRoot.dragging && !sessionRoot.capturing && root.backingReady
                            visible: showPill || opacity > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: showPill ? 32 : -80
                            height: 56
                            width: pillRow.implicitWidth + 16
                            opacity: showPill ? 1.0 : 0.0

                            Behavior on opacity {
                                enabled: !sessionRoot.capturing
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on anchors.bottomMargin {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Colors.md3.surface_container
                                border.width: 1
                                border.color: Colors.md3.outline_variant
                            }

                            Row {
                                id: pillRow
                                anchors.centerIn: parent
                                spacing: 0

                                Item {
                                    readonly property bool isPillTool: root.activeTool === "screenshot" || root.activeTool === "record"
                                    width: isPillTool ? toolTrack.btnW * root.pillTools.length : 40
                                    height: 56
                                    anchors.verticalCenter: parent.verticalCenter
                                    clip: true
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Item {
                                        id: toolTrack
                                        readonly property real btnW: 44
                                        readonly property real btnH: 40
                                        readonly property int activeIndex: {
                                            const idx = root.pillTools.findIndex(t => t.id === root.activeTool);
                                            return idx >= 0 ? idx : 0;
                                        }
                                        visible: parent.isPillTool
                                        opacity: parent.isPillTool ? 1.0 : 0.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
                                            }
                                        }
                                        width: btnW * root.pillTools.length
                                        height: btnH
                                        anchors.centerIn: parent

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: height / 2
                                            color: Colors.md3.surface_container_highest
                                        }
                                        Rectangle {
                                            width: toolTrack.btnW - 8
                                            height: toolTrack.btnH - 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: height / 2
                                            color: Colors.md3.secondary
                                            x: toolTrack.activeIndex * toolTrack.btnW + 4
                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                        Row {
                                            anchors.fill: parent
                                            Repeater {
                                                model: root.pillTools
                                                Item {
                                                    required property var modelData
                                                    required property int index
                                                    width: toolTrack.btnW
                                                    height: toolTrack.btnH
                                                    readonly property bool isActive: root.activeTool === modelData.id
                                                    property color iconColor: isActive ? Colors.md3.on_secondary : Colors.md3.on_surface
                                                    Behavior on iconColor {
                                                        ColorAnimation {
                                                            duration: 200
                                                        }
                                                    }

                                                    Loader {
                                                        id: toolIconLoader
                                                        anchors.centerIn: parent
                                                        sourceComponent: modelData.id === "screenshot" ? ssIconComp : recIconComp
                                                        onLoaded: item.iconSize = 20
                                                    }
                                                    Binding {
                                                        target: toolIconLoader.item
                                                        property: "color"
                                                        value: iconColor
                                                        when: toolIconLoader.item !== null
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.selectTool(modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        visible: !parent.isPillTool
                                        opacity: parent.isPillTool ? 0.0 : 1.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
                                            }
                                        }
                                        anchors.centerIn: parent
                                        width: 40
                                        height: 40
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 20
                                            color: Colors.md3.secondary_container
                                        }
                                        Loader {
                                            id: singleToolIconLoader
                                            anchors.centerIn: parent
                                            sourceComponent: root.activeTool === "ocr" ? ocrIconComp : ctsIconComp
                                            onLoaded: {
                                                item.iconSize = 20;
                                                item.color = Colors.md3.on_secondary_container;
                                            }
                                        }
                                    }
                                }

                                Item {
                                    id: recordingModeContainer
                                    readonly property bool showStop: root.modeLocked
                                    readonly property real innerW: 17 + modeTrack.btnW * 3
                                    width: innerW
                                    height: 56

                                    Row {
                                        height: 56

                                        Item {
                                            width: 17
                                            height: 56
                                            Rectangle {
                                                width: 1
                                                height: 28
                                                anchors.centerIn: parent
                                                color: Colors.md3.outline_variant
                                                opacity: 0.6
                                            }
                                        }

                                        Item {
                                            id: modeTrack
                                            readonly property real btnW: 52
                                            readonly property real btnH: 40
                                            readonly property int activeIndex: root.forcedAction === "smart" ? 0 : root.forcedAction === "window" ? 1 : 2
                                            width: btnW * 3
                                            height: btnH
                                            anchors.verticalCenter: parent.verticalCenter

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: height / 2
                                                color: Colors.md3.surface_container_highest
                                            }

                                            ClippingRectangle {
                                                id: indicatorPill
                                                width: recordingModeContainer.showStop ? modeTrack.btnW * 3 - 8 : modeTrack.btnW - 8
                                                height: modeTrack.btnH - 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                radius: height / 2
                                                color: recordingModeContainer.showStop ? Colors.md3.error : Colors.md3.primary
                                                x: recordingModeContainer.showStop ? 4 : modeTrack.activeIndex * modeTrack.btnW + 4

                                                Behavior on x {
                                                    NumberAnimation {
                                                        duration: 200
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                                Behavior on width {
                                                    NumberAnimation {
                                                        duration: 200
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 200
                                                    }
                                                }

                                                Item {
                                                    x: 4 - indicatorPill.x
                                                    y: 0
                                                    width: modeTrack.btnW * 3 - 8
                                                    height: modeTrack.btnH - 8
                                                    opacity: recordingModeContainer.showStop ? 1.0 : 0.0
                                                    Behavior on opacity {
                                                        NumberAnimation {
                                                            duration: 150
                                                            easing.type: Easing.OutCubic
                                                        }
                                                    }

                                                    Row {
                                                        anchors.centerIn: parent
                                                        spacing: 8

                                                        Rectangle {
                                                            width: 13
                                                            height: 13
                                                            radius: 2
                                                            color: Colors.md3.on_error
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                        Text {
                                                            text: Localization.t("screenshot.stop_recording")
                                                            font.pixelSize: 12
                                                            font.weight: Font.Medium
                                                            color: Colors.md3.on_error
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: recordingModeContainer.showStop
                                                    onClicked: {
                                                        ScreencapService.markRecordingStoppedOptimistic();
                                                        stopRecordingProc.running = true;
                                                    }
                                                }
                                            }
                                            Row {
                                                anchors.fill: parent
                                                opacity: recordingModeContainer.showStop ? 0.0 : 1.0
                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 150
                                                    }
                                                }
                                                Repeater {
                                                    model: [
                                                        {
                                                            action: "smart",
                                                            comp: "region"
                                                        },
                                                        {
                                                            action: "window",
                                                            comp: "window"
                                                        },
                                                        {
                                                            action: "fullscreen",
                                                            comp: "screen"
                                                        },
                                                    ]
                                                    Item {
                                                        required property var modelData
                                                        width: modeTrack.btnW
                                                        height: modeTrack.btnH
                                                        readonly property bool isActive: root.forcedAction === modelData.action
                                                        property color iconColor: isActive ? Colors.md3.on_primary : Colors.md3.on_surface
                                                        Behavior on iconColor {
                                                            ColorAnimation {
                                                                duration: 200
                                                            }
                                                        }

                                                        Loader {
                                                            id: modeIconLoader
                                                            anchors.centerIn: parent
                                                            sourceComponent: modelData.comp === "region" ? regionIconComp : modelData.comp === "window" ? windowIconComp : screenIconComp
                                                            onLoaded: item.iconSize = 20
                                                        }
                                                        Binding {
                                                            target: modeIconLoader.item
                                                            property: "color"
                                                            value: iconColor
                                                            when: modeIconLoader.item !== null
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            enabled: !recordingModeContainer.showStop
                                                            onClicked: sessionRoot.setMode(modelData.action)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Item {
                                    width: 17
                                    height: 56
                                    Rectangle {
                                        width: 1
                                        height: 28
                                        anchors.centerIn: parent
                                        color: Colors.md3.outline_variant
                                        opacity: 0.6
                                    }
                                }
                                Item {
                                    width: 40
                                    height: 56
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 36
                                        height: 36
                                        radius: 18
                                        color: closeMouse.containsMouse ? Colors.md3.surface_variant : Colors.md3.surface_container
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                                        MaterialIcon {
                                            name: "close"
                                            anchors.centerIn: parent
                                            iconSize: 20
                                            color: Colors.md3.on_surface_variant
                                        }
                                        MouseArea {
                                            id: closeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root._closeOverlay()
                                        }
                                    }
                                }
                            }

                            Component {
                                id: ssIconComp
                                MaterialIcon {
                                    name: "snipping"
                                }
                            }
                            Component {
                                id: recIconComp
                                MaterialIcon {
                                    name: "record"
                                }
                            }
                            Component {
                                id: ctsIconComp
                                MaterialIcon {
                                    name: "image-search"
                                }
                            }
                            Component {
                                id: ocrIconComp
                                MaterialIcon {
                                    name: "ocr"
                                }
                            }
                            Component {
                                id: regionIconComp
                                MaterialIcon {
                                    name: "region"
                                }
                            }
                            Component {
                                id: windowIconComp
                                MaterialIcon {
                                    name: "window"
                                }
                            }
                            Component {
                                id: screenIconComp
                                MaterialIcon {
                                    name: "screen"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component CornerDim: Item {
        id: block
        property int type: 0
        property color dimColor: "#8C000000"
        property int radiusSize: Math.min(overlay.cornerRadius, selectionOutline.width / 2, selectionOutline.height / 2)
        width: radiusSize
        height: radiusSize
        clip: true
        Rectangle {
            width: block.radiusSize * 4
            height: block.radiusSize * 4
            radius: block.radiusSize * 2
            color: "transparent"
            border.width: block.radiusSize
            border.color: block.dimColor
            x: (block.type === 1 || block.type === 3) ? -block.radiusSize * 2 : -block.radiusSize
            y: (block.type === 2 || block.type === 3) ? -block.radiusSize * 2 : -block.radiusSize
        }
    }
}