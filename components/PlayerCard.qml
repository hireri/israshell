import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.style
import qs.services

Item {
    id: root

    property var player: null
    property bool pinned: false
    property bool showPin: true
    property bool suppressAnimations: false
    property real _dragPos: 0

    readonly property bool darkMode: typeof Config.darkMode !== "undefined" ? Config.darkMode : true

    signal pinToggled

    implicitWidth: 380
    implicitHeight: card.implicitHeight

    readonly property string artUrl: player?.trackArtUrl ?? ""
    property string localArtPath: ""
    property bool _silentNextArtLoad: false

    onPlayerChanged: {
        _silentNextArtLoad = true;
    }

    onArtUrlChanged: {
        if (artUrl === "") {
            localArtPath = "";
            return;
        }
        if (artUrl.startsWith("file://")) {
            localArtPath = artUrl;
            return;
        }
        const file = "/tmp/qs_art_" + Qt.md5(artUrl);
        artFetchProc.launchedUrl = artUrl;
        artFetchProc.launchedFile = file;
        artFetchProc.running = false;
        artFetchProc.command = ["bash", "-c", `f='${file}'; t="$f.tmp"; [ -f "$f" ] || { curl -4 -sSL '${artUrl}' -o "$t" && mv "$t" "$f"; }`];
        artFetchProc.running = true;
    }

    Process {
        id: artFetchProc
        property string launchedUrl: ""
        property string launchedFile: ""
        running: false
        onExited: code => {
            if (code === 0 && launchedUrl === root.artUrl && launchedFile !== "")
                root.localArtPath = "file://" + launchedFile;
        }
    }

    ColorQuantizer {
        id: quantizer
        source: root.localArtPath
        depth: 2
        rescaleSize: 8
    }

    readonly property color dominantColor: {
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
        if (!cols || cols.length === 0 || localArtPath === "") {
            return {
                surface: Colors.md3.surface_container_high,
                surfaceContainer: Colors.md3.surface_container,
                surfaceContainerHigh: Colors.md3.surface_container_highest,
                primary: Colors.md3.primary,
                onPrimary: Colors.md3.on_primary,
                primaryContainer: Colors.md3.primary_container,
                onPrimaryContainer: Colors.md3.on_primary_container,
                onSurface: Colors.md3.on_surface,
                onSurfaceVariant: Colors.md3.on_surface_variant,
                outline: Colors.md3.outline_variant
            };
        }
        return ColorUtils.m3CardScheme(dominantColor, darkMode);
    }

    readonly property color colSurface: _scheme.surface
    readonly property color colSurfaceContainer: _scheme.surfaceContainer
    readonly property color colSurfaceContainerHigh: _scheme.surfaceContainerHigh
    readonly property color colPrimary: _scheme.primary
    readonly property color colOnPrimary: _scheme.onPrimary
    readonly property color colPrimaryContainer: _scheme.primaryContainer
    readonly property color colOnPrimaryContainer: _scheme.onPrimaryContainer
    readonly property color colOnSurface: _scheme.onSurface
    readonly property color colOnSurfaceVariant: _scheme.onSurfaceVariant
    readonly property color colOutline: _scheme.outline

    property bool _snapProgress: false
    property bool _isDragging: false
    property real _prevPos: 0
    property string _prevTitle: ""
    property real currentPosition: 0

    Timer {
        id: snapResetTimer
        interval: 80
        onTriggered: root._snapProgress = false
    }

    function syncPosition() {
        if (!root.player) {
            root.currentPosition = 0;
            return;
        }
        const title = root.player.trackTitle ?? "";
        const pos = root.player.position ?? 0;
        if (title !== root._prevTitle || pos < root._prevPos - 2.0) {
            root._snapProgress = true;
            snapResetTimer.restart();
        }
        root._prevTitle = title;
        root._prevPos = pos;
        root.currentPosition = pos;
    }

    Timer {
        id: positionPoller
        running: root.visible && root.player !== null
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.syncPosition()
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onPlaybackStateChanged() {
            root.syncPosition();
        }
        function onTrackTitleChanged() {
            root.syncPosition();
        }
        function onPositionChanged() {
            root.syncPosition();
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 24
        color: root.colSurface
        implicitHeight: col.implicitHeight + 28
        clip: true
        border.width: 1
        border.color: root.colOutline

        Behavior on color {
            enabled: !root.suppressAnimations
            ColorAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Behavior on border.color {
            enabled: !root.suppressAnimations
            ColorAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        ClippingRectangle {
            id: bgClip
            anchors.fill: parent
            radius: card.radius
            color: "transparent"

            BgImage {
                id: bgA
            }
            BgImage {
                id: bgB
            }

            NumberAnimation {
                id: bgAnim_A
                target: bgA
                property: "opacity"
                duration: 380
                easing.type: Easing.OutCubic
                onStopped: {
                    if (bgA.opacity < 0.01)
                        bgA.source = "";
                }
            }
            NumberAnimation {
                id: bgAnim_B
                target: bgB
                property: "opacity"
                duration: 380
                easing.type: Easing.OutCubic
                onStopped: {
                    if (bgB.opacity < 0.01)
                        bgB.source = "";
                }
            }

            property bool _aActive: false

            function showBg(path) {
                bgAnim_A.stop();
                bgAnim_B.stop();
                const a = _aActive;
                const curr = a ? bgA : bgB;
                const next = a ? bgB : bgA;
                const animCurr = a ? bgAnim_A : bgAnim_B;
                const animNext = a ? bgAnim_B : bgAnim_A;

                if (path === "") {
                    animCurr.to = 0;
                    animCurr.start();
                    return;
                }

                if (curr.opacity > 0.01) {
                    animCurr.to = 0;
                    animCurr.start();
                }
                next.source = path;
                _aActive = !a;
            }

            Connections {
                target: root
                function onLocalArtPathChanged() {
                    bgClip.showBg(root.localArtPath);
                }
            }

            Connections {
                target: bgA
                function onStatusChanged() {
                    if (bgA.status === Image.Ready) {
                        bgAnim_A.to = 0.22;
                        bgAnim_A.start();
                    }
                }
            }
            Connections {
                target: bgB
                function onStatusChanged() {
                    if (bgB.status === Image.Ready) {
                        bgAnim_B.to = 0.22;
                        bgAnim_B.start();
                    }
                }
            }
        }

        Column {
            id: col
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 14
                topMargin: 14
            }
            spacing: 10

            Row {
                width: parent.width
                spacing: 14

                Item {
                    id: coverRoot
                    width: 80
                    height: 80
                    property real flipAngle: 0
                    property string shownPath: ""

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 12
                        color: root.colSurfaceContainerHigh
                        antialiasing: true
                        smooth: true
                        layer.enabled: true
                        layer.smooth: true
                        layer.mipmap: true

                        Behavior on color {
                            enabled: !root.suppressAnimations
                            ColorAnimation {
                                duration: 500
                            }
                        }

                        transform: Rotation {
                            axis {
                                x: 0
                                y: 1
                                z: 0
                            }
                            angle: coverRoot.flipAngle
                            origin.x: 40
                            origin.y: 40
                            distanceToPlane: 200
                        }

                        Image {
                            id: coverImg
                            anchors.fill: parent
                            source: coverRoot.shownPath
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(256, 256)
                            cache: true
                            asynchronous: true
                            antialiasing: true
                            smooth: true
                            mipmap: true
                        }
                    }

                    Rectangle {
                        id: coverFade
                        anchors.fill: parent
                        radius: 12
                        color: root.colSurface
                        opacity: 0
                        z: 10
                    }

                    Connections {
                        target: root
                        function onLocalArtPathChanged() {
                            if (root.localArtPath === "") {
                                coverRoot.shownPath = "";
                                root._silentNextArtLoad = false;
                                return;
                            }
                            if (root._silentNextArtLoad) {
                                coverRoot.shownPath = root.localArtPath;
                                root._silentNextArtLoad = false;
                                return;
                            }
                            if (coverRoot.shownPath === "") {
                                coverRoot.shownPath = root.localArtPath;
                                return;
                            }
                            if (root.localArtPath === coverRoot.shownPath)
                                return;

                            if (coverFlipAnim.running) {
                                coverFlipAnim.stop();
                                coverRoot.flipAngle = 0;
                                coverFadeAnim.start();
                            } else {
                                coverFlipAnim.start();
                            }
                        }
                    }

                    SequentialAnimation {
                        id: coverFadeAnim
                        NumberAnimation {
                            target: coverFade
                            property: "opacity"
                            to: 1
                            duration: 80
                            easing.type: Easing.OutCubic
                        }
                        ScriptAction {
                            script: {
                                coverRoot.shownPath = root.localArtPath;
                                root._silentNextArtLoad = false;
                            }
                        }
                        NumberAnimation {
                            target: coverFade
                            property: "opacity"
                            to: 0
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    SequentialAnimation {
                        id: coverFlipAnim
                        NumberAnimation {
                            target: coverRoot
                            property: "flipAngle"
                            to: 90
                            duration: 140
                            easing.type: Easing.InCubic
                        }
                        ScriptAction {
                            script: {
                                coverRoot.shownPath = root.localArtPath;
                                root._silentNextArtLoad = false;
                                coverRoot.flipAngle = -90;
                            }
                        }
                        NumberAnimation {
                            target: coverRoot
                            property: "flipAngle"
                            to: 0
                            duration: 780
                            easing.type: Easing.OutElastic
                            easing.period: 0.88
                            easing.amplitude: 1.3
                        }
                        onFinished: {
                            root._silentNextArtLoad = false;
                            if (root.localArtPath !== coverRoot.shownPath && root.localArtPath !== "")
                                coverFadeAnim.start();
                        }
                    }
                }

                Item {
                    width: parent.width - coverRoot.width - parent.spacing
                    height: coverRoot.height

                    Row {
                        width: parent.width
                        anchors.top: parent.top
                        spacing: 8

                        Column {
                            width: parent.width - (root.showPin ? pinBtn.width + parent.spacing : 0)
                            spacing: 3

                            XfadeText {
                                target: root.player?.trackTitle ?? "nothing playing"
                                textColor: root.colOnSurface
                                pixelSize: 14
                                fontWeight: Font.Bold
                            }
                            XfadeText {
                                target: root.player?.trackArtist ?? ""
                                textColor: root.colOnSurfaceVariant
                                pixelSize: 12
                            }
                        }

                        Rectangle {
                            id: pinBtn
                            width: 28
                            height: 28
                            radius: 14
                            visible: root.showPin
                            color: root.pinned ? root.colPrimary : root.colSurfaceContainerHigh
                            Behavior on color {
                                enabled: !root.suppressAnimations
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                font.pixelSize: 13
                                color: root.pinned ? root.colOnPrimary : root.colOnSurfaceVariant
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pinToggled()
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        anchors.bottom: parent.bottom
                        spacing: 4

                        Item {
                            id: progressArea
                            width: parent.width
                            height: 16
                            property bool hover: false

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 4
                                radius: 2
                                color: root.colSurfaceContainer
                                Behavior on color {
                                    enabled: !root.suppressAnimations
                                    ColorAnimation {
                                        duration: 400
                                    }
                                }

                                Rectangle {
                                    id: progFill
                                    width: {
                                        const p = root._isDragging ? root._dragPos : root.currentPosition / Math.max(root.player?.length ?? 1, 1);
                                        return parent.width * Math.min(p, 1);
                                    }
                                    height: parent.height
                                    radius: 2
                                    color: root.colPrimary
                                    Behavior on width {
                                        enabled: !root.suppressAnimations && !root._snapProgress && !root._isDragging
                                        NumberAnimation {
                                            duration: 420
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on color {
                                        enabled: !root.suppressAnimations
                                        ColorAnimation {
                                            duration: 400
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(parent.width - width, progFill.width - width / 2))
                                    color: root.colPrimary
                                    visible: root.player?.canSeek ?? false
                                    opacity: progressArea.hover ? 1 : 0
                                    scale: progressArea.hover ? 1 : 0.5
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutBack
                                            easing.overshoot: 2
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: (root.player?.canSeek ?? false) ? Qt.SizeHorCursor : Qt.ArrowCursor
                                onEntered: progressArea.hover = true
                                onExited: {
                                    if (!pressed)
                                        progressArea.hover = false;
                                }
                                onPressed: mouse => {
                                    if (!(root.player?.canSeek ?? false))
                                        return;
                                    root._isDragging = true;
                                    root._dragPos = mouse.x / width;
                                }
                                onPositionChanged: mouse => {
                                    if (root._isDragging)
                                        root._dragPos = Math.max(0, Math.min(mouse.x / width, 1));
                                }
                                onReleased: mouse => {
                                    if (root._isDragging && (root.player?.canSeek ?? false)) {
                                        root.player.position = root._dragPos * (root.player.length ?? 0);
                                        root.syncPosition();
                                    }
                                    root._isDragging = false;
                                    progressArea.hover = containsMouse;
                                }
                            }
                        }

                        RowLayout {
                            width: parent.width
                            Text {
                                text: {
                                    const s = Math.floor(root.currentPosition);
                                    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
                                }
                                color: root.colOnSurfaceVariant
                                font.pixelSize: 10
                                font.family: Config.fontFamily
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Text {
                                text: {
                                    const r = Math.max(0, Math.floor((root.player?.length ?? 0) - root.currentPosition));
                                    return "−" + Math.floor(r / 60) + ":" + String(r % 60).padStart(2, "0");
                                }
                                color: root.colOnSurfaceVariant
                                font.pixelSize: 10
                                font.family: Config.fontFamily
                            }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                height: 44

                Rectangle {
                    width: 48
                    height: 34
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colPrimaryContainer
                    opacity: (root.player?.canGoPrevious ?? false) ? 1.0 : 0.4
                    Behavior on color {
                        enabled: !root.suppressAnimations
                        ColorAnimation {
                            duration: 400
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        font.family: Config.fontFamily
                        font.pixelSize: 16
                        color: root.colOnPrimaryContainer
                    }
                    scale: prevMa.pressed ? 0.92 : 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                    MouseArea {
                        id: prevMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.player?.previous();
                            root.syncPosition();
                        }
                    }
                }

                Rectangle {
                    id: playBtn
                    readonly property bool isPlaying: root.player?.playbackState === MprisPlaybackState.Playing
                    width: 60
                    height: 40
                    radius: isPlaying ? 12 : height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colPrimary
                    Behavior on height {
                        enabled: !root.suppressAnimations
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on radius {
                        enabled: !root.suppressAnimations
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on color {
                        enabled: !root.suppressAnimations
                        ColorAnimation {
                            duration: 400
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: playBtn.isPlaying ? "󰏤" : "󰐊"
                        font.family: Config.fontFamily
                        font.pixelSize: 16
                        color: root.colOnPrimary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.player?.togglePlaying();
                            root.syncPosition();
                        }
                    }
                }

                Rectangle {
                    width: 48
                    height: 34
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colPrimaryContainer
                    opacity: (root.player?.canGoNext ?? false) ? 1.0 : 0.4
                    Behavior on color {
                        enabled: !root.suppressAnimations
                        ColorAnimation {
                            duration: 400
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.family: Config.fontFamily
                        font.pixelSize: 16
                        color: root.colOnPrimaryContainer
                    }
                    scale: nextMa.pressed ? 0.92 : 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.player?.next();
                            root.syncPosition();
                        }
                    }
                }
            }
        }
    }

    component BgImage: Image {
        anchors {
            fill: parent
            margins: -40
        }
        fillMode: Image.PreserveAspectCrop
        opacity: 0
        cache: true
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.04
        }
    }

    component XfadeText: Item {
        id: xft
        property string target: ""
        property color textColor: root.colOnSurface
        property int pixelSize: 14
        property int fontWeight: Font.Normal
        implicitHeight: xCurr.implicitHeight
        width: parent.width

        onTargetChanged: {
            xPrev.text = xCurr.text;
            xPrev.opacity = 1;
            xPrev.x = 0;
            xCurr.text = target;
            xCurr.opacity = 0;
            xCurr.x = 8;
            xAnim.restart();
        }

        Text {
            id: xPrev
            width: parent.width
            opacity: 0
            x: 0
            color: xft.textColor
            font.pixelSize: xft.pixelSize
            font.weight: xft.fontWeight
            font.family: Config.fontFamily
            elide: Text.ElideRight
        }
        Text {
            id: xCurr
            width: parent.width
            opacity: 1
            x: 0
            color: xft.textColor
            font.pixelSize: xft.pixelSize
            font.weight: xft.fontWeight
            font.family: Config.fontFamily
            elide: Text.ElideRight
            Component.onCompleted: text = xft.target
        }
        ParallelAnimation {
            id: xAnim
            NumberAnimation {
                target: xPrev
                property: "opacity"
                to: 0
                duration: 140
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: xPrev
                property: "x"
                to: -8
                duration: 140
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: xCurr
                property: "opacity"
                to: 1
                duration: 260
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: xCurr
                property: "x"
                to: 0
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
    }
}
