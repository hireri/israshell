import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Qt.labs.platform as Labs
import Quickshell
import qs.style
import qs.services
import qs.icons

Item {
    id: root
    property string entryId: ""
    property var hostScreen: null

    anchors.fill: parent

    readonly property var entry: DesktopWidgetService.entryFor(root.entryId)
    readonly property var _data: root.entry?.data ?? ({})

    property string _quantizerSource: ""

    ColorQuantizer {
        id: quantizer
        source: root._quantizerSource
        depth: 2
        rescaleSize: 8
    }

    readonly property color _dominantColor: {
        const cols = quantizer.colors;
        if (!cols || cols.length === 0)
            return Colors.md3.primary;
        let best = cols[0];
        for (const c of cols)
            if (c.hslSaturation > best.hslSaturation)
                best = c;
        return best;
    }

    readonly property var _scheme: {
        const cols = quantizer.colors;
        if (!cols || cols.length === 0 || !root._data.imagePath) {
            return {
                surfaceContainerHigh: Colors.md3.surface_container_high
            };
        }
        return ColorUtils.m3CardScheme(root._dominantColor, Config.darkMode);
    }

    property real localX: 100
    property real localY: 100
    property real localSize: 200
    property real _sourceSizeAnchor: 200

    readonly property real minSize: 48

    readonly property string imageKey: root._data.imagePath ? (root._data.imagePath + "|" + Math.round(root._sourceSizeAnchor)) : ""

    property int _photoFront: 0

    function _photoFrontItem() {
        return root._photoFront === 0 ? photoA : photoB;
    }
    function _photoBackItem() {
        return root._photoFront === 0 ? photoB : photoA;
    }

    function _showPhoto(key) {
        if (key === "") {
            photoFadeA.stop();
            photoFadeB.stop();
            photoFadeA.to = 0;
            photoFadeB.to = 0;
            photoFadeA.start();
            photoFadeB.start();
            return;
        }
        const front = root._photoFrontItem();
        const back = root._photoBackItem();
        if (front._key === key && front.status === Image.Ready)
            return;
        if (back._key === key && back.status === Image.Ready) {
            root._crossfadePhoto(1 - root._photoFront);
            return;
        }
        back._key = key;
        back.source = root._data.imagePath ? ("file://" + root._data.imagePath) : "";
        back.sourceSize = Qt.size(root._sourceSizeAnchor, root._sourceSizeAnchor);
    }

    function _crossfadePhoto(slot) {
        if (slot === root._photoFront)
            return;
        root._photoFront = slot;
        const frontItem = slot === 0 ? photoA : photoB;
        root._quantizerSource = frontItem.source.toString();
        const frontAnim = slot === 0 ? photoFadeA : photoFadeB;
        const backAnim = slot === 0 ? photoFadeB : photoFadeA;
        frontAnim.stop();
        frontAnim.to = 1;
        frontAnim.start();
        backAnim.stop();
        backAnim.to = 0;
        backAnim.start();
    }

    readonly property var _shapeCycle: ["circle", "square", "slanted", "arch", "fan", "arrow", "semiCircle", "oval", "pill", "triangle", "diamond", "clamShell", "pentagon", "gem", "sunny", "verySunny", "cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "ghostish", "clover4", "clover8", "burst", "softBurst", "boom", "softBoom", "flower", "puffy", "puffyDiamond", "pixelCircle", "pixelTriangle", "bun", "heart"]

    function _cycleShape() {
        const cur = root._data.shape || "circle";
        const idx = root._shapeCycle.indexOf(cur);
        const next = root._shapeCycle[(idx + 1) % root._shapeCycle.length];
        DesktopWidgetService.updateEntryData(root.entryId, { shape: next });
    }

    readonly property var referenceScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real referenceWidth: root.referenceScreen?.width ?? root.hostScreen?.width ?? 1920
    readonly property real referenceHeight: root.referenceScreen?.height ?? root.hostScreen?.height ?? 1080

    function _screenTransform(curW, curH) {
        const scale = Math.max(curW / root.referenceWidth, curH / root.referenceHeight);
        return {
            scale: scale,
            cropX: (root.referenceWidth * scale - curW) / 2,
            cropY: (root.referenceHeight * scale - curH) / 2
        };
    }

    function _applyScaledDefault() {
        const curW = root.hostScreen?.width ?? root.referenceWidth;
        const curH = root.hostScreen?.height ?? root.referenceHeight;
        const t = root._screenTransform(curW, curH);
        root.localX = (root.entry?.x ?? 100) * t.scale - t.cropX;
        root.localY = (root.entry?.y ?? 100) * t.scale - t.cropY;
        root.localSize = (root.entry?.size ?? 200) * t.scale;
    }

    function loadGeometry() {
        if (!root.entry)
            return;
        const mirror = root.entry.mirror ?? true;
        if (mirror) {
            root._applyScaledDefault();
        } else if (root.hostScreen && root.hostScreen.name) {
            const pos = root.entry.positions?.[root.hostScreen.name];
            if (pos) {
                root.localX = pos.x ?? 100;
                root.localY = pos.y ?? 100;
                root.localSize = pos.size ?? 200;
            } else {
                root._applyScaledDefault();
            }
        }
        root._sourceSizeAnchor = root.localSize;
    }

    property bool _mirrorInitialized: false
    property bool _prevMirror: true

    function _seedMirrorBaseFromReferenceMonitor() {
        if (root.hostScreen !== root.referenceScreen)
            return;
        const pos = root.entry?.positions?.[root.hostScreen?.name];
        if (!pos)
            return;
        DesktopWidgetService.updateEntry(root.entryId, { x: pos.x, y: pos.y, size: pos.size });
    }

    function _captureCurrentAsIndividualPosition() {
        if (!root.hostScreen || !root.hostScreen.name)
            return;
        DesktopWidgetService.updateEntryPosition(root.entryId, root.hostScreen.name, {
            x: Math.round(root.localX),
            y: Math.round(root.localY),
            size: Math.round(root.localSize)
        });
    }

    function _maybeInit() {
        if (root._mirrorInitialized)
            return;
        if (!root.entry || !root.hostScreen)
            return;
        root._prevMirror = root.entry.mirror ?? true;
        root._mirrorInitialized = true;
        root.loadGeometry();
    }

    onEntryChanged: {
        root._maybeInit();
        if (!root._mirrorInitialized || !root.entry)
            return;
        const mirror = root.entry.mirror ?? true;
        const enabling = !root._prevMirror && mirror;
        const disabling = root._prevMirror && !mirror;
        root._prevMirror = mirror;
        if (enabling) {
            root._seedMirrorBaseFromReferenceMonitor();
        } else if (disabling) {
            root._captureCurrentAsIndividualPosition();
        }
        root.loadGeometry();
    }

    onHostScreenChanged: root._maybeInit()

    Item {
        id: body
        x: root.localX
        y: root.localY
        width: root.localSize
        height: root.localSize

        MaterialShape {
            id: frameShape
            anchors.fill: parent
            name: root._data.shape || "circle"
            shapeSize: parent.width
            color: root._scheme.surfaceContainerHigh

            Behavior on color {
                ColorAnimation { duration: 400 }
            }
        }

        Image {
            id: photoA
            property string _key: ""
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            visible: false
        }
        Image {
            id: photoB
            property string _key: ""
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            visible: false
        }

        MultiEffect {
            id: photoAEffect
            anchors.fill: parent
            source: photoA
            maskEnabled: true
            maskSource: frameShape
            opacity: 0
        }
        MultiEffect {
            id: photoBEffect
            anchors.fill: parent
            source: photoB
            maskEnabled: true
            maskSource: frameShape
            opacity: 0
        }

        NumberAnimation { id: photoFadeA; target: photoAEffect; property: "opacity"; duration: 380; easing.type: Easing.OutCubic }
        NumberAnimation { id: photoFadeB; target: photoBEffect; property: "opacity"; duration: 380; easing.type: Easing.OutCubic }

        Connections {
            target: photoA
            function onStatusChanged() {
                if (photoA.status === Image.Ready)
                    root._crossfadePhoto(0);
            }
        }
        Connections {
            target: photoB
            function onStatusChanged() {
                if (photoB.status === Image.Ready)
                    root._crossfadePhoto(1);
            }
        }

        Connections {
            target: root
            function onImageKeyChanged() {
                root._showPhoto(root.imageKey);
            }
        }

        Component.onCompleted: root._showPhoto(root.imageKey)

        MaterialIcon {
            anchors.centerIn: parent
            name: "image"
            iconSize: parent.width * 0.3
            color: Colors.md3.on_surface_variant
            visible: photoAEffect.opacity < 0.5 && photoBEffect.opacity < 0.5
        }

        MouseArea {
            anchors.fill: parent
            enabled: !EditModeService.active
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root._cycleShape();
                else
                    filePicker.open();
            }
        }
    }

    Labs.FileDialog {
        id: filePicker
        title: "Choose photo"
        fileMode: Labs.FileDialog.OpenFile
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.gif *.bmp)", "All files (*)"]
        onAccepted: {
            const path = decodeURIComponent(filePicker.file.toString().replace(/^file:\/\//, ""));
            DesktopWidgetService.updateEntryData(root.entryId, { imagePath: path });
        }
    }

    EditableFrame {
        id: editFrame
        trackX: body.x
        trackY: body.y
        trackWidth: body.width
        trackHeight: body.height
        label: "Photo"
        interactive: EditModeService.active
        showChrome: EditModeService.active
        movable: true
        resizable: true
        uniformScale: true
        cornerRadius: Math.max(4, root.localSize / 6)

        property real _startX: 0
        property real _startY: 0
        property real _startSize: 0

        quickActions: Component {
            Row {
                spacing: 2

                Rectangle {
                    readonly property bool _mirror: root.entry?.mirror ?? true
                    width: 16
                    height: 16
                    radius: 8
                    color: mirrorMouse.containsMouse ? Qt.alpha(Colors.md3.on_primary_container, 0.15) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "monitor"
                        filled: !parent._mirror
                        iconSize: 12
                        color: Colors.md3.on_primary_container
                    }

                    MouseArea {
                        id: mirrorMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DesktopWidgetService.updateEntry(root.entryId, { mirror: !(root.entry?.mirror ?? true) })
                    }
                }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: removeMouse.containsMouse ? Qt.alpha(Colors.md3.error, 0.15) : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "delete"
                        iconSize: 12
                        color: Colors.md3.error
                    }

                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DesktopWidgetService.removeEntry(root.entryId)
                    }
                }
            }
        }

        onMoveStarted: {
            _startX = root.localX;
            _startY = root.localY;
        }
        onMoveDelta: (dx, dy) => {
            root.localX = _startX + dx;
            root.localY = _startY + dy;
        }
        onMoveCommitted: root.commitGeometry()

        onResizeStarted: {
            _startSize = root.localSize;
        }
        onResizeDelta: (dw, dh) => {
            root.localSize = Math.max(root.minSize, _startSize + (dw + dh) / 2);
        }
        onResizeCommitted: {
            root.commitGeometry();
            root._sourceSizeAnchor = root.localSize;
        }
    }

    function commitGeometry() {
        const mirror = root.entry?.mirror ?? true;
        if (mirror) {
            const curW = root.hostScreen?.width ?? root.referenceWidth;
            const curH = root.hostScreen?.height ?? root.referenceHeight;
            const t = root._screenTransform(curW, curH);
            DesktopWidgetService.updateEntry(root.entryId, {
                mirror: true,
                x: Math.round((root.localX + t.cropX) / t.scale),
                y: Math.round((root.localY + t.cropY) / t.scale),
                size: Math.round(root.localSize / t.scale)
            });
        } else {
            root._captureCurrentAsIndividualPosition();
        }
    }
}
