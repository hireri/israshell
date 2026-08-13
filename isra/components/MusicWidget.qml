import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
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
    readonly property real _buttonScale: root._data.buttonScale ?? 0.28

    readonly property var player: MediaPlayerState.displayPlayer
    readonly property bool isPlaying: root.player?.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: root.player?.trackArtUrl ?? ""

    property real _rotationTicks: 0
    readonly property real _bodyRotation: root._rotationTicks * 40

    property int _artFront: 0

    function _artFrontItem() {
        return root._artFront === 0 ? artA : artB;
    }
    function _artBackItem() {
        return root._artFront === 0 ? artB : artA;
    }

    function _showArt(url) {
        if (url === "") {
            artFadeA.stop();
            artFadeB.stop();
            artFadeA.to = 0;
            artFadeB.to = 0;
            root._rotationTicks += 1;
            artFadeA.start();
            artFadeB.start();
            return;
        }
        const front = root._artFrontItem();
        const back = root._artBackItem();
        if (front._key === url && front.status === Image.Ready) {
            root._rotationTicks += 1;
            return;
        }
        if (back._key === url && back.status === Image.Ready) {
            root._crossfadeArt(1 - root._artFront);
            return;
        }
        back._key = url;
        back.source = url;
    }

    function _crossfadeArt(slot) {
        if (slot === root._artFront)
            return;
        root._rotationTicks += 1;
        root._artFront = slot;
        const frontAnim = slot === 0 ? artFadeA : artFadeB;
        const backAnim = slot === 0 ? artFadeB : artFadeA;
        frontAnim.stop();
        frontAnim.to = 1;
        frontAnim.start();
        backAnim.stop();
        backAnim.to = 0;
        backAnim.start();
    }

    property real localX: 100
    property real localY: 100
    property real localSize: 180

    readonly property real minSize: 48

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
        root.localSize = (root.entry?.size ?? 180) * t.scale;
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
                root.localSize = pos.size ?? 180;
            } else {
                root._applyScaledDefault();
            }
        }
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

        Item {
            id: bodyShapeMaskRoot
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true

            MaterialShape {
                id: bodyShape
                anchors.fill: parent
                name: root.isPlaying ? "cookie9" : "circle"
                shapeSize: parent.width
                color: Colors.md3.primary_container
                rotationDegrees: root._bodyRotation
            }
        }

        Image {
            id: artA
            property string _key: ""
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width, height)
            asynchronous: true
            visible: false
        }
        Image {
            id: artB
            property string _key: ""
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width, height)
            asynchronous: true
            visible: false
        }

        MultiEffect {
            id: artAEffect
            anchors.fill: parent
            source: artA
            maskEnabled: true
            maskSource: bodyShapeMaskRoot
            opacity: 0
        }
        MultiEffect {
            id: artBEffect
            anchors.fill: parent
            source: artB
            maskEnabled: true
            maskSource: bodyShapeMaskRoot
            opacity: 0
        }

        NumberAnimation { id: artFadeA; target: artAEffect; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { id: artFadeB; target: artBEffect; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }

        Connections {
            target: artA
            function onStatusChanged() {
                if (artA.status === Image.Ready)
                    root._crossfadeArt(0);
            }
        }
        Connections {
            target: artB
            function onStatusChanged() {
                if (artB.status === Image.Ready)
                    root._crossfadeArt(1);
            }
        }

        Timer {
            id: clearArtDelay
            interval: 250
            onTriggered: root._showArt("")
        }

        Connections {
            target: root
            function onArtUrlChanged() {
                if (root.artUrl === "") {
                    clearArtDelay.restart();
                } else {
                    clearArtDelay.stop();
                    root._showArt(root.artUrl);
                }
            }
        }

        Component.onCompleted: root._showArt(root.artUrl)

        MaterialIcon {
            anchors.centerIn: parent
            name: "music-note"
            iconSize: parent.width * 0.3
            color: Colors.md3.on_primary_container
            visible: artAEffect.opacity < 0.5 && artBEffect.opacity < 0.5
        }

        Item {
            id: playBtn
            width: parent.width * root._buttonScale
            height: width
            anchors {
                left: parent.left
                bottom: parent.bottom
            }

            MaterialShape {
                anchors.fill: parent
                name: "square"
                shapeSize: parent.width
                color: Colors.md3.primary
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: "play-pause"
                filled: root.isPlaying
                iconSize: parent.width * 0.45
                color: Colors.md3.on_primary
            }

            MouseArea {
                anchors.fill: parent
                enabled: !EditModeService.active
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player?.togglePlaying()
            }
        }

        Item {
            id: skipBtn
            width: parent.width * root._buttonScale
            height: width
            anchors {
                right: parent.right
                top: parent.top
            }
            readonly property bool canSkip: root.player?.canGoNext ?? false
            opacity: canSkip ? 1.0 : 0.5

            MaterialShape {
                anchors.fill: parent
                name: "clover4"
                shapeSize: parent.width
                color: Colors.md3.secondary_container
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: "next-prev"
                filled: true
                iconSize: parent.width * 0.4
                color: Colors.md3.on_secondary_container
            }

            MouseArea {
                anchors.fill: parent
                enabled: !EditModeService.active
                cursorShape: skipBtn.canSkip ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (skipBtn.canSkip) root.player.next()
            }
        }
    }

    EditableFrame {
        id: editFrame
        trackX: body.x
        trackY: body.y
        trackWidth: body.width
        trackHeight: body.height
        label: "Music"
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
        onResizeCommitted: root.commitGeometry()
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
