import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.style

Item {
    id: root

    readonly property string outputDir: (Quickshell.env("HOME") + "/Pictures") + "/Screenshots"
    readonly property string editor: "satty"
    readonly property real windowPad: 4

    readonly property color crosshairColor: Colors.md3.primary
    readonly property color surfaceColor: Colors.md3.surface_container
    readonly property color onSurfaceColor: Colors.md3.on_surface

    property bool active: false
    property string forcedAction: "smart"

    property string pendingEditPath: ""

    IpcHandler {
        target: "screenshot"
        function activate(): void {
            if (!root.active) {
                root.forcedAction = "smart";
                root._startCapture();
            }
        }
        function region(): void {
            if (!root.active) {
                root.forcedAction = "region";
                root._startCapture();
            }
        }
        function window(): void {
            if (!root.active) {
                root.forcedAction = "window";
                root._startCapture();
            }
        }
        function screen(): void {
            if (!root.active) {
                root.forcedAction = "fullscreen";
                root._startCapture();
            }
        }
    }

    function _startCapture() {
        if (!Hyprland.focusedMonitor)
            return;
        root.active = true;
        uiLoader.active = true;
        clientFetchProc.running = true;
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
                    console.error("clientFetchProc parse error:", e);
                }
            }
        }
    }

    function captureGlobal(gx, gy, gw, gh) {
        if (uiLoader.item)
            uiLoader.item.capturing = true;

        const ts = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        const path = root.outputDir + "/screenshot-" + ts + ".png";
        const cx = Math.round(gx), cy = Math.round(gy);
        const cw = Math.round(gw), ch = Math.round(gh);

        root.pendingEditPath = path;

        const cmd = `
        mkdir -p '${root.outputDir}' && \
        grim -g "${cx},${cy} ${cw}x${ch}" '${path}' && \
        wl-copy < '${path}' && \
        res=$(notify-send "Screenshot saved" "<img src=\\"${path}\\"/>Saved to ${root.outputDir}" -i camera-photo -a Screenshot -A "default=Edit") && \
        if [ "$res" = "default" ]; then echo "OPEN_EDITOR"; fi
    `;

        captureProc.command = ["sh", "-c", cmd];
        captureProc.running = true;
    }

    Process {
        id: captureProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "OPEN_EDITOR") {
                    if (root.editor === "satty") {
                        editProc.command = ["satty", "--filename", root.pendingEditPath, "--output-filename", root.pendingEditPath, "--actions-on-enter", "save-to-clipboard", "--save-after-copy", "--early-exit", "--copy-command", "wl-copy"];
                    } else {
                        editProc.command = [root.editor, root.pendingEditPath];
                    }
                    editProc.running = true;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.length)
                console.error(text)
        }
        onExited: {
            root.active = false;
            uiLoader.active = false;
        }
    }

    Process {
        id: editProc
        running: false
        stderr: StdioCollector {
            onStreamFinished: if (text.length)
                console.error("editor:", text)
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
                                readonly property real x: (active ? sessionRoot.globalHlX : 0) - overlay.monX
                                readonly property real y: (active ? sessionRoot.globalHlY : 0) - overlay.monY
                                readonly property real w: active ? sessionRoot.globalHlW : 0
                                readonly property real h: active ? sessionRoot.globalHlH : 0
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
                                visible: currentHole.active
                                x: currentHole.x
                                y: currentHole.y
                                width: currentHole.w
                                height: currentHole.h
                                color: "transparent"
                                border.color: root.crosshairColor
                                border.width: 2
                            }

                            Rectangle {
                                visible: isFocused
                                x: 0
                                y: sessionRoot.globalMouseY - overlay.monY
                                width: parent.width
                                height: 1
                                color: root.crosshairColor
                                opacity: 0.35
                            }
                            Rectangle {
                                visible: isFocused
                                x: sessionRoot.globalMouseX - overlay.monX
                                y: 0
                                width: 1
                                height: parent.height
                                color: root.crosshairColor
                                opacity: 0.35
                            }
                            Rectangle {
                                visible: isFocused && sessionRoot.dragging
                                x: 0
                                y: sessionRoot.globalPressY - overlay.monY
                                width: parent.width
                                height: 1
                                color: root.crosshairColor
                                opacity: 0.55
                            }
                            Rectangle {
                                visible: isFocused && sessionRoot.dragging
                                x: sessionRoot.globalPressX - overlay.monX
                                y: 0
                                width: 1
                                height: parent.height
                                color: root.crosshairColor
                                opacity: 0.55
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
                                        if (!sessionRoot.dragging && root.forcedAction !== "window" && root.forcedAction !== "fullscreen") {
                                            const dx = gmx - sessionRoot.globalPressX;
                                            const dy = gmy - sessionRoot.globalPressY;
                                            if (Math.sqrt(dx * dx + dy * dy) >= 8)
                                                sessionRoot.dragging = true;
                                        }
                                        if (sessionRoot.dragging) {
                                            sessionRoot.globalTargetX = Math.min(sessionRoot.globalPressX, gmx);
                                            sessionRoot.globalTargetY = Math.min(sessionRoot.globalPressY, gmy);
                                            sessionRoot.globalTargetW = Math.abs(gmx - sessionRoot.globalPressX);
                                            sessionRoot.globalTargetH = Math.abs(gmy - sessionRoot.globalPressY);
                                        }
                                        return;
                                    }

                                    if (sessionRoot.cancelled)
                                        return;

                                    let hoveringSomething = false;
                                    let tx = 0, ty = 0, tw = 0, th = 0;

                                    if (root.forcedAction === "fullscreen") {
                                        hoveringSomething = true;
                                        tx = overlay.monX;
                                        ty = overlay.monY;
                                        tw = overlay.width;
                                        th = overlay.height;
                                    } else if (root.forcedAction === "smart" || root.forcedAction === "window") {
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

                                    const action = root.forcedAction;

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
                                    if (action === "region") {
                                        sessionRoot.resetDrag();
                                        return;
                                    }

                                    if (action === "window" || action === "smart") {
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
                                width: coordsText.implicitWidth + 16
                                height: coordsText.implicitHeight + 8

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 16
                                    color: root.surfaceColor
                                    border.width: 1
                                    border.color: Colors.md3.outline_variant
                                }
                                Text {
                                    id: coordsText
                                    anchors.centerIn: parent
                                    color: Colors.md3.on_surface
                                    font.pixelSize: 12
                                    font.family: Config.fontMonospace
                                    text: {
                                        const cx = Math.round(sessionRoot.globalMouseX);
                                        const cy = Math.round(sessionRoot.globalMouseY);
                                        if (sessionRoot.dragging) {
                                            const sx = Math.round(sessionRoot.globalPressX);
                                            const sy = Math.round(sessionRoot.globalPressY);
                                            return `${sx}, ${sy} 󱦰 ${cx}, ${cy} | ${Math.round(sessionRoot.globalHlW)} × ${Math.round(sessionRoot.globalHlH)}`;
                                        }
                                        return `${cx}, ${cy}`;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
