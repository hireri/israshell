pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.services
import qs.style

Item {
    id: root

    property var controller: null
    readonly property bool isOpen: controller ? controller.isOpen : false
    readonly property var windows: controller?.windows ?? []
    readonly property var specialNames: controller?.specialNames ?? []

    anchors.fill: parent

    readonly property var scr: controller?._targetScreen ?? Quickshell.screens[0]
    readonly property int columns: 5
    readonly property int spacing: 8
    readonly property int pad: 16
    readonly property int tileRadius: 10
    readonly property real minRadius: 1.5
    readonly property int ringWidth: 2
    readonly property int bezel: 3

    function nestedRadius(gap: real): real {
        return Math.max(minRadius, tileRadius - gap);
    }

    readonly property real tileW: Math.round(Math.min(288, ((scr?.width ?? 1920) * 0.85 - 2 * pad - (columns - 1) * spacing) / columns))
    readonly property var usable: CompositorService.usableSize(scr) ?? { w: scr?.width ?? 1920, h: scr?.height ?? 1080 }
    readonly property real tileH: Math.round(tileW * usable.h / usable.w)
    readonly property real tileStepX: tileW + spacing
    readonly property real tileStepY: tileH + spacing
    readonly property real gridH: 2 * tileH + spacing
    readonly property real specialTop: gridH + 40
    readonly property real contentW: columns * tileW + (columns - 1) * spacing
    readonly property real contentH: specialNames.length > 0 ? specialTop + Math.ceil(specialNames.length / columns) * tileStepY - spacing : gridH

    function tileX(wsId: int, special: string): real {
        const i = wsId > 0 ? wsId - 1 : Math.max(0, specialNames.indexOf(special));
        return (i % columns) * tileStepX;
    }

    function tileY(wsId: int, special: string): real {
        if (wsId > 0)
            return Math.floor((wsId - 1) / columns) * tileStepY;
        return specialTop + Math.floor(Math.max(0, specialNames.indexOf(special)) / columns) * tileStepY;
    }

    function frameKey(w: var): string {
        return w.workspaceId > 0 ? "w" + w.workspaceId : w.workspaceName;
    }

    function covered(w: var, fullscreen: bool): bool {
        const m = w.monitor;
        return fullscreen && !w.fullscreen && !!m && w.x >= m.x && w.y >= m.y && w.x + w.w <= m.x + m.w && w.y + w.h <= m.y + m.h;
    }

    readonly property var frames: {
        const groups = {};
        for (const a in byAddr) {
            const w = byAddr[a];
            if (!w.monitor)
                continue;
            const k = frameKey(w);
            (groups[k] = groups[k] ?? []).push(w);
        }
        const out = {};
        for (const k in groups) {
            const ws = groups[k];
            const fullscreen = ws.some(w => w.fullscreen);
            const m = ws[0].monitor;
            let g = Infinity;
            for (const w of ws)
                if (!w.floating && !w.fullscreen)
                    g = Math.min(g, ...[w.x - m.x, w.y - m.y].filter(v => v >= 0));
            g = isFinite(g) ? g : 0;
            let x0 = 0, y0 = 0, x1 = m.w, y1 = m.h;
            for (const w of ws) {
                const wg = w.fullscreen ? 0 : g;
                x0 = Math.min(x0, w.x - m.x - wg);
                y0 = Math.min(y0, w.y - m.y - wg);
                x1 = Math.max(x1, w.x - m.x + w.w + wg);
                y1 = Math.max(y1, w.y - m.y + w.h + wg);
            }
            const spill = (x1 - x0) > m.w + 1 || (y1 - y0) > m.h + 1;
            const s = Math.min(tileW / (x1 - x0), tileH / (y1 - y0));
            const fill = !spill && Math.abs((tileW / tileH) / (m.w / m.h) - 1) < 0.01;

            const sx = fill ? tileW / m.w : s, sy = fill ? tileH / m.h : s;
            const ox = Math.round((tileW - (x1 - x0) * sx) / 2 - x0 * sx);
            const oy = Math.round((tileH - (y1 - y0) * sy) / 2 - y0 * sy);

            let bx0 = tileW, by0 = tileH, bx1 = 0, by1 = 0;
            const colXs = [];
            for (const w of ws) {
                if (w.floating || covered(w, fullscreen))
                    continue;
                bx0 = Math.min(bx0, ox + Math.round((w.x - m.x) * sx));
                by0 = Math.min(by0, oy + Math.round((w.y - m.y) * sy));
                bx1 = Math.max(bx1, ox + Math.round((w.x - m.x + w.w) * sx));
                by1 = Math.max(by1, oy + Math.round((w.y - m.y + w.h) * sy));
                if (!colXs.some(x => Math.abs(x - w.x) < 8))
                    colXs.push(w.x);
            }

            const outerRadius = nestedRadius(Math.max(0, Math.min(bx0, tileW - bx1), Math.min(by0, tileH - by1)));
            const winRadius = Math.max(minRadius, outerRadius / Math.sqrt(Math.max(1, colXs.length)));

            const vx = Math.max(0, ox - bezel), vy = Math.max(0, oy - bezel);
            const vw = Math.min(tileW, ox + Math.round(m.w * sx) + bezel) - vx, vh = Math.min(tileH, oy + Math.round(m.h * sy) + bezel) - vy;

            out[k] = { sx: sx, sy: sy, ox: ox, oy: oy, vx: vx, vy: vy, vw: vw, vh: vh, winRadius: winRadius, outerRadius: outerRadius, bx0: bx0, by0: by0, bx1: bx1, by1: by1, vpRadius: outerRadius + bezel, spill: spill, fill: fill, fullscreen: fullscreen };
        }
        return out;
    }

    readonly property var byAddr: {
        const m = {};
        for (const w of windows)
            m[w.address] = w.fullscreen && w.monitor ? Object.assign({}, w, { x: w.monitor.x, y: w.monitor.y, w: w.monitor.w, h: w.monitor.h }) : w;
        return m;
    }

    ListModel {
        id: winModel
    }

    function syncModel(): void {
        const want = windows.map(w => w.address);
        const have = [];
        for (let i = winModel.count - 1; i >= 0; i--) {
            const a = winModel.get(i).address;
            if (want.includes(a))
                have.push(a);
            else
                winModel.remove(i);
        }
        for (const a of want)
            if (!have.includes(a))
                winModel.append({ address: a });
    }
    onWindowsChanged: syncModel()

    property int dropWs: 0
    property string dropSpecial: ""

    function tileAt(px: real, py: real): var {
        const col = Math.floor(px / tileStepX);
        if (col < 0 || col >= columns || px - col * tileStepX > tileW)
            return null;
        if (py >= 0 && py < gridH) {
            const row = Math.floor(py / tileStepY);
            if (py - row * tileStepY > tileH || row > 1)
                return null;
            return { wsId: row * columns + col + 1, special: "" };
        }
        if (py >= specialTop) {
            const row = Math.floor((py - specialTop) / tileStepY);
            const i = row * columns + col;
            if (i < specialNames.length && py - specialTop - row * tileStepY <= tileH)
                return { wsId: 0, special: specialNames[i] };
        }
        return null;
    }

    function hover(px: real, py: real): void {
        const t = tileAt(px, py);
        dropWs = t?.wsId ?? 0;
        dropSpecial = t?.special ?? "";
    }

    function iconSource(appId: string): string {
        const entry = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(entry?.icon || appId || "application-x-executable", "application-x-executable");
    }

    function specialShort(name: string): string {
        return name.replace(/^special:/, "");
    }

    readonly property int activeWs: CompositorService.monitorFor(scr)?.activeWorkspaceId ?? -1
    readonly property var visibleWs: CompositorService.monitors.map(m => m.activeWorkspaceId)
    onActiveWsChanged: if (controller && activeWs >= 1 && activeWs <= 10)
        controller.selected = activeWs - 1

    focus: isOpen
    onIsOpenChanged: if (isOpen)
        Qt.callLater(() => root.forceActiveFocus())
    Component.onCompleted: {
        syncModel();
        if (isOpen)
            Qt.callLater(() => root.forceActiveFocus());
    }

    Keys.onPressed: event => {
        const c = root.controller;
        const k = event.key;
        if (!c)
            return;
        if (k === Qt.Key_Escape) {
            c.close();
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            const id = c.selected + 1;
            c.closeThen(() => CompositorService.focusWorkspace(id, ""));
        } else if (k === Qt.Key_Left || k === Qt.Key_H) {
            c.selected = Math.max(0, c.selected - 1);
        } else if (k === Qt.Key_Right || k === Qt.Key_L) {
            c.selected = Math.min(9, c.selected + 1);
        } else if (k === Qt.Key_Up || k === Qt.Key_K) {
            c.selected = Math.max(0, c.selected - root.columns);
        } else if (k === Qt.Key_Down || k === Qt.Key_J) {
            c.selected = Math.min(9, c.selected + root.columns);
        } else if (k >= Qt.Key_0 && k <= Qt.Key_9) {
            const id = k === Qt.Key_0 ? 10 : k - Qt.Key_0;
            c.closeThen(() => CompositorService.focusWorkspace(id, ""));
        }
    }

    Rectangle {
        id: panel

        property bool shown: false
        Component.onCompleted: Qt.callLater(() => panel.shown = true)
        readonly property bool vis: root.isOpen && shown

        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        width: root.contentW + 2 * root.pad
        height: root.contentH + 2 * root.pad
        radius: 24
        color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)

        opacity: vis ? 1 : 0
        scale: vis ? 1 : 0.94
        Behavior on opacity {
            NumberAnimation {
                duration: panel.vis ? 160 : 120
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: panel.vis ? 260 : 160
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: content
            x: root.pad
            y: root.pad
            width: root.contentW
            height: root.contentH

            WheelHandler {
                onWheel: event => {
                    if (root.controller)
                        root.controller.selected = Math.max(0, Math.min(9, root.controller.selected + (event.angleDelta.y > 0 ? -1 : 1)));
                }
            }

            Repeater {
                model: 10
                delegate: Rectangle {
                    id: tile
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool hot: root.dropWs === wsId
                    readonly property bool isSelected: index === (root.controller?.selected ?? -1)
                    readonly property bool isActive: root.visibleWs.includes(wsId)
                    readonly property var frame: root.frames["w" + wsId] ?? null

                    x: root.tileX(wsId, "")
                    y: root.tileY(wsId, "")
                    width: root.tileW
                    height: root.tileH
                    radius: root.tileRadius
                    color: Qt.alpha(Qt.tint(Colors.md3.surface_container_high, hot ? Qt.alpha(Colors.md3.primary, 0.24) : isSelected ? Qt.alpha(Colors.md3.primary, 0.16) : Qt.alpha(Colors.md3.on_surface, tileMa.containsMouse ? 0.08 : 0)), Config.blurOpacity)
                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -root.ringWidth
                        radius: root.tileRadius + root.ringWidth
                        color: "transparent"
                        border.width: tile.hot ? root.ringWidth : (tile.isActive && !tile.isSelected ? 1 : 0)
                        border.color: tile.hot ? Colors.md3.primary : Colors.md3.outline
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 140
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: tile.wsId
                        font.family: Config.fontFamily
                        font.pixelSize: tile.height * 0.4
                        font.bold: true
                        color: Qt.alpha(tile.wsId === root.activeWs ? Colors.md3.primary : Colors.md3.on_surface, tile.wsId === root.activeWs ? 0.4 : 0.18)
                    }

                    OverviewMonitorFrame {
                        frame: tile.frame
                    }

                    MouseArea {
                        id: tileMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const id = tile.wsId;
                            root.controller?.closeThen(() => CompositorService.focusWorkspace(id, ""));
                        }
                    }
                }
            }

            Rectangle {
                readonly property int sel: root.controller?.selected ?? -1
                visible: sel >= 0
                x: root.tileX(sel + 1, "") - root.ringWidth
                y: root.tileY(sel + 1, "") - root.ringWidth
                width: root.tileW + 2 * root.ringWidth
                height: root.tileH + 2 * root.ringWidth
                radius: root.tileRadius + root.ringWidth
                color: "transparent"
                border.width: root.ringWidth
                border.color: Colors.md3.primary
                Behavior on x {
                    enabled: root.isOpen
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    enabled: root.isOpen
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                visible: root.specialNames.length > 0
                y: root.gridH + 10
                text: Localization.t("overview.special")
                font.family: Config.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: Colors.md3.on_surface_variant
            }

            Repeater {
                model: root.specialNames
                delegate: Rectangle {
                    id: stile
                    required property string modelData
                    readonly property bool hot: root.dropSpecial === modelData

                    x: root.tileX(0, modelData)
                    y: root.tileY(0, modelData)
                    width: root.tileW
                    height: root.tileH
                    radius: root.tileRadius
                    color: Qt.alpha(Qt.tint(Colors.md3.surface_container_high, hot ? Qt.alpha(Colors.md3.primary, 0.24) : Qt.alpha(Colors.md3.on_surface, stileMa.containsMouse ? 0.08 : 0)), Config.blurOpacity)
                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -root.ringWidth
                        radius: root.tileRadius + root.ringWidth
                        color: "transparent"
                        border.width: stile.hot ? root.ringWidth : 0
                        border.color: Colors.md3.primary
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 140
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.specialShort(stile.modelData)
                        font.family: Config.fontFamily
                        font.pixelSize: 20
                        font.bold: true
                        color: Qt.alpha(Colors.md3.on_surface, 0.18)
                    }

                    OverviewMonitorFrame {
                        frame: root.frames[stile.modelData] ?? null
                    }

                    MouseArea {
                        id: stileMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const name = root.specialShort(stile.modelData);
                            root.controller?.closeThen(() => CompositorService.toggleSpecial(name));
                        }
                    }
                }
            }

            Item {
                id: winLayer
                anchors.fill: parent

                Repeater {
                    model: winModel

                    delegate: Item {
                        id: cell
                        required property string address
                        readonly property var d: root.byAddr[address] ?? null
                        readonly property var mon: d?.monitor ?? null

                        property int moveWs: 0
                        property string moveSpecial: ""
                        readonly property bool moved: moveWs > 0 || moveSpecial !== ""
                        readonly property var ownFrame: d ? (root.frames[root.frameKey(d)] ?? null) : null
                        readonly property var frame: moved ? (root.frames[moveWs > 0 ? "w" + moveWs : moveSpecial] ?? ownFrame) : ownFrame
                        readonly property real sx: frame?.sx ?? 0
                        readonly property real sy: frame?.sy ?? 0
                        readonly property int tileWs: moved ? moveWs : ((d?.workspaceId ?? 0) > 0 ? d.workspaceId : 0)
                        readonly property string tileSpecial: moved ? moveSpecial : ((d?.workspaceId ?? 0) > 0 ? "" : (d?.workspaceName ?? ""))

                        onDChanged: {
                            moveWs = 0;
                            moveSpecial = "";
                        }

                        readonly property real relX: Math.round(((d?.x ?? 0) - (mon?.x ?? 0)) * sx)
                        readonly property real relY: Math.round(((d?.y ?? 0) - (mon?.y ?? 0)) * sy)
                        readonly property real baseX: root.tileX(tileWs, tileSpecial) + (frame?.ox ?? 0) + relX
                        readonly property real baseY: root.tileY(tileWs, tileSpecial) + (frame?.oy ?? 0) + relY

                        property bool ready: false
                        Timer {
                            running: true
                            interval: 60
                            onTriggered: cell.ready = true
                        }
                        property bool dragging: false

                        visible: d !== null && mon !== null && frame !== null && !root.covered(d, ownFrame?.fullscreen ?? false)

                        readonly property bool offscreen: !!d && !!mon && (d.x + d.w <= mon.x || d.x >= mon.x + mon.w || d.y + d.h <= mon.y || d.y >= mon.y + mon.h)
                        opacity: offscreen ? 0.55 : 1
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 160
                            }
                        }
                        x: baseX
                        y: baseY
                        width: Math.max(8, Math.round(((d?.x ?? 0) - (mon?.x ?? 0) + (d?.w ?? 0)) * sx) - relX)
                        height: Math.max(8, Math.round(((d?.y ?? 0) - (mon?.y ?? 0) + (d?.h ?? 0)) * sy) - relY)
                        z: (d?.fullscreen ? 2 : d?.floating ? 1 : 0) + (dragging || xAnim.running ? 99999 : 0)

                        readonly property bool animate: ready && !dragging
                        Behavior on x {
                            enabled: cell.animate
                            NumberAnimation {
                                id: xAnim
                                duration: 320
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on y {
                            enabled: cell.animate
                            NumberAnimation {
                                duration: 320
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on width {
                            enabled: cell.animate
                            NumberAnimation {
                                duration: 320
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on height {
                            enabled: cell.animate
                            NumberAnimation {
                                duration: 320
                                easing.type: Easing.OutCubic
                            }
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            readonly property real cap: Math.min(cell.width, cell.height) * 0.25
                            readonly property real inner: Math.min(cell.frame?.winRadius ?? 0, cap)
                            readonly property real outer: Math.min(cell.frame?.outerRadius ?? 0, cap)
                            readonly property bool atL: !cell.d?.floating && Math.abs((cell.frame?.ox ?? 0) + cell.relX - (cell.frame?.bx0 ?? -9)) < 1
                            readonly property bool atT: !cell.d?.floating && Math.abs((cell.frame?.oy ?? 0) + cell.relY - (cell.frame?.by0 ?? -9)) < 1
                            readonly property bool atR: !cell.d?.floating && Math.abs((cell.frame?.ox ?? 0) + cell.relX + cell.width - (cell.frame?.bx1 ?? -9)) < 1
                            readonly property bool atB: !cell.d?.floating && Math.abs((cell.frame?.oy ?? 0) + cell.relY + cell.height - (cell.frame?.by1 ?? -9)) < 1
                            topLeftRadius: atL && atT ? outer : inner
                            topRightRadius: atR && atT ? outer : inner
                            bottomLeftRadius: atL && atB ? outer : inner
                            bottomRightRadius: atR && atB ? outer : inner
                            color: Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
                            border.width: 1
                            border.color: cell.dragging || ma.containsMouse ? Colors.md3.primary : Qt.alpha(Colors.md3.outline_variant, 0.7)
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            ScreencopyView {
                                id: capture
                                readonly property real aspect: sourceSize.height > 0 ? sourceSize.width / sourceSize.height : parent.width / Math.max(1, parent.height)
                                anchors.centerIn: parent
                                width: Math.max(parent.width, parent.height * aspect)
                                height: Math.max(parent.height, parent.width / aspect)
                                live: PowerProfileService.liveCaptureAllowed
                                constraintSize: Qt.size(root.tileW * 2, root.tileH * 2)
                                captureSource: cell.d?.toplevel ?? null
                            }

                            IconImage {
                                visible: Math.min(cell.width, cell.height) >= 24
                                anchors.centerIn: parent
                                implicitSize: Math.min(48, Math.min(cell.width, cell.height) * 0.5)
                                source: root.iconSource(cell.d?.appId ?? "")
                            }
                        }

                        Tooltip {
                            flat: true
                            suppressed: cell.dragging || (root.controller?.dragActive ?? false)
                            text: cell.d?.title ?? ""
                        }

                        MouseArea {
                            id: ma
                            property bool wasDragged: false
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            drag.target: cell
                            drag.threshold: 8

                            function settle(): void {
                                cell.dragging = false;
                                wasDragged = false;
                                if (root.controller)
                                    root.controller.dragActive = false;
                                root.hover(-1, -1);
                                cell.x = Qt.binding(() => cell.baseX);
                                cell.y = Qt.binding(() => cell.baseY);
                            }

                            function pointer(mouse: var): point {
                                return ma.mapToItem(winLayer, mouse.x, mouse.y);
                            }

                            onPressed: {
                                cell.dragging = true;
                                if (root.controller)
                                    root.controller.dragActive = true;
                            }
                            onCanceled: settle()
                            onClicked: mouse => {
                                const addr = cell.address;
                                if (mouse.button === Qt.MiddleButton) {
                                    root.controller?.closeWindow(addr);
                                } else {
                                    root.controller?.closeThen(() => CompositorService.focusWindow(addr));
                                }
                            }
                            drag.onActiveChanged: if (ma.drag.active)
                                wasDragged = true
                            onPositionChanged: mouse => {
                                if (wasDragged) {
                                    const p = pointer(mouse);
                                    root.hover(p.x, p.y);
                                }
                            }
                            onReleased: mouse => {
                                const dragged = wasDragged;
                                const p = pointer(mouse);
                                const hit = dragged ? root.tileAt(p.x, p.y) : null;
                                settle();
                                if (!hit || (hit.wsId > 0 ? hit.wsId === cell.tileWs : hit.special === cell.tileSpecial))
                                    return;
                                cell.moveWs = hit.wsId;
                                cell.moveSpecial = hit.special;
                                root.controller?.moveWindow(cell.address, hit.wsId, root.specialShort(hit.special));
                            }
                        }
                    }
                }
            }
        }
    }
}
