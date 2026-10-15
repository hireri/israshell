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
import "markup.js" as Markup

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
    property string markupColor: "#ff3b30"
    property int markupWidth: 4
    property bool markupFill: false
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

    function setRecordFormat(format) {
        Config.update({
            screencap: Object.assign({}, Config.screencap, {
                recordFormat: format
            })
        });
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

        const recordFormat = root.activeTool === "record" ? ` ${Config.screencap.recordFormat === "gif" ? "gif" : "mp4"}` : "";

        captureProc.environment = root.envFor(root.activeTool);
        captureProc.command = ["sh", "-c", `${tool?.cmd ?? ""} '${geom}'${recordFormat}`];

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
            if (root.activeTool === "record")
                ScreencapService.refresh();

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
                property var textEdit: null
                property var textScreen: null
                property string textValue: ""
                property real textW: 0
                property real textH: 0
                property string tool: "region"
                readonly property string effTool: root.activeTool === "screenshot" ? tool : "region"
                property var doc: Markup.newDoc()
                property int selIndex: -1
                property int nudgeIndex: -1
                onSelIndexChanged: nudgeIndex = -1
                property var draft: null
                property int editIndex: -1
                property string shapeHandle: ""
                property var editStart: null
                property real editPressX: 0
                property real editPressY: 0
                property bool leftHeld: false
                readonly property var gestureScreen: (leftHeld || dragging) ? pressScreen : pointerScreen
                readonly property var keyboardScreen: textEdit !== null ? textScreen : gestureScreen
                readonly property var selShape: editIndex >= 0 ? draft : (selIndex >= 0 ? doc.shapes[selIndex] ?? null : null)
                readonly property bool drawing: editIndex >= 0 ? draft !== editStart : (draft !== null && !Markup.isEmpty(draft))
                property bool spaceHeld: false

                property bool hlSeeded: false
                property string hoverTitle: ""
                property string hoverSubtitle: ""

                property bool staged: false
                property rect sel: Qt.rect(0, 0, 0, 0)
                property string handle: ""
                property rect handleStart: Qt.rect(0, 0, 0, 0)
                property real handlePressX: 0
                property real handlePressY: 0
                readonly property var handleSpecs: [
                    {
                        id: "tl",
                        fx: 0,
                        fy: 0
                    },
                    {
                        id: "t",
                        fx: 0.5,
                        fy: 0
                    },
                    {
                        id: "tr",
                        fx: 1,
                        fy: 0
                    },
                    {
                        id: "r",
                        fx: 1,
                        fy: 0.5
                    },
                    {
                        id: "br",
                        fx: 1,
                        fy: 1
                    },
                    {
                        id: "b",
                        fx: 0.5,
                        fy: 1
                    },
                    {
                        id: "bl",
                        fx: 0,
                        fy: 1
                    },
                    {
                        id: "l",
                        fx: 0,
                        fy: 0.5
                    },
                ]

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
                    if (effTool !== "region") {
                        hovering = false;
                        return;
                    }
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

                function shouldStage(mods) {
                    return root.activeTool === "screenshot" && (!Config.screencap.instantCapture || (mods & Qt.ControlModifier) !== 0);
                }

                function enterStaged(x, y, w, h) {
                    sel = Qt.rect(Math.round(x), Math.round(y), Math.round(w), Math.round(h));
                    staged = true;
                    dragging = pressing = hovering = false;
                }

                function unstageRegion() {
                    staged = false;
                    handle = "";
                    resetDrag();
                    updateHover();
                }

                function setTool(id) {
                    tool = id;
                    if (id !== "move")
                        selIndex = -1;
                    if (id === "region") {
                        updateHover();
                    } else {
                        hovering = false;
                    }
                }

                function escapePressed(canClose) {
                    if (textEdit !== null) {
                        commitText();
                    } else if (draft !== null) {
                        draft = null;
                        editIndex = -1;
                        shapeHandle = "";
                        editStart = null;
                    } else if (handle !== "") {
                        sel = handleStart;
                        handle = "";
                    } else if (pressing || dragging) {
                        resetDrag();
                    } else if (selIndex >= 0) {
                        selIndex = -1;
                    } else if (staged) {
                        unstageRegion();
                    } else if (root.activeTool === "screenshot" && tool !== "region") {
                        setTool("region");
                    } else if (canClose) {
                        root._closeOverlay();
                    } else {
                        resetDrag();
                    }
                }

                function captureHovered(mods) {
                    let x, y, w, h;
                    if (hovering && globalHlW > 0 && globalHlH > 0) {
                        x = globalHlX;
                        y = globalHlY;
                        w = globalHlW;
                        h = globalHlH;
                    } else if (effectiveAction !== "window" && pointerScreen) {
                        x = pointerScreen.x;
                        y = pointerScreen.y;
                        w = pointerScreen.width;
                        h = pointerScreen.height;
                    } else {
                        return false;
                    }
                    if (shouldStage(mods))
                        enterStaged(x, y, w, h);
                    else
                        root.captureGlobal(x, y, w, h);
                    return true;
                }

                function toolForKey(key) {
                    switch (key) {
                    case Qt.Key_S:
                        return "region";
                    case Qt.Key_V:
                        return "move";
                    case Qt.Key_R:
                        return "rect";
                    case Qt.Key_E:
                        return "ellipse";
                    case Qt.Key_L:
                        return "line";
                    case Qt.Key_A:
                        return "arrow";
                    case Qt.Key_P:
                        return "pen";
                    case Qt.Key_H:
                        return "highlighter";
                    case Qt.Key_T:
                        return "text";
                    case Qt.Key_N:
                        return "step";
                    case Qt.Key_B:
                        return "blur";
                    case Qt.Key_X:
                        return "pixelate";
                    default:
                        return "";
                    }
                }

                function insideSel(gx, gy) {
                    return gx >= sel.x && gx <= sel.x + sel.width && gy >= sel.y && gy <= sel.y + sel.height;
                }

                function handleAt(gx, gy) {
                    for (let i = 0; i < handleSpecs.length; i++) {
                        const h = handleSpecs[i];
                        if (Math.abs(gx - (sel.x + sel.width * h.fx)) <= 8 && Math.abs(gy - (sel.y + sel.height * h.fy)) <= 8)
                            return h.id;
                    }
                    return "";
                }

                function cursorForHandle(id) {
                    switch (id) {
                    case "l":
                    case "r":
                        return Qt.SizeHorCursor;
                    case "t":
                    case "b":
                        return Qt.SizeVerCursor;
                    case "tl":
                    case "br":
                        return Qt.SizeFDiagCursor;
                    case "tr":
                    case "bl":
                        return Qt.SizeBDiagCursor;
                    default:
                        return Qt.SizeAllCursor;
                    }
                }

                function cursorAt(gx, gy) {
                    if (effTool === "region") {
                        if (staged) {
                            if (handle !== "")
                                return cursorForHandle(handle);
                            const h = handleAt(gx, gy);
                            if (h !== "")
                                return cursorForHandle(h);
                            if (insideSel(gx, gy))
                                return Qt.SizeAllCursor;
                        }
                        return spaceHeld ? Qt.SizeAllCursor : Qt.CrossCursor;
                    }
                    if (editIndex >= 0)
                        return cursorForHandle(shapeHandle);
                    if (selShape !== null) {
                        const h = Markup.handleAt(selShape, gx, gy, 8);
                        if (h !== "")
                            return cursorForHandle(h);
                        if (Markup.hits(selShape, gx, gy, 6))
                            return Qt.SizeAllCursor;
                    }
                    if (tool === "move")
                        return Markup.hitTest(doc.shapes, gx, gy, 6) >= 0 ? Qt.SizeAllCursor : Qt.ArrowCursor;
                    if (tool === "text")
                        return Qt.IBeamCursor;
                    return Qt.CrossCursor;
                }

                function startHandle(id, gx, gy) {
                    handle = id;
                    handleStart = sel;
                    handlePressX = gx;
                    handlePressY = gy;
                }

                function commitShapes(next) {
                    doc = Markup.commit(doc, next);
                    nudgeIndex = -1;
                }

                function regionPress(gx, gy) {
                    if (!staged)
                        return false;
                    const h = handleAt(gx, gy);
                    if (h !== "") {
                        startHandle(h, gx, gy);
                        return true;
                    }
                    if (insideSel(gx, gy)) {
                        startHandle("move", gx, gy);
                        return true;
                    }
                    unstageRegion();
                    return false;
                }

                function regionDrag(gx, gy) {
                    const b = root.screenBounds();
                    if (handle === "move") {
                        const w = handleStart.width;
                        const h = handleStart.height;
                        const nx = Math.max(b.l, Math.min(b.r - w, handleStart.x + gx - handlePressX));
                        const ny = Math.max(b.t, Math.min(b.b - h, handleStart.y + gy - handlePressY));
                        sel = Qt.rect(nx, ny, w, h);
                    } else if (handle !== "") {
                        const spec = handleSpecs.find(s => s.id === handle);
                        const px = Math.max(b.l, Math.min(b.r, gx));
                        const py = Math.max(b.t, Math.min(b.b, gy));
                        let x1 = handleStart.x, x2 = handleStart.x + handleStart.width;
                        let y1 = handleStart.y, y2 = handleStart.y + handleStart.height;
                        if (spec.fx === 0)
                            x1 = px;
                        else if (spec.fx === 1)
                            x2 = px;
                        if (spec.fy === 0)
                            y1 = py;
                        else if (spec.fy === 1)
                            y2 = py;
                        sel = Qt.rect(Math.min(x1, x2), Math.min(y1, y2), Math.max(4, Math.abs(x2 - x1)), Math.max(4, Math.abs(y2 - y1)));
                    }
                }

                function beginEdit(i, h, gx, gy) {
                    editIndex = i;
                    shapeHandle = h;
                    editStart = doc.shapes[i];
                    draft = editStart;
                    editPressX = gx;
                    editPressY = gy;
                }

                function canvasPress(gx, gy, screen) {
                    if (selIndex >= 0) {
                        const h = Markup.handleAt(doc.shapes[selIndex], gx, gy, 8);
                        if (h !== "") {
                            beginEdit(selIndex, h, gx, gy);
                            return;
                        }
                        if (Markup.hits(doc.shapes[selIndex], gx, gy, 6)) {
                            beginEdit(selIndex, "move", gx, gy);
                            return;
                        }
                    }
                    if (tool === "move") {
                        const i = Markup.hitTest(doc.shapes, gx, gy, 6);
                        if (i >= 0) {
                            selIndex = i;
                            beginEdit(i, "move", gx, gy);
                        } else {
                            selIndex = -1;
                        }
                        return;
                    }
                    selIndex = -1;
                    if (tool === "text") {
                        textEdit = {
                            x: gx,
                            y: gy
                        };
                        textScreen = screen;
                    } else if (tool === "step") {
                        commitShapes(Markup.push(doc.shapes, {
                            type: "step",
                            x1: gx,
                            y1: gy,
                            n: Markup.nextStep(doc.shapes),
                            color: root.markupColor,
                            width: root.markupWidth
                        }));
                    } else {
                        const d = {
                            type: tool,
                            color: root.markupColor,
                            width: root.markupWidth,
                            x1: gx,
                            y1: gy,
                            x2: gx,
                            y2: gy
                        };
                        if (Markup.isFillable(tool))
                            d.fill = root.markupFill;
                        if (tool === "pen" || tool === "highlighter")
                            d.points = [{
                                    x: gx,
                                    y: gy
                                }];
                        draft = d;
                    }
                }

                function canvasDrag(gx, gy, shift) {
                    if (editIndex >= 0) {
                        draft = shapeHandle === "move" ? Markup.translate(editStart, gx - editPressX, gy - editPressY) : Markup.dragHandle(editStart, shapeHandle, gx, gy);
                    } else if (draft !== null) {
                        if (draft.type === "pen" || draft.type === "highlighter") {
                            draft = Object.assign({}, draft, {
                                points: Markup.addPoint(draft.points, gx, gy)
                            });
                        } else {
                            const p = shift ? Markup.constrain(draft.type, draft.x1, draft.y1, gx, gy) : {
                                x: gx,
                                y: gy
                            };
                            draft = Object.assign({}, draft, {
                                x2: p.x,
                                y2: p.y
                            });
                        }
                    }
                }

                function canvasRelease() {
                    if (editIndex >= 0) {
                        if (draft !== editStart)
                            commitShapes(Markup.replaceAt(doc.shapes, editIndex, draft));
                        selIndex = editIndex;
                        editIndex = -1;
                        shapeHandle = "";
                        editStart = null;
                        draft = null;
                    } else if (draft !== null) {
                        if (!Markup.isEmpty(draft)) {
                            commitShapes(Markup.push(doc.shapes, draft));
                            selIndex = (Markup.isBoxed(draft.type) || draft.type === "line" || draft.type === "arrow") ? doc.shapes.length - 1 : -1;
                        }
                        draft = null;
                    }
                }

                function commitText() {
                    if (textEdit === null)
                        return;
                    if (textValue.trim() !== "")
                        commitShapes(Markup.push(doc.shapes, {
                            type: "text",
                            x1: textEdit.x,
                            y1: textEdit.y,
                            text: textValue,
                            color: root.markupColor,
                            width: root.markupWidth,
                            tw: textW,
                            th: textH
                        }));
                    textEdit = null;
                    textScreen = null;
                }

                function undo() {
                    doc = Markup.undo(doc);
                    selIndex = -1;
                    draft = null;
                    editIndex = -1;
                    shapeHandle = "";
                    nudgeIndex = -1;
                }

                function redo() {
                    doc = Markup.redo(doc);
                    selIndex = -1;
                    draft = null;
                    editIndex = -1;
                    shapeHandle = "";
                    nudgeIndex = -1;
                }

                function deleteSelected() {
                    if (selIndex >= 0) {
                        commitShapes(Markup.removeAt(doc.shapes, selIndex));
                        selIndex = -1;
                    }
                }

                function restyleSelected(patch) {
                    const s = selIndex >= 0 ? doc.shapes[selIndex] : null;
                    const next = s ? Markup.withStyle(s, patch) : null;
                    if (next && JSON.stringify(next) !== JSON.stringify(s))
                        commitShapes(Markup.replaceAt(doc.shapes, selIndex, next));
                }

                function setFill(on) {
                    root.markupFill = on;
                    restyleSelected({
                        fill: on
                    });
                }

                function nudge(dx, dy) {
                    if (selIndex >= 0) {
                        const next = Markup.replaceAt(doc.shapes, selIndex, Markup.translate(doc.shapes[selIndex], dx, dy));
                        if (nudgeIndex === selIndex) {
                            doc = Markup.amend(doc, next);
                        } else {
                            commitShapes(next);
                            nudgeIndex = selIndex;
                        }
                    } else if (staged) {
                        const b = root.screenBounds();
                        const nx = Math.max(b.l, Math.min(b.r - sel.width, sel.x + dx));
                        const ny = Math.max(b.t, Math.min(b.b - sel.height, sel.y + dy));
                        sel = Qt.rect(nx, ny, sel.width, sel.height);
                    }
                }

                function confirmStaged() {
                    commitText();
                    draft = null;
                    editIndex = -1;
                    selIndex = -1;
                    handle = "";
                    root.captureGlobal(sel.x, sel.y, sel.width, sel.height);
                }

                function finishPress(mods) {
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
                        else if (shouldStage(mods))
                            enterStaged(globalTargetX, globalTargetY, globalTargetW, globalTargetH);
                        else
                            root.captureGlobal(globalTargetX, globalTargetY, globalTargetW, globalTargetH);
                    } else if (!captureHovered(mods)) {
                        resetDrag();
                    }
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
                        property real cornerRadius: sessionRoot.staged ? 4 : (sessionRoot.dragging ? 10 : 22)
                        Behavior on cornerRadius {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                        readonly property var backgroundItem: backgroundViewLoader.item

                        Component.onCompleted: {
                            if (CompositorService.focusedMonitor?.name === modelData.name)
                                sessionRoot.pointerScreen = modelData;
                        }

                        Shortcut {
                            enabled: !sessionRoot.capturing
                            sequence: "Escape"
                            onActivated: sessionRoot.escapePressed(true)
                        }

                        Item {
                            id: keyHandler
                            focus: true
                            onActiveFocusChanged: if (!activeFocus)
                                sessionRoot.spaceHeld = false

                            Keys.onPressed: event => {
                                const isArrow = event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Up || event.key === Qt.Key_Down;
                                if (sessionRoot.capturing || (event.isAutoRepeat && !isArrow))
                                    return;
                                event.accepted = true;
                                const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
                                const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                                const canvas = root.activeTool === "screenshot";
                                if (ctrl && canvas && event.key === Qt.Key_Z) {
                                    if (shift)
                                        sessionRoot.redo();
                                    else
                                        sessionRoot.undo();
                                    return;
                                }
                                if (ctrl && canvas && event.key === Qt.Key_Y) {
                                    sessionRoot.redo();
                                    return;
                                }
                                switch (event.key) {
                                case Qt.Key_Delete:
                                case Qt.Key_Backspace:
                                    if (canvas && !ctrl)
                                        sessionRoot.deleteSelected();
                                    else
                                        event.accepted = false;
                                    break;
                                case Qt.Key_Left:
                                case Qt.Key_Right:
                                case Qt.Key_Up:
                                case Qt.Key_Down: {
                                    const d = shift ? 10 : 1;
                                    const dx = event.key === Qt.Key_Left ? -d : event.key === Qt.Key_Right ? d : 0;
                                    const dy = event.key === Qt.Key_Up ? -d : event.key === Qt.Key_Down ? d : 0;
                                    if (!ctrl && ((canvas && sessionRoot.selIndex >= 0) || sessionRoot.staged)) {
                                        sessionRoot.nudge(dx, dy);
                                    } else {
                                        event.accepted = false;
                                    }
                                    break;
                                }
                                case Qt.Key_Space:
                                    sessionRoot.spaceHeld = sessionRoot.dragging;
                                    break;
                                case Qt.Key_1:
                                    if (sessionRoot.staged)
                                        event.accepted = false;
                                    else
                                        sessionRoot.setMode("smart");
                                    break;
                                case Qt.Key_2:
                                    if (sessionRoot.staged)
                                        event.accepted = false;
                                    else
                                        sessionRoot.setMode("window");
                                    break;
                                case Qt.Key_3:
                                    if (sessionRoot.staged)
                                        event.accepted = false;
                                    else
                                        sessionRoot.setMode("fullscreen");
                                    break;
                                case Qt.Key_Tab:
                                    if (sessionRoot.staged)
                                        event.accepted = false;
                                    else
                                        root.cycleTool();
                                    break;
                                case Qt.Key_F:
                                    if (canvas && !ctrl)
                                        sessionRoot.setFill(!root.markupFill);
                                    else
                                        event.accepted = false;
                                    break;
                                case Qt.Key_G:
                                    if (root.activeTool === "record" && !root.modeLocked)
                                        root.setRecordFormat(Config.screencap.recordFormat === "gif" ? "mp4" : "gif");
                                    else
                                        event.accepted = false;
                                    break;
                                case Qt.Key_Return:
                                case Qt.Key_Enter:
                                    if (sessionRoot.staged)
                                        sessionRoot.confirmStaged();
                                    else if (!sessionRoot.pressing)
                                        sessionRoot.captureHovered(event.modifiers);
                                    break;
                                default: {
                                    const toolId = sessionRoot.toolForKey(event.key);
                                    if (canvas && toolId !== "" && !ctrl)
                                        sessionRoot.setTool(toolId);
                                    else
                                        event.accepted = false;
                                }
                                }
                            }
                            Keys.onReleased: event => {
                                if (event.key === Qt.Key_Space && !event.isAutoRepeat)
                                    sessionRoot.spaceHeld = false;
                            }
                        }

                        TextInput {
                            id: textInput
                            z: 3
                            visible: sessionRoot.textEdit !== null && sessionRoot.textScreen === overlay.screen
                            x: visible ? sessionRoot.textEdit.x - overlay.monX : 0
                            y: visible ? sessionRoot.textEdit.y - overlay.monY : 0
                            width: Math.max(16, contentWidth)
                            color: root.markupColor
                            font.family: Config.fontFamily
                            font.pixelSize: Markup.fontSize(root.markupWidth)
                            font.weight: Font.Bold
                            selectByMouse: false
                            onTextChanged: sessionRoot.textValue = text
                            Binding {
                                target: sessionRoot
                                property: "textW"
                                value: textInput.contentWidth
                                when: textInput.visible
                            }
                            Binding {
                                target: sessionRoot
                                property: "textH"
                                value: textInput.contentHeight
                                when: textInput.visible
                            }
                            onVisibleChanged: {
                                if (visible) {
                                    text = "";
                                    forceActiveFocus();
                                } else {
                                    keyHandler.forceActiveFocus();
                                }
                            }
                            Keys.onReturnPressed: sessionRoot.commitText()
                            Keys.onEnterPressed: sessionRoot.commitText()
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

                        MarkupLayer {
                            anchors.fill: parent
                            z: 0
                            visible: root.backingReady && root.activeTool === "screenshot"
                            shapes: sessionRoot.doc.shapes
                            draft: sessionRoot.draft
                            hiddenIndex: sessionRoot.editIndex
                            originX: overlay.monX
                            originY: overlay.monY
                            backgroundSource: overlay.backgroundItem
                        }

                        Item {
                            id: selectionUi
                            anchors.fill: parent
                            visible: !sessionRoot.capturing && root.backingReady
                            z: 1

                            QtObject {
                                id: currentHole
                                readonly property bool active: sessionRoot.dragging || sessionRoot.hovering || sessionRoot.staged
                                readonly property real x: Math.round(active ? (sessionRoot.staged ? sessionRoot.sel.x : (sessionRoot.dragging ? sessionRoot.globalTargetX : sessionRoot.animHlX)) : 0) - overlay.monX
                                readonly property real y: Math.round(active ? (sessionRoot.staged ? sessionRoot.sel.y : (sessionRoot.dragging ? sessionRoot.globalTargetY : sessionRoot.animHlY)) : 0) - overlay.monY
                                readonly property real w: Math.round(active ? (sessionRoot.staged ? sessionRoot.sel.width : (sessionRoot.dragging ? sessionRoot.globalTargetW : sessionRoot.animHlW)) : 0)
                                readonly property real h: Math.round(active ? (sessionRoot.staged ? sessionRoot.sel.height : (sessionRoot.dragging ? sessionRoot.globalTargetH : sessionRoot.animHlH)) : 0)
                            }

                            CornerDim {
                                type: 0
                                visible: currentHole.active && (sessionRoot.effTool === "region" || sessionRoot.staged)
                                x: currentHole.x
                                y: currentHole.y
                            }
                            CornerDim {
                                type: 1
                                visible: currentHole.active && (sessionRoot.effTool === "region" || sessionRoot.staged)
                                x: currentHole.x + currentHole.w - radiusSize
                                y: currentHole.y
                            }
                            CornerDim {
                                type: 2
                                visible: currentHole.active && (sessionRoot.effTool === "region" || sessionRoot.staged)
                                x: currentHole.x
                                y: currentHole.y + currentHole.h - radiusSize
                            }
                            CornerDim {
                                type: 3
                                visible: currentHole.active && (sessionRoot.effTool === "region" || sessionRoot.staged)
                                x: currentHole.x + currentHole.w - radiusSize
                                y: currentHole.y + currentHole.h - radiusSize
                            }

                            Item {
                                anchors.fill: parent
                                visible: sessionRoot.effTool === "region" || sessionRoot.staged
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

                            Repeater {
                                model: sessionRoot.staged && sessionRoot.effTool === "region" ? sessionRoot.handleSpecs : []
                                Rectangle {
                                    required property var modelData
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: Colors.md3.primary
                                    border.width: 1.5
                                    border.color: Colors.md3.surface
                                    x: sessionRoot.sel.x + sessionRoot.sel.width * modelData.fx - overlay.monX - 5
                                    y: sessionRoot.sel.y + sessionRoot.sel.height * modelData.fy - overlay.monY - 5
                                    NumberAnimation on opacity {
                                        from: 0
                                        to: 1
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                    NumberAnimation on scale {
                                        from: 0.4
                                        to: 1
                                        duration: 220
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            readonly property var selBounds: sessionRoot.selShape !== null ? Markup.bounds(sessionRoot.selShape) : ({
                                    x: 0,
                                    y: 0,
                                    w: 0,
                                    h: 0
                                })
                            readonly property var selHandles: sessionRoot.selShape !== null && root.activeTool === "screenshot" ? Markup.handlesFor(sessionRoot.selShape) : []
                            Rectangle {
                                visible: sessionRoot.selShape !== null && root.activeTool === "screenshot"
                                x: selectionUi.selBounds.x - 4 - overlay.monX
                                y: selectionUi.selBounds.y - 4 - overlay.monY
                                width: selectionUi.selBounds.w + 8
                                height: selectionUi.selBounds.h + 8
                                color: "transparent"
                                radius: 2
                                opacity: 0.8
                                border.color: Colors.md3.primary
                                border.width: 1
                            }
                            Repeater {
                                model: selectionUi.selHandles.length
                                Rectangle {
                                    required property int index
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: Colors.md3.primary
                                    border.width: 1.5
                                    border.color: Colors.md3.surface
                                    x: (selectionUi.selHandles[index]?.x ?? 0) - overlay.monX - 5
                                    y: (selectionUi.selHandles[index]?.y ?? 0) - overlay.monY - 5
                                }
                            }

                            Shape {
                                visible: overlay.isPointer && !sessionRoot.dragging && !sessionRoot.staged && sessionRoot.effTool === "region"
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
                                cursorShape: sessionRoot.cursorAt(sessionRoot.globalMouseX, sessionRoot.globalMouseY)
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
                                        if (sessionRoot.effTool !== "region" || sessionRoot.draft !== null) {
                                            sessionRoot.canvasDrag(gmx, gmy, !!(mouse.modifiers & Qt.ShiftModifier));
                                            return;
                                        }
                                        if (sessionRoot.handle !== "") {
                                            sessionRoot.regionDrag(gmx, gmy);
                                            return;
                                        }
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

                                    if (!sessionRoot.staged)
                                        sessionRoot.updateHover();
                                }

                                onPressed: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        sessionRoot.escapePressed(false);
                                        return;
                                    }
                                    if (mouse.button === Qt.LeftButton) {
                                        const gmx = overlay.monX + mouse.x - pointerArea.reach;
                                        const gmy = overlay.monY + mouse.y - pointerArea.reach;
                                        sessionRoot.leftHeld = true;
                                        sessionRoot.pressScreen = overlay.screen;
                                        if (sessionRoot.textEdit !== null) {
                                            sessionRoot.commitText();
                                            return;
                                        }
                                        if (sessionRoot.effTool !== "region") {
                                            sessionRoot.canvasPress(gmx, gmy, overlay.screen);
                                            return;
                                        }
                                        if (sessionRoot.regionPress(gmx, gmy))
                                            return;
                                        sessionRoot.cancelled = false;
                                        sessionRoot.pressing = true;
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
                                    if (mouse.button !== Qt.LeftButton)
                                        return;
                                    sessionRoot.leftHeld = false;
                                    if (sessionRoot.effTool !== "region" || sessionRoot.draft !== null)
                                        sessionRoot.canvasRelease();
                                    else if (sessionRoot.handle !== "")
                                        sessionRoot.handle = "";
                                    else
                                        sessionRoot.finishPress(mouse.modifiers);
                                }

                                onCanceled: {
                                    sessionRoot.resetDrag();
                                    sessionRoot.cancelled = false;
                                    sessionRoot.leftHeld = false;
                                    sessionRoot.draft = null;
                                    sessionRoot.editIndex = -1;
                                    sessionRoot.shapeHandle = "";
                                    sessionRoot.handle = "";
                                }
                            }

                            Rectangle {
                                id: regionChip
                                readonly property real lx: sessionRoot.sel.x - overlay.monX
                                readonly property real ly: sessionRoot.sel.y - overlay.monY
                                readonly property real lw: sessionRoot.sel.width
                                readonly property real lh: sessionRoot.sel.height
                                readonly property bool ownsCentre: lx + lw / 2 >= 0 && lx + lw / 2 < overlay.width && ly + lh / 2 >= 0 && ly + lh / 2 < overlay.height
                                readonly property real toolbarBand: markupToolbar.placed ? markupToolbar.height + 40 : 0
                                readonly property bool chipBelow: ly + lh + 10 + height <= overlay.height - 8 - (markupToolbar.y > overlay.height / 2 ? toolbarBand : 0)
                                readonly property bool chipAbove: ly - 10 - height >= 8 + (markupToolbar.y < overlay.height / 2 ? toolbarBand : 0)

                                readonly property bool shown: sessionRoot.staged && root.activeTool === "screenshot" && ownsCentre && sessionRoot.handle === "" && !sessionRoot.drawing
                                visible: shown || opacity > 0
                                opacity: shown ? 1 : 0
                                scale: shown ? 1 : 0.9
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 220
                                        easing.type: Easing.OutBack
                                    }
                                }

                                width: row.implicitWidth + 18
                                height: 40
                                radius: 20
                                color: Colors.md3.surface_container
                                border.width: 1
                                border.color: Colors.md3.outline_variant
                                x: Math.max(8, Math.min(overlay.width - width - 8, lx + lw / 2 - width / 2))
                                y: chipBelow ? ly + lh + 10 : (chipAbove ? ly - 10 - height : ly + lh - 10 - height)

                                Row {
                                    id: row
                                    x: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 32
                                    spacing: 6

                                    Text {
                                        width: implicitWidth
                                        height: 32
                                        verticalAlignment: Text.AlignVCenter
                                        text: Math.round(sessionRoot.sel.width) + " × " + Math.round(sessionRoot.sel.height)
                                        font.family: Config.fontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        font.features: ({ "tnum": 1 })
                                        color: Colors.md3.on_surface
                                    }

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: cancelMouse.containsMouse ? Colors.md3.surface_variant : Colors.md3.surface_container

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            name: "close"
                                            iconSize: 18
                                            color: Colors.md3.on_surface_variant
                                        }
                                        MouseArea {
                                            id: cancelMouse
                                            anchors.fill: parent
                                            enabled: regionChip.shown
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: sessionRoot.unstageRegion()
                                        }
                                        Tooltip {
                                            flat: true
                                            text: Localization.t("screenshot.tip_cancel")
                                            suppressed: sessionRoot.capturing || !sessionRoot.staged || !regionChip.shown
                                        }
                                    }

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: Colors.md3.primary

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            name: "check"
                                            iconSize: 18
                                            color: Colors.md3.on_primary
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: regionChip.shown
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: sessionRoot.confirmStaged()
                                        }
                                        Tooltip {
                                            flat: true
                                            text: Localization.t("screenshot.tip_confirm")
                                            suppressed: sessionRoot.capturing || !sessionRoot.staged || !regionChip.shown
                                        }
                                    }
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
                                opacity: overlay.isPointer && !sessionRoot.staged && sessionRoot.effTool === "region" ? 1 : 0
                                scale: overlay.isPointer && !sessionRoot.staged && sessionRoot.effTool === "region" ? 1 : 0.94
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
                                    Text {
                                        visible: sessionRoot.dragging && Config.screencap.instantCapture && root.activeTool === "screenshot"
                                        text: Localization.t("screenshot.hint_markup")
                                        font.pixelSize: 10
                                        color: Colors.md3.outline
                                    }
                                }
                            }
                        }

                        MarkupToolbar {
                            id: markupToolbar
                            z: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            readonly property bool placed: overlay.screen === sessionRoot.gestureScreen && root.activeTool === "screenshot" && root.backingReady
                            readonly property bool atBottom: sessionRoot.staged && sessionRoot.sel.y - overlay.monY < 120
                            shown: placed && !sessionRoot.dragging && !sessionRoot.drawing && sessionRoot.handle === "" && !sessionRoot.capturing
                            y: atBottom ? parent.height - height - 32 : 32
                            visible: (shown || opacity > 0) && !sessionRoot.capturing
                            opacity: shown ? 1.0 : 0.0
                            transform: Translate {
                                y: markupToolbar.shown ? 0 : (markupToolbar.atBottom ? 96 : -96)
                                Behavior on y {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                            Behavior on opacity {
                                enabled: !sessionRoot.capturing
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                            tool: sessionRoot.tool
                            color: root.markupColor
                            strokeWidth: root.markupWidth
                            fill: root.markupFill
                            fillShape: {
                                const t = sessionRoot.selShape?.type ?? sessionRoot.tool;
                                return Markup.isFillable(t) ? t : "";
                            }
                            canUndo: sessionRoot.doc.past.length > 0
                            canRedo: sessionRoot.doc.future.length > 0
                            canDelete: sessionRoot.selIndex >= 0
                            onToolPicked: id => sessionRoot.setTool(id)
                            onColorPicked: c => {
                                root.markupColor = c;
                                sessionRoot.restyleSelected({
                                    color: c
                                });
                            }
                            onWidthPicked: w => {
                                root.markupWidth = w;
                                root.markupFill = false;
                                sessionRoot.restyleSelected({
                                    width: w,
                                    fill: false
                                });
                            }
                            onFillPicked: on => sessionRoot.setFill(on)
                            onDeleteRequested: sessionRoot.deleteSelected()
                            onUndoRequested: sessionRoot.undo()
                            onRedoRequested: sessionRoot.redo()
                            onCloseRequested: root._closeOverlay()
                        }

                        Item {
                            id: floatingPill
                            z: 2

                            property bool showPill: overlay.screen === sessionRoot.gestureScreen && !sessionRoot.dragging && !sessionRoot.drawing && !sessionRoot.capturing && root.backingReady && !sessionRoot.staged
                            visible: (showPill || opacity > 0) && !sessionRoot.capturing
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
                                        SlidingIndicator {
                                            id: pillToolInd
                                            index: toolTrack.activeIndex
                                            step: toolTrack.btnW
                                            color: Colors.md3.secondary
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
                                                    property color iconColor: pillToolInd.covers(x + width / 2) ? Colors.md3.on_secondary : Colors.md3.on_surface

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
                                                    Tooltip {
                                                        flat: true
                                                        text: Localization.t("screenshot.tip_" + modelData.id)
                                                        suppressed: sessionRoot.capturing || !floatingPill.showPill
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
                                    id: formatContainer
                                    readonly property bool shown: root.activeTool === "record" && !root.modeLocked
                                    readonly property real innerW: 17 + formatTrack.btnW * 2
                                    width: shown ? innerW : 0
                                    height: 56
                                    clip: true
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutCubic
                                        }
                                    }

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
                                            id: formatTrack
                                            readonly property real btnW: 44
                                            readonly property real btnH: 40
                                            readonly property int activeIndex: Config.screencap.recordFormat === "gif" ? 1 : 0
                                            width: btnW * 2
                                            height: btnH
                                            anchors.verticalCenter: parent.verticalCenter

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: height / 2
                                                color: Colors.md3.surface_container_highest
                                            }
                                            SlidingIndicator {
                                                id: formatInd
                                                index: formatTrack.activeIndex
                                                step: formatTrack.btnW
                                                color: Colors.md3.secondary
                                            }
                                            Row {
                                                anchors.fill: parent
                                                Repeater {
                                                    model: [
                                                        {
                                                            format: "mp4",
                                                            icon: "movie"
                                                        },
                                                        {
                                                            format: "gif",
                                                            icon: "gif-box"
                                                        },
                                                    ]
                                                    Item {
                                                        required property var modelData
                                                        required property int index
                                                        width: formatTrack.btnW
                                                        height: formatTrack.btnH

                                                        MaterialIcon {
                                                            name: modelData.icon
                                                            anchors.centerIn: parent
                                                            iconSize: 20
                                                            color: formatInd.covers(parent.x + parent.width / 2) ? Colors.md3.on_secondary : Colors.md3.on_surface
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            enabled: formatContainer.shown
                                                            onClicked: root.setRecordFormat(modelData.format)
                                                        }
                                                        Tooltip {
                                                            flat: true
                                                            text: Localization.t("screenshot.tip_" + modelData.format)
                                                            suppressed: sessionRoot.capturing || !floatingPill.showPill
                                                        }
                                                    }
                                                }
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

                                            SlidingIndicator {
                                                id: indicatorPill
                                                index: recordingModeContainer.showStop ? 0 : modeTrack.activeIndex
                                                span: recordingModeContainer.showStop ? 3 : 1
                                                step: modeTrack.btnW
                                                clip: true
                                                color: recordingModeContainer.showStop ? (ScreencapService.recordingGif ? Colors.md3.tertiary : Colors.md3.error) : Colors.md3.primary
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
                                                            color: ScreencapService.recordingGif ? Colors.md3.on_tertiary : Colors.md3.on_error
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                        Text {
                                                            text: Localization.t("screenshot.stop_recording")
                                                            font.pixelSize: 12
                                                            font.weight: Font.Medium
                                                            color: ScreencapService.recordingGif ? Colors.md3.on_tertiary : Colors.md3.on_error
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
                                                        property color iconColor: indicatorPill.covers(x + width / 2) ? Colors.md3.on_primary : Colors.md3.on_surface

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
                                                        Tooltip {
                                                            flat: true
                                                            text: Localization.t("screenshot.tip_mode_" + modelData.comp)
                                                            suppressed: sessionRoot.capturing || !floatingPill.showPill || recordingModeContainer.showStop
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
                                    Tooltip {
                                        flat: true
                                        text: Localization.t("screenshot.tip_close")
                                        suppressed: sessionRoot.capturing || !floatingPill.showPill
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