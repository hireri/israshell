import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.style
import qs.services

Item {
    id: root

    property var player: null
    property bool pinned: false
    property bool showPin: true
    property bool suppressAnimations: false

    signal pinToggled

    implicitWidth: 380
    implicitHeight: 160

    readonly property string artUrl: player?.trackArtUrl ?? ""
    property string localArtPath: ""

    onPlayerChanged: {
        localArtPath = "";
        snapToPosition();
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

        localArtPath = "";
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
                quantizerDelay.restart();
        }
    }

    Timer {
        id: quantizerDelay
        interval: 100
        running: false
        onTriggered: {
            if (root.artUrl === artFetchProc.launchedUrl)
                root.localArtPath = "file://" + artFetchProc.launchedFile;
        }
    }

    Timer {
        id: skipSyncTimer
        interval: 380
        onTriggered: root.snapToPosition()
    }

    ColorQuantizer {
        id: quantizer
        source: root.localArtPath
        depth: 2
        rescaleSize: 8
    }

    readonly property bool darkMode: typeof Config.darkMode !== "undefined" ? Config.darkMode : true

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

    readonly property color colSurface: _scheme.surface ?? Colors.md3.surface_container_high
    readonly property color colSurfaceContainer: _scheme.surfaceContainer ?? Colors.md3.surface_container
    readonly property color colSurfaceContainerHigh: _scheme.surfaceContainerHigh ?? Colors.md3.surface_container_highest
    readonly property color colPrimary: _scheme.primary ?? Colors.md3.primary
    readonly property color colOnPrimary: _scheme.onPrimary ?? Colors.md3.on_primary
    readonly property color colPrimaryContainer: _scheme.primaryContainer ?? Colors.md3.primary_container
    readonly property color colOnPrimaryContainer: _scheme.onPrimaryContainer ?? Colors.md3.on_primary_container
    readonly property color colOnSurface: _scheme.onSurface ?? Colors.md3.on_surface
    readonly property color colOnSurfaceVariant: _scheme.onSurfaceVariant ?? Colors.md3.on_surface_variant
    readonly property color colOutline: _scheme.outline ?? Colors.md3.outline_variant

    readonly property color colHoverTint: Qt.rgba(colOnSurface.r, colOnSurface.g, colOnSurface.b, 0.12)
    readonly property color colBarFill: colPrimary
    readonly property color colBarTrack: Qt.rgba(colPrimary.r, colPrimary.g, colPrimary.b, 0.35)
    readonly property color _overlayBase: darkMode ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1)

    property real currentPosition: 0
    property bool _isDragging: false
    property real _dragProgress: 0
    property bool _isResetting: false
    property string _prevTitle: ""
    property real progress: 0
    property real _displayLength: 1

    NumberAnimation {
        id: positionAnim
        target: root
        property: "progress"
        to: 1
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: trackChangeAnim
        target: root
        property: "progress"
        to: 0
        duration: 380
        easing.type: Easing.OutCubic
    }

    function handleTrackChange() {
        _isResetting = false;
        positionAnim.stop();
        trackChangeAnim.restart();
        skipSyncTimer.restart();
    }

    function snapToPosition() {
        _isResetting = false;
        positionAnim.stop();
        trackChangeAnim.stop();
        if (!root.player) {
            progress = 0;
            _displayLength = 1;
            return;
        }
        const pos = root.player.position ?? 0;
        const len = root.player.length ?? 0;
        if (len <= 0) {
            progress = 0;
            return;
        }
        _displayLength = len;
        progress = pos / len;
        if (root.player.playbackState === MprisPlaybackState.Playing) {
            positionAnim.duration = (1 - progress) * len * 1000;
            positionAnim.start();
        }
    }

    function resetToPosition() {
        positionAnim.stop();
        positionResetAnim.stop();
        if (!root.player) {
            snapToPosition();
            return;
        }
        const pos = root.player.position ?? 0;
        const len = root.player.length ?? 0;
        if (root.player.playbackState !== MprisPlaybackState.Playing || len <= 0) {
            currentPosition = pos;
            return;
        }
        _isResetting = true;
        const target = Math.min(pos + positionResetAnim.duration / 1000, len);
        positionResetAnim.to = target;
        positionResetAnim.start();
    }

    function resyncPosition() {
        if (_isResetting || trackChangeAnim.running)
            return;
        if (!root.player) {
            positionAnim.stop();
            progress = 0;
            return;
        }
        const pos = root.player.position ?? 0;
        const len = root.player.length ?? 0;
        const isPlaying = root.player.playbackState === MprisPlaybackState.Playing;
        const drift = Math.abs((progress * len) - pos);

        if (isPlaying && len > 0 && drift < 3.0) {
            if (positionAnim.running && positionAnim.to === 1)
                return;
            positionAnim.duration = (1 - progress) * len * 1000;
            positionAnim.start();
            return;
        }

        positionAnim.stop();
        if (len > 0) {
            _displayLength = len;
            progress = pos / len;
        }
        if (isPlaying && len > 0) {
            positionAnim.duration = (1 - progress) * len * 1000;
            positionAnim.start();
        }
    }

    Timer {
        id: snapResetTimer
        interval: 80
        onTriggered: {
            root._snapReason = 2;
            root.resyncPosition();
            snapResetTimer.restart();
        }
    }

    Timer {
        id: positionPoller
        running: root.visible && root.player !== null
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.resyncPosition()
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onPlaybackStateChanged() {
            if (_isResetting || trackChangeAnim.running)
                return;
            positionAnim.stop();
            if (!root.player)
                return;
            const len = root.player.length ?? 0;
            const isPlaying = root.player.playbackState === MprisPlaybackState.Playing;
            if (isPlaying && len > 0 && progress < 1) {
                positionAnim.duration = (1 - progress) * len * 1000;
                positionAnim.start();
            }
        }
        function onTrackTitleChanged() {
            root.handleTrackChange();
        }
    }

    function formatTime(secs) {
        const s = Math.max(0, Math.floor(secs));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function getIconSource(player) {
        if (!player)
            return "";
        const de = (player.desktopEntry ?? "").trim();
        const identity = (player.identity ?? "").trim().toLowerCase().replace(/\s+/g, "-");
        const id = de !== "" ? de : identity;
        if (id === "")
            return "";
        const entry = DesktopEntries.heuristicLookup(id);
        if (entry && entry.icon)
            return "image://icon/" + entry.icon + "?fallback=application-x-executable";
        return "image://icon/" + id + "?fallback=application-x-executable";
    }

    readonly property real displayProgress: {
        const raw = root._isDragging ? root._dragProgress : root.progress;
        return Math.max(0, Math.min(raw, 1));
    }

    ClippingRectangle {
        id: card
        anchors.fill: parent
        radius: 24
        color: root.colSurface
        Behavior on color {
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
            property bool _aActive: false

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
                onStopped: if (bgA.opacity < 0.01)
                    bgA.source = ""
            }
            NumberAnimation {
                id: bgAnim_B
                target: bgB
                property: "opacity"
                duration: 380
                easing.type: Easing.OutCubic
                onStopped: if (bgB.opacity < 0.01)
                    bgB.source = ""
            }

            function showBg(path) {
                bgAnim_A.stop();
                bgAnim_B.stop();
                const isA = _aActive;
                const curr = isA ? bgA : bgB;
                const animC = isA ? bgAnim_A : bgAnim_B;
                const next = isA ? bgB : bgA;
                if (path === "") {
                    animC.to = 0;
                    animC.start();
                    return;
                }
                if (curr.opacity > 0.01) {
                    animC.to = 0;
                    animC.start();
                }
                next.source = path;
                _aActive = !isA;
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
                        bgAnim_A.to = 1;
                        bgAnim_A.start();
                    }
                }
            }
            Connections {
                target: bgB
                function onStatusChanged() {
                    if (bgB.status === Image.Ready) {
                        bgAnim_B.to = 1;
                        bgAnim_B.start();
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root._overlayBase.r, root._overlayBase.g, root._overlayBase.b, 0.5)
            Behavior on color {
                ColorAnimation {
                    duration: 400
                }
            }
        }
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: parent.height * 0.45
            gradient: Gradient {
                orientation: Gradient.TopToBottom
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(root._overlayBase.r, root._overlayBase.g, root._overlayBase.b, 0.45)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(root._overlayBase.r, root._overlayBase.g, root._overlayBase.b, 0.0)
                }
            }
        }
        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: parent.height * 0.65
            gradient: Gradient {
                orientation: Gradient.TopToBottom
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(root._overlayBase.r, root._overlayBase.g, root._overlayBase.b, 0.0)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(root._overlayBase.r, root._overlayBase.g, root._overlayBase.b, 0.65)
                }
            }
        }

        Item {
            id: topRow
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 13
                leftMargin: 14
                rightMargin: 14
            }
            height: 22

            ClippingRectangle {
                id: smallCover
                width: 22
                height: 22
                radius: 5
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                color: Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.1)

                Image {
                    anchors {
                        fill: parent
                        margins: 2
                    }
                    source: root.getIconSource(root.player)
                    fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(44, 44)
                    cache: true
                    asynchronous: true
                }
                Image {
                    anchors.fill: parent
                    source: root.localArtPath
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(44, 44)
                    cache: true
                    asynchronous: true
                    opacity: status === Image.Ready && root.localArtPath !== "" ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            Text {
                anchors {
                    left: smallCover.right
                    leftMargin: 7
                    right: timestampLabel.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                text: root.player?.trackAlbum ?? ""
                color: root.colOnSurfaceVariant
                font.pixelSize: 11
                font.family: Config.fontFamily
                elide: Text.ElideRight
                Behavior on color {
                    ColorAnimation {
                        duration: 400
                    }
                }
            }

            Text {
                id: timestampLabel
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: root.formatTime(root.displayProgress * root._displayLength) + " / " + root.formatTime(root._displayLength)
                color: root.colOnSurfaceVariant
                font.pixelSize: 11
                font.family: Config.fontFamily
                Behavior on color {
                    ColorAnimation {
                        duration: 400
                    }
                }
            }
        }

        Item {
            id: middleRow
            anchors {
                left: parent.left
                right: parent.right
                top: topRow.bottom
                bottom: bottomRow.top
                leftMargin: 14
                rightMargin: 14
            }

            readonly property bool isPlaying: root.player?.playbackState === MprisPlaybackState.Playing

            Column {
                anchors {
                    left: parent.left
                    right: playBtn.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 4

                XfadeText {
                    target: root.player?.trackTitle ?? "Nothing playing"
                    textColor: root.colOnSurface
                    pixelSize: 19
                    fontWeight: Font.Medium
                }
                XfadeText {
                    target: root.player?.trackArtist ?? ""
                    textColor: root.colOnSurfaceVariant
                    pixelSize: 12
                }
            }

            Rectangle {
                id: playBtn
                width: 44
                height: 44
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                radius: middleRow.isPlaying ? 14 : 26
                color: root.colPrimary

                Behavior on radius {
                    enabled: !root.suppressAnimations
                    NumberAnimation {
                        duration: 320
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
                    text: middleRow.isPlaying ? "󰏤" : "󰐊"
                    font.family: Config.fontFamily
                    font.pixelSize: 18
                    color: root.colOnPrimary
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }

                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.player?.togglePlaying();
                        root.resyncPosition();
                    }
                }
            }
        }

        Item {
            id: bottomRow
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                bottomMargin: 12
                leftMargin: 14
                rightMargin: 14
            }
            height: 28

            Item {
                id: prevBtn
                width: 28
                height: 28
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                opacity: (root.player?.canGoPrevious ?? false) ? 1.0 : 0.4
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: prevMa.containsMouse && (root.player?.canGoPrevious ?? false) ? root.colHoverTint : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: Config.fontFamily
                    font.pixelSize: 16
                    color: root.colOnSurface
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }
                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (root.player?.canGoNext ?? false) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (!(root.player?.canGoPrevious ?? false))
                            return;
                        root.player.previous();
                        root.handleTrackChange();
                        skipSyncTimer.restart();
                    }
                }
            }

            Item {
                id: scrubber
                anchors {
                    left: prevBtn.right
                    leftMargin: 8
                    right: nextBtn.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                height: 28

                property bool scrubHover: false
                property real thumbW: scrubHover ? 2 : 0
                property real thumbGap: scrubHover ? 4 : 2

                Behavior on thumbW {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on thumbGap {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: barLeft
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    width: root.displayProgress * (parent.width - scrubber.thumbW - scrubber.thumbGap * 2)
                    height: 4
                    radius: 3
                    color: root.colBarFill
                    Behavior on height {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }

                Rectangle {
                    id: thumbRect
                    anchors.verticalCenter: parent.verticalCenter
                    x: barLeft.width + scrubber.thumbGap
                    width: scrubber.thumbW
                    height: scrubber.scrubHover ? 16 : 14
                    radius: 1
                    color: root.colPrimary
                    Behavior on height {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }

                Rectangle {
                    anchors {
                        left: thumbRect.right
                        leftMargin: scrubber.thumbGap
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: 4
                    radius: 3
                    color: root.colBarTrack
                    Behavior on height {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (root.player?.canSeek ?? false) ? Qt.SizeHorCursor : Qt.ArrowCursor
                    onEntered: scrubber.scrubHover = true
                    onExited: if (!pressed)
                        scrubber.scrubHover = false
                    onPressed: mouse => {
                        if (!(root.player?.canSeek ?? false))
                            return;
                        root._isDragging = true;
                        root._dragProgress = Math.max(0, Math.min(mouse.x / width, 1));
                    }
                    onPositionChanged: mouse => {
                        if (root._isDragging)
                            root._dragProgress = Math.max(0, Math.min(mouse.x / width, 1));
                    }
                    onReleased: mouse => {
                        if (root._isDragging && (root.player?.canSeek ?? false)) {
                            root.player.position = root._dragProgress * (root._displayLength);
                            root.resyncPosition();
                        }
                        root._isDragging = false;
                        scrubber.scrubHover = containsMouse;
                    }
                }
            }

            Item {
                id: nextBtn
                width: 28
                height: 28
                anchors {
                    right: pinBtn.left
                    rightMargin: root.showPin ? 4 : 0
                    verticalCenter: parent.verticalCenter
                }
                opacity: (root.player?.canGoNext ?? false) ? 1.0 : 0.4
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: nextMa.containsMouse && (root.player?.canGoNext ?? false) ? root.colHoverTint : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: Config.fontFamily
                    font.pixelSize: 16
                    color: root.colOnSurface
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }
                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (root.player?.canGoNext ?? false) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (!(root.player?.canGoNext ?? false))
                            return;
                        root.player.next();
                        root.handleTrackChange();
                        skipSyncTimer.restart();
                    }
                }
            }

            Item {
                id: pinBtn
                width: root.showPin ? 28 : 0
                height: 28
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                visible: root.showPin

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: root.pinned ? root.colPrimary : pinMa.containsMouse ? root.colHoverTint : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰐃"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: root.pinned ? root.colOnPrimary : root.colOnSurfaceVariant
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
                MouseArea {
                    id: pinMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pinToggled()
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"
            border.width: 1
            border.color: root.colOutline
            Behavior on border.color {
                ColorAnimation {
                    duration: 500
                }
            }
        }
    }

    component BgImage: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        opacity: 0
        cache: true
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 30
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
