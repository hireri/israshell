import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Shapes
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    readonly property real windowPad: 4
    readonly property color crosshairColor: Colors.md3.primary
    readonly property color surfaceColor: Colors.md3.surface_container

    property bool active: false
    property string forcedAction: "smart"
    property string activeTool: "screenshot"
    property string _capturedPath: ""

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
            root.forcedAction = "fullscreen";
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

    function _openOverlay() {
        if (!Hyprland.focusedMonitor)
            return;
        root.active = true;
        uiLoader.active = true;
        clientFetchProc.running = true;
        ScreencapService.refresh();
    }

    function captureGlobal(gx, gy, gw, gh) {
        const geom = `${Math.round(gx)},${Math.round(gy)} ${Math.round(gw)}x${Math.round(gh)}`;
        const tool = root.toolList.find(t => t.id === root.activeTool);

        captureProc.command = ["sh", "-c", `${tool?.cmd ?? ""} '${geom}'`];

        if (root.activeTool === "screenshot") {
            if (uiLoader.item)
                uiLoader.item.capturing = true;
        } else {
            root.active = false;
            uiLoader.active = false;
        }
        captureDelay.start();
    }

    property var clientRects: []

    Process {
        id: clientFetchProc
        command: ["hyprctl", "clients", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const clients = JSON.parse(text);
                    const pad = root.windowPad;
                    const activeWsIds = [];
                    const fullscreenWsIds = [];
                    for (const m of Hyprland.monitors.values) {
                        const ws = m.activeWorkspace;
                        if (ws) {
                            activeWsIds.push(ws.id);
                            if (ws.hasFullscreen)
                                fullscreenWsIds.push(ws.id);
                        }
                    }
                    const rects = [];
                    for (const c of clients) {
                        if (!activeWsIds.includes(c.workspace.id))
                            continue;
                        if (fullscreenWsIds.includes(c.workspace.id))
                            continue;
                        if (!c.mapped || c.hidden)
                            continue;
                        rects.push({
                            x: c.at[0] - pad,
                            y: c.at[1] - pad,
                            w: c.size[0] + pad * 2,
                            h: c.size[1] + pad * 2
                        });
                    }
                    root.clientRects = rects;
                } catch (e) {
                    console.error("clientFetchProc:", e);
                }
            }
        }
    }

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
            if (root.activeTool === "screenshot" && root._capturedPath !== "") {
                screenshotPreview.show(root._capturedPath);
                root._capturedPath = "";
            }
            root.active = false;
            uiLoader.active = false;
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
                property var focusedScreen: null

                property real animHlX: 0
                property real animHlY: 0
                property real animHlW: 0
                property real animHlH: 0

                Behavior on animHlX {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on animHlY {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on animHlW {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on animHlH {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                function resetDrag() {
                    dragging = false;
                    pressing = false;
                    hovering = false;
                    cancelled = true;
                    globalTargetX = 0;
                    globalTargetY = 0;
                    globalTargetW = 0;
                    globalTargetH = 0;
                    globalHlX = 0;
                    globalHlY = 0;
                    globalHlW = 0;
                    globalHlH = 0;
                }

                function windowAtGlobal(gx, gy) {
                    const rects = root.clientRects;
                    for (let i = rects.length - 1; i >= 0; i--) {
                        const r = rects[i];
                        if (gx >= r.x && gx < r.x + r.w && gy >= r.y && gy < r.y + r.h)
                            return r;
                    }
                    return null;
                }

                Timer {
                    id: dragSync
                    interval: 12
                    repeat: true
                    running: sessionRoot.dragging
                    onTriggered: {
                        sessionRoot.globalHlX = sessionRoot.globalTargetX;
                        sessionRoot.globalHlY = sessionRoot.globalTargetY;
                        sessionRoot.globalHlW = sessionRoot.globalTargetW;
                        sessionRoot.globalHlH = sessionRoot.globalTargetH;
                    }
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
                        WlrLayershell.keyboardFocus: isFocused && !sessionRoot.capturing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                        readonly property bool isFocused: sessionRoot.focusedScreen === modelData
                        property real monX: modelData.x
                        property real monY: modelData.y
                        property int cornerRadius: sessionRoot.dragging ? 10 : 22

                        Component.onCompleted: {
                            if (Hyprland.focusedMonitor?.name === modelData.name)
                                sessionRoot.focusedScreen = modelData;
                        }

                        Shortcut {
                            enabled: isFocused && !sessionRoot.capturing
                            sequence: "Escape"
                            onActivated: {
                                root.active = false;
                                uiLoader.active = false;
                            }
                        }

                        ScreencopyView {
                            anchors.fill: parent
                            captureSource: overlay.screen
                        }

                        Item {
                            anchors.fill: parent
                            visible: !sessionRoot.capturing

                            QtObject {
                                id: currentHole
                                readonly property bool active: sessionRoot.dragging || sessionRoot.hovering
                                readonly property real x: (active ? (sessionRoot.dragging ? sessionRoot.globalTargetX : sessionRoot.animHlX) : 0) - overlay.monX
                                readonly property real y: (active ? (sessionRoot.dragging ? sessionRoot.globalTargetY : sessionRoot.animHlY) : 0) - overlay.monY
                                readonly property real w: active ? (sessionRoot.dragging ? sessionRoot.globalTargetW : sessionRoot.animHlW) : 0
                                readonly property real h: active ? (sessionRoot.dragging ? sessionRoot.globalTargetH : sessionRoot.animHlH) : 0
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
                                visible: isFocused
                                anchors.fill: parent
                                ShapePath {
                                    strokeColor: Qt.alpha(root.crosshairColor, 0.35)
                                    strokeWidth: 1
                                    strokeStyle: ShapePath.DashLine
                                    dashPattern: [4, 8]
                                    fillColor: "transparent"
                                    startX: 0
                                    startY: sessionRoot.globalMouseY - overlay.monY
                                    PathLine {
                                        x: overlay.width
                                        y: sessionRoot.globalMouseY - overlay.monY
                                    }
                                }
                                ShapePath {
                                    strokeColor: sessionRoot.dragging ? Qt.alpha(root.crosshairColor, 0.55) : "transparent"
                                    strokeWidth: 1
                                    strokeStyle: ShapePath.DashLine
                                    dashPattern: [4, 8]
                                    fillColor: "transparent"
                                    startX: 0
                                    startY: sessionRoot.globalPressY - overlay.monY
                                    PathLine {
                                        x: overlay.width
                                        y: sessionRoot.globalPressY - overlay.monY
                                    }
                                }
                            }
                            Shape {
                                visible: isFocused
                                anchors.fill: parent
                                ShapePath {
                                    strokeColor: Qt.alpha(root.crosshairColor, 0.35)
                                    strokeWidth: 1
                                    strokeStyle: ShapePath.DashLine
                                    dashPattern: [4, 8]
                                    fillColor: "transparent"
                                    startX: sessionRoot.globalMouseX - overlay.monX
                                    startY: 0
                                    PathLine {
                                        x: sessionRoot.globalMouseX - overlay.monX
                                        y: overlay.height
                                    }
                                }
                                ShapePath {
                                    strokeColor: sessionRoot.dragging ? Qt.alpha(root.crosshairColor, 0.55) : "transparent"
                                    strokeWidth: 1
                                    strokeStyle: ShapePath.DashLine
                                    dashPattern: [4, 8]
                                    fillColor: "transparent"
                                    startX: sessionRoot.globalPressX - overlay.monX
                                    startY: 0
                                    PathLine {
                                        x: sessionRoot.globalPressX - overlay.monX
                                        y: overlay.height
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.CrossCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onPositionChanged: mouse => {
                                    const gmx = overlay.monX + mouse.x;
                                    const gmy = overlay.monY + mouse.y;
                                    sessionRoot.globalMouseX = gmx;
                                    sessionRoot.globalMouseY = gmy;

                                    if (!isFocused && !sessionRoot.dragging)
                                        sessionRoot.focusedScreen = overlay.screen;

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
                                        if (sessionRoot.dragging) {
                                            let dx = gmx - sessionRoot.globalPressX;
                                            let dy = gmy - sessionRoot.globalPressY;
                                            if (mouse.modifiers & Qt.ShiftModifier) {
                                                const size = Math.max(Math.abs(dx), Math.abs(dy));
                                                dx = dx >= 0 ? size : -size;
                                                dy = dy >= 0 ? size : -size;
                                            }
                                            sessionRoot.globalTargetX = dx >= 0 ? sessionRoot.globalPressX : sessionRoot.globalPressX + dx;
                                            sessionRoot.globalTargetY = dy >= 0 ? sessionRoot.globalPressY : sessionRoot.globalPressY + dy;
                                            sessionRoot.globalTargetW = Math.abs(dx);
                                            sessionRoot.globalTargetH = Math.abs(dy);
                                        }
                                        return;
                                    }

                                    if (sessionRoot.cancelled)
                                        return;
                                    let hoveringSomething = false;
                                    let tx = 0, ty = 0, tw = 0, th = 0;
                                    const action = sessionRoot.effectiveAction;

                                    if (action === "fullscreen") {
                                        hoveringSomething = true;
                                        tx = overlay.monX;
                                        ty = overlay.monY;
                                        tw = overlay.width;
                                        th = overlay.height;
                                    } else if (action === "smart" || action === "window") {
                                        const win = sessionRoot.windowAtGlobal(gmx, gmy);
                                        if (win) {
                                            hoveringSomething = true;
                                            tx = win.x;
                                            ty = win.y;
                                            tw = win.w;
                                            th = win.h;
                                        }
                                    }

                                    if (hoveringSomething && !sessionRoot.pressing && !sessionRoot.dragging) {
                                        sessionRoot.globalHlX = tx;
                                        sessionRoot.globalHlY = ty;
                                        sessionRoot.globalHlW = tw;
                                        sessionRoot.globalHlH = th;
                                        sessionRoot.animHlX = tx;
                                        sessionRoot.animHlY = ty;
                                        sessionRoot.animHlW = tw;
                                        sessionRoot.animHlH = th;
                                        sessionRoot.hovering = true;
                                    } else {
                                        sessionRoot.hovering = false;
                                    }
                                }

                                onPressed: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        sessionRoot.resetDrag();
                                        return;
                                    }
                                    if (mouse.button === Qt.LeftButton) {
                                        const gmx = overlay.monX + mouse.x;
                                        const gmy = overlay.monY + mouse.y;
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
                                    sessionRoot.pressing = false;
                                    if (mouse.button === Qt.RightButton)
                                        return;
                                    if (sessionRoot.cancelled) {
                                        sessionRoot.cancelled = false;
                                        return;
                                    }

                                    const action = sessionRoot.effectiveAction;

                                    if (action === "fullscreen") {
                                        root.captureGlobal(overlay.monX, overlay.monY, overlay.width, overlay.height);
                                        return;
                                    }
                                    if (sessionRoot.dragging) {
                                        if (sessionRoot.globalTargetW < 4 || sessionRoot.globalTargetH < 4) {
                                            sessionRoot.resetDrag();
                                            return;
                                        }
                                        root.captureGlobal(sessionRoot.globalTargetX, sessionRoot.globalTargetY, sessionRoot.globalTargetW, sessionRoot.globalTargetH);
                                        return;
                                    }
                                    if (action === "smart" || action === "window") {
                                        if (sessionRoot.hovering && sessionRoot.globalHlW > 0 && sessionRoot.globalHlH > 0) {
                                            root.captureGlobal(sessionRoot.globalHlX, sessionRoot.globalHlY, sessionRoot.globalHlW, sessionRoot.globalHlH);
                                        } else if (action === "smart") {
                                            root.captureGlobal(overlay.monX, overlay.monY, overlay.width, overlay.height);
                                        } else {
                                            sessionRoot.resetDrag();
                                        }
                                        return;
                                    }
                                    sessionRoot.resetDrag();
                                }
                            }

                            Item {
                                visible: isFocused
                                x: Math.min(sessionRoot.globalMouseX - overlay.monX + 16, parent.width - width - 16)
                                y: Math.min(sessionRoot.globalMouseY - overlay.monY + 16, parent.height - height - 16)
                                width: tooltipContent.implicitWidth + 24
                                height: tooltipContent.implicitHeight + 20

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 20
                                    topLeftRadius: 8
                                    color: root.surfaceColor
                                    border.width: 1
                                    border.color: Colors.md3.outline_variant
                                }
                                Column {
                                    id: tooltipContent
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Row {
                                        visible: sessionRoot.dragging
                                        spacing: 4
                                        Text {
                                            text: Math.round(sessionRoot.globalHlW)
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: Colors.md3.on_surface
                                        }
                                        Text {
                                            text: "×"
                                            font.pixelSize: 10
                                            color: Colors.md3.on_surface_variant
                                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                        }
                                        Text {
                                            text: Math.round(sessionRoot.globalHlH)
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: Colors.md3.on_surface
                                        }
                                        Text {
                                            text: "px"
                                            font.pixelSize: 9
                                            color: Colors.md3.outline
                                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                        }
                                    }
                                    Rectangle {
                                        visible: sessionRoot.dragging
                                        width: tooltipContent.implicitWidth
                                        height: 1
                                        color: Colors.md3.outline_variant
                                        opacity: 0.5
                                    }
                                    Column {
                                        spacing: 4
                                        Row {
                                            visible: sessionRoot.dragging
                                            spacing: 6
                                            Text {
                                                text: "FROM"
                                                font.pixelSize: 8
                                                font.letterSpacing: 1
                                                color: Colors.md3.outline
                                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                            }
                                            Text {
                                                text: Math.round(sessionRoot.globalPressX) + ",  " + Math.round(sessionRoot.globalPressY)
                                                font.pixelSize: 10
                                                font.family: Config.fontMonospace
                                                color: Colors.md3.on_surface_variant
                                            }
                                        }
                                        Row {
                                            spacing: 6
                                            Text {
                                                text: sessionRoot.dragging ? "TO     " : "POS"
                                                font.pixelSize: 8
                                                font.letterSpacing: 1
                                                color: Colors.md3.outline
                                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                            }
                                            Text {
                                                text: Math.round(sessionRoot.globalMouseX) + ",  " + Math.round(sessionRoot.globalMouseY)
                                                font.pixelSize: 10
                                                font.family: Config.fontMonospace
                                                color: Colors.md3.on_surface_variant
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            id: floatingPill

                            property bool showPill: isFocused && !sessionRoot.dragging && !sessionRoot.capturing
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
                                                        onClicked: {
                                                            root.activeTool = modelData.id;
                                                            if (modelData.id === "record")
                                                                ScreencapService.refresh();
                                                        }
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
                                    readonly property bool showStop: root.activeTool === "record" && ScreencapService.isRecording
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
                                                            text: "Stop recording"
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
                                                        ScreencapService.isRecording = false;
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
                                                            onClicked: root.forcedAction = modelData.action
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
                                        CloseIcon {
                                            anchors.centerIn: parent
                                            iconSize: 20
                                            color: Colors.md3.on_surface_variant
                                        }
                                        MouseArea {
                                            id: closeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.active = false;
                                                uiLoader.active = false;
                                            }
                                        }
                                    }
                                }
                            }

                            Component {
                                id: ssIconComp
                                SnippingIcon {}
                            }
                            Component {
                                id: recIconComp
                                RecordIcon {}
                            }
                            Component {
                                id: ctsIconComp
                                ImageSearchIcon {}
                            }
                            Component {
                                id: ocrIconComp
                                OcrIcon {}
                            }
                            Component {
                                id: regionIconComp
                                RegionIcon {}
                            }
                            Component {
                                id: windowIconComp
                                WindowIcon {}
                            }
                            Component {
                                id: screenIconComp
                                ScreenIcon {}
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
