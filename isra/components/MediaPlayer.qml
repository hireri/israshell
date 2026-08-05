pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.style
import qs.services
import qs.icons

ClippingRectangle {
    id: root

    required property var panelScreen
    property var panelWindow: null

    color: {
        if (root.isOpen) {
            Colors.md3.secondary_container
        } else if (Config.bar.transparentPills) {
            Qt.alpha(Colors.md3.secondary_container, 0)
        } else { 
            Qt.alpha(Colors.md3.surface_container_high, 0.8)
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    radius: Config.bar.playerMode === 1 ? height / 2 : 18
    implicitWidth: {
        if (Config.bar.playerMode === 1)
            return 32;
        if (Config.bar.playerMode === 2)
            return 216;
        return 240;
    }
    height: 32

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    readonly property bool isOpen: MediaPlayerState.openScreen === panelScreen
    readonly property bool _barAtBottom: Config.bar.position === 1
    property bool popupWindowVisible: false

    onIsOpenChanged: {
        if (isOpen) {
            closeDelayTimer.stop();
            popupWindowVisible = true;
            PanelService.opened(root, root.panelScreen ?? root.panelWindow?.screen);
        } else {
            closeDelayTimer.restart();
            PanelService.closed(root);
        }
    }

    function close(): void {
        if (root.isOpen)
            MediaPlayerState.close();
    }

    Timer {
        id: closeDelayTimer
        interval: 220
        onTriggered: if (!root.isOpen)
            root.popupWindowVisible = false
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

    function getPlayerName(player) {
        if (!player)
            return "";
        const de = (player.desktopEntry ?? "").trim();
        const identity = (player.identity ?? "").trim();
        const id = de !== "" ? de : identity;
        const entry = id !== "" ? DesktopEntries.heuristicLookup(id) : null;
        const name = entry?.name ?? identity ?? de.split(".").pop() ?? "";
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                MediaPlayerState.toggle(root.panelScreen);
                return;
            }
            const p = MediaPlayerState.displayPlayer;
            if (!p)
                return;
            if (mouse.button === Qt.RightButton)
                p.next();
            if (mouse.button === Qt.MiddleButton)
                p.playbackState === MprisPlaybackState.Playing ? p.pause() : p.play();
        }
        onWheel: wheel => {
            const p = MediaPlayerState.displayPlayer;
            if (!p)
                return;
            p.volume = Math.max(0, Math.min(1, p.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: (Config.bar.playerMode === 1 || Config.bar.playerMode === 2) ? 0 : 8

        Item {
            id: pillCover
            visible: Config.bar.playerMode !== 2
            implicitWidth: Config.bar.playerMode === 1 ? root.height - 4 : 24
            height: Config.bar.playerMode === 1 ? root.height - 4 : 24
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isPlaying: MediaPlayerState.displayPlayer?.playbackState === MprisPlaybackState.Playing
            readonly property bool shouldSpin: Config.bar.spinningCover && isPlaying

            readonly property bool hasPlayer: MediaPlayerState.displayPlayer !== null && MediaPlayerState.displayPlayer !== undefined
            readonly property bool showRing: hasPlayer && (Config.bar.playerRing ?? false)

            property real coverMargin: showRing ? 4 : 0
            property real ringStrokeWidth: showRing ? 2.2 : 0

            Behavior on coverMargin {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on ringStrokeWidth {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            property real displayProgress: 0
            readonly property var displayPlayer: MediaPlayerState.displayPlayer

            function syncProgress() {
                if (trackResetAnim.running) return;
                const p = displayPlayer;
                if (!p || !p.length || p.length <= 0) {
                    displayProgress = 0;
                    return;
                }
                const target = Math.min(1.0, Math.max(0.0, p.position / p.length));
                if (target < displayProgress - 0.05) {
                    animateResetTo(target);
                } else {
                    displayProgress = target;
                }
            }

            function animateResetTo(targetVal) {
                trackResetAnim.stop();
                trackResetAnim.to = targetVal;
                trackResetAnim.start();
            }

            NumberAnimation {
                id: trackResetAnim
                target: pillCover
                property: "displayProgress"
                duration: 380
                easing.type: Easing.OutCubic
            }

            Connections {
                target: MediaPlayerState
                function onDisplayPlayerChanged() {
                    pillCover.animateResetTo(0);
                }
            }

            Connections {
                target: MediaPlayerState.displayPlayer ?? null
                function onTrackTitleChanged() {
                    pillCover.animateResetTo(0);
                }
                function onPositionChanged() {
                    pillCover.syncProgress();
                }
            }

            Timer {
                id: smoothPosTimer
                interval: 16
                repeat: true
                running: root.visible && pillCover.displayPlayer !== null && pillCover.displayPlayer.playbackState === MprisPlaybackState.Playing && !trackResetAnim.running
                onTriggered: {
                    if (pillCover.displayPlayer) {
                        pillCover.displayPlayer.positionChanged();
                        pillCover.syncProgress();
                    }
                }
            }

            Canvas {
                id: progressRing
                anchors.fill: parent
                antialiasing: true

                readonly property real progress: pillCover.displayProgress

                onProgressChanged: requestPaint()

                Connections {
                    target: pillCover
                    function onRingStrokeWidthChanged() {
                        progressRing.requestPaint();
                    }
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const strokeWidth = pillCover.ringStrokeWidth;
                    if (strokeWidth <= 0.01) return;

                    const centerX = width / 2;
                    const centerY = height / 2;
                    const radius = (Math.min(width, height) - strokeWidth) / 2;

                    if (radius <= 0) return;

                    const activeColor = Colors.md3.primary;
                    const trackColor = Qt.alpha(Colors.md3.primary, 0.25);

                    const topAngle = -Math.PI / 2;
                    const fullGap = 15 * (Math.PI / 180);
                    const halfFullGap = fullGap / 2;

                    const p = Math.max(0, Math.min(1, progress));
                    const pMin = 0.03;
                    const minArcAngle = 0.04;

                    const activeAlpha = Math.min(1.0, Math.max(0.0, p / pMin));
                    const remainingAlpha = Math.min(1.0, Math.max(0.0, (1 - p) / pMin));

                    let dynamicGap = fullGap;
                    if (p < pMin) {
                        dynamicGap = fullGap * (p / pMin);
                    } else if (p > 1 - pMin) {
                        dynamicGap = fullGap * ((1 - p) / pMin);
                    }
                    const halfDynamicGap = dynamicGap / 2;

                    const progressAngle = p * 2 * Math.PI;

                    if (activeAlpha > 0) {
                        ctx.save();
                        ctx.globalAlpha = activeAlpha;

                        const activeStart = topAngle + halfFullGap;
                        let activeEnd = topAngle + progressAngle - halfDynamicGap;

                        if (p >= 0.995) {
                            activeEnd = topAngle + 2 * Math.PI - halfFullGap;
                        } else if (activeEnd - activeStart < minArcAngle) {
                            activeEnd = activeStart + minArcAngle;
                        }

                        if (activeEnd > activeStart) {
                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, activeStart, activeEnd);
                            ctx.strokeStyle = activeColor;
                            ctx.lineWidth = strokeWidth;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                        ctx.restore();
                    }

                    if (remainingAlpha > 0) {
                        ctx.save();
                        ctx.globalAlpha = remainingAlpha;

                        let remainingStart = topAngle + progressAngle + halfDynamicGap;
                        const remainingEnd = topAngle + 2 * Math.PI - halfFullGap;

                        if (p <= 0.005) {
                            remainingStart = topAngle + halfFullGap;
                        } else if (remainingEnd - remainingStart < minArcAngle) {
                            remainingStart = remainingEnd - minArcAngle;
                        }

                        if (remainingEnd > remainingStart) {
                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, remainingStart, remainingEnd);
                            ctx.strokeStyle = trackColor;
                            ctx.lineWidth = strokeWidth;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                        ctx.restore();
                    }
                }
            }

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: pillCover.coverMargin
                radius: 30
                color: Colors.md3.surface_container_highest
                MaterialIcon {
                    anchors.centerIn: parent
                    name: "music-note"
                    color: Colors.md3.on_surface_variant
                    iconSize: 14
                }
            }

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: pillCover.coverMargin
                radius: 30
                visible: pillArt.status === Image.Ready
                color: "transparent"
                antialiasing: true

                Image {
                    id: pillArt
                    anchors.fill: parent
                    source: MediaPlayerState.displayPlayer?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize: Qt.size(60, 60)

                    property real angle: 0
                    property real velocity: pillCover.shouldSpin ? 0.5 : 0
                    rotation: angle

                    Behavior on velocity {
                        NumberAnimation {
                            duration: 600
                            easing.type: Easing.OutCubic
                        }
                    }

                    Timer {
                        interval: 16
                        running: pillArt.visible
                        repeat: true
                        onTriggered: {
                            if (Math.abs(pillArt.velocity) > 0.001)
                                pillArt.angle = (pillArt.angle + pillArt.velocity) % 360;
                        }
                    }
                }
            }
        }

        Item {
            id: marqueeContainer
            visible: Config.bar.playerMode !== 1
            implicitWidth: Config.bar.playerMode !== 1 ? (Config.bar.playerMode === 2 ? 176 : 200) : 0
            height: 20
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool shouldScroll: marqueeText.implicitWidth > implicitWidth
            property real scrollPos: 0

            Component.onCompleted: {
                if (shouldScroll)
                    marqueeAnim.restart();
            }

            NumberAnimation {
                id: marqueeAnim
                target: marqueeContainer
                property: "scrollPos"
                from: 0
                to: marqueeText.implicitWidth + 20
                duration: (marqueeText.implicitWidth + 20) * 1000 / Config.carouselSpeed
                loops: Animation.Infinite
            }

            Text {
                id: marqueeText
                anchors.verticalCenter: parent.verticalCenter
                x: marqueeContainer.shouldScroll ? -marqueeContainer.scrollPos : (marqueeContainer.width - implicitWidth) / 2
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                renderType: Text.NativeRendering
                text: {
                    const p = MediaPlayerState.displayPlayer;
                    if (!p)
                        return "nothing playing   ᓚ₍ ^. .^₎";
                    return p.trackTitle + "  •  " + p.trackArtist;
                }
                onTextChanged: {
                    if (marqueeContainer.shouldScroll)
                        marqueeAnim.restart();
                    else {
                        marqueeAnim.stop();
                        marqueeContainer.scrollPos = 0;
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: marqueeText.x + marqueeText.implicitWidth + 20
                visible: marqueeContainer.shouldScroll
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                renderType: Text.NativeRendering
                text: marqueeText.text
            }
        }
    }

    Variants {
        id: popupVariants
        model: Quickshell.screens

        PanelWindow {
            id: popup

            required property ShellScreen modelData
            screen: modelData

            readonly property bool isOwnScreen: modelData === (root.panelScreen ?? root.panelWindow?.screen)

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            visible: root.popupWindowVisible

            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:mediaOverlay"

            readonly property real popupWidth: 380
            readonly property real contentMargin: 16
            readonly property real popupHeight: cardStack.height + chipItem.height + 10 + (contentMargin * 2)
            readonly property real screenEdgeMargin: 12
            readonly property real verticalGap: 8

            property real calculatedX: 0
            property real calculatedY: 0

            function updatePosition() {
                if (!root.visible || !popup.visible || !popup.isOwnScreen)
                    return;

                const screenWidth = popup.width > 0 ? popup.width : (modelData.geometry?.width ?? modelData.width ?? 1920);
                const screenHeight = popup.height > 0 ? popup.height : (modelData.geometry?.height ?? modelData.height ?? 1080);

                const pillPos = root.mapToItem(null, 0, 0);
                const barWindow = root.QsWindow?.window ?? null;
                const barHeight = (barWindow && barWindow.implicitHeight > 0) ? barWindow.implicitHeight : root.height;

                calculatedX = _clampedCenteredX(pillPos.x, screenWidth);
                calculatedY = root._barAtBottom ? _yAboveBottomBar(screenHeight, barHeight) : _yBelowTopBar(barHeight);
            }

            function _clampedCenteredX(pillX, screenWidth) {
                const idealX = pillX + (root.width / 2) - (popupWidth / 2);
                return Math.max(screenEdgeMargin, Math.min(screenWidth - popupWidth - screenEdgeMargin, idealX));
            }

            function _yAboveBottomBar(screenHeight, barHeight) {
                return (screenHeight - barHeight) - popupHeight - verticalGap + contentMargin;
            }

            function _yBelowTopBar(barHeight) {
                return barHeight + verticalGap - contentMargin;
            }

            onWidthChanged: updatePosition()
            onHeightChanged: updatePosition()
            onVisibleChanged: {
                if (visible && popup.isOwnScreen) {
                    updatePosition();
                    Qt.callLater(updatePosition);
                }
            }

            Connections {
                target: root
                function onXChanged() { if (popup.isOwnScreen) popup.updatePosition(); }
                function onYChanged() { if (popup.isOwnScreen) popup.updatePosition(); }
                function onWidthChanged() { if (popup.isOwnScreen) popup.updatePosition(); }
            }

            Connections {
                target: cardStack
                function onHeightChanged() { if (popup.isOwnScreen) popup.updatePosition(); }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Item {
                id: animContainer
                visible: popup.isOwnScreen
                x: popup.calculatedX
                y: popup.calculatedY
                width: popup.popupWidth
                height: popup.popupHeight

                opacity: root.isOpen ? 1 : 0
                scale: root.isOpen ? 1 : 0.92

                transformOrigin: root._barAtBottom ? Item.Bottom : Item.Top

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                Item {
                    anchors.fill: parent
                    focus: root.isOpen && popup.isOwnScreen
                    Keys.onEscapePressed: root.close()
                }

                Item {
                    id: popupContent
                    anchors.fill: parent
                    anchors.margins: popup.contentMargin

                    Item {
                        id: cardStack

                        property bool cardAIsFront: true
                        readonly property var frontCard: cardAIsFront ? cardA : cardB
                        readonly property var backCard: cardAIsFront ? cardB : cardA

                        function syncBackCard() {
                            const players = MediaPlayerState.players;
                            const frontPlayer = cardStack.frontCard.player;
                            const other = players.find(p => p !== frontPlayer) ?? null;
                            if (cardStack.backCard.player !== other) {
                                cardStack.backCard.suppressAnimations = true;
                                cardStack.backCard.player = other;
                                Qt.callLater(() => {
                                    cardStack.backCard.suppressAnimations = false;
                                });
                            }
                        }

                        Connections {
                            target: MediaPlayerState

                            function onPlayersChanged() {
                                cardStack.syncBackCard();
                            }

                            function onPlayerSwitched(oldPlayer, newPlayer) {
                                cardStack.backCard.suppressAnimations = true;
                                cardStack.backCard.player = newPlayer;
                                cardStack.backCard.resyncPosition();
                                Qt.callLater(() => {
                                    cardStack.backCard.suppressAnimations = false;
                                    swapOut.start();
                                });
                            }

                            function onPlayerChangedSilently(newPlayer) {
                                cardStack.frontCard.suppressAnimations = true;
                                cardStack.frontCard.player = newPlayer;
                                Qt.callLater(() => {
                                    cardStack.frontCard.suppressAnimations = false;
                                });
                            }
                        }

                        y: root._barAtBottom ? chipItem.height + 10 : 0
                        width: parent.width
                        height: cardA.implicitHeight

                        PlayerCard {
                            id: cardA
                            z: cardStack.cardAIsFront ? 1 : 0
                            enabled: cardStack.cardAIsFront
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: cardStack.cardAIsFront ? 1 : 0
                            scale: cardStack.cardAIsFront ? 1 : 0.92
                            pinned: MediaPlayerState.pinnedPlayer === player
                            showPin: MediaPlayerState.players.length >= 2
                            onPinToggled: MediaPlayerState.pin(player)
                            Component.onCompleted: {
                                player = MediaPlayerState.currentPlayer;
                                Qt.callLater(() => cardStack.syncBackCard());
                            }
                        }

                        PlayerCard {
                            id: cardB
                            z: cardStack.cardAIsFront ? 0 : 1
                            enabled: !cardStack.cardAIsFront
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: cardStack.cardAIsFront ? 0 : 1
                            scale: cardStack.cardAIsFront ? 0.92 : 1
                            pinned: MediaPlayerState.pinnedPlayer === player
                            showPin: MediaPlayerState.players.length >= 2
                            onPinToggled: MediaPlayerState.pin(player)
                        }

                        ParallelAnimation {
                            id: swapOut
                            NumberAnimation {
                                target: cardStack.frontCard
                                property: "opacity"
                                to: 0
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: cardStack.frontCard
                                property: "scale"
                                to: 0.92
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                            onFinished: {
                                cardStack.cardAIsFront = !cardStack.cardAIsFront;

                                cardStack.frontCard.opacity = 0;
                                cardStack.frontCard.scale = 0.92;

                                cardStack.syncBackCard();
                                swapIn.start();
                            }
                        }

                        ParallelAnimation {
                            id: swapIn
                            onStarted: {
                                animationOp.target = cardStack.frontCard;
                                animationSc.target = cardStack.frontCard;
                            }

                            NumberAnimation {
                                id: animationOp
                                property: "opacity"
                                to: 1
                                duration: 260
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                id: animationSc
                                property: "scale"
                                to: 1
                                duration: 260
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Item {
                        id: chipItem

                        y: root._barAtBottom ? 0 : cardStack.height + 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 44
                        implicitWidth: chipRow.implicitWidth + 10

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: cardStack.frontCard.colSurfaceContainer
                            Behavior on color {
                                ColorAnimation {
                                    duration: 400
                                }
                            }
                        }

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 4

                            Item {
                                id: sourcePill
                                height: 36
                                readonly property bool multi: MediaPlayerState.players.length >= 2
                                readonly property bool noPlayers: MediaPlayerState.players.length === 0
                                width: multi ? Math.max(srcRow.implicitWidth + 8, 44) : Math.max(singleRow.implicitWidth + 24, 60)
                                Behavior on width {
                                    NumberAnimation {
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: cardStack.frontCard.colSurfaceContainerHigh
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 400
                                        }
                                    }
                                }

                                Row {
                                    id: singleRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    opacity: sourcePill.multi ? 0 : 1
                                    visible: !sourcePill.multi
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 180
                                        }
                                    }

                                    IconImage {
                                        implicitSize: 18
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: root.getIconSource(MediaPlayerState.players[0])
                                        visible: source !== "" && status !== Image.Error
                                        mipmap: true
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: sourcePill.noPlayers ? Localization.t("mediaPlayer.no_players") : root.getPlayerName(MediaPlayerState.players[0])
                                        color: cardStack.frontCard.colOnSurface
                                        font.pixelSize: 13
                                        font.family: Config.fontFamily
                                        renderType: Text.NativeRendering
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 400
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: chipSlider
                                    height: 28
                                    y: 4
                                    radius: height / 2
                                    color: cardStack.frontCard.colPrimary
                                    opacity: sourcePill.multi ? 1 : 0
                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 220
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 220
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 180
                                        }
                                    }
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 400
                                        }
                                    }
                                }

                                Row {
                                    id: srcRow
                                    anchors.centerIn: parent
                                    spacing: 2
                                    opacity: sourcePill.multi ? 1 : 0
                                    visible: sourcePill.multi
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 180
                                        }
                                    }

                                    Repeater {
                                        id: playerRepeater
                                        model: MediaPlayerState.players
                                        delegate: Item {
                                            required property var modelData
                                            required property int index
                                            width: 36
                                            height: 36
                                            readonly property bool isCurrent: modelData === MediaPlayerState.currentPlayer

                                            IconImage {
                                                id: appIcon
                                                anchors.centerIn: parent
                                                implicitSize: 18
                                                source: root.getIconSource(modelData)
                                                visible: source !== "" && status !== Image.Error
                                                mipmap: true
                                                opacity: isCurrent ? 1.0 : 0.5
                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                iconSize: 16
                                                name: "music-note"
                                                visible: !appIcon.visible
                                                color: isCurrent ? cardStack.frontCard.colOnPrimary : cardStack.frontCard.colOnPrimaryContainer
                                                opacity: isCurrent ? 1.0 : 0.5
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }
                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: MediaPlayerState.switchTo(modelData)
                                            }
                                        }
                                    }
                                }

                                function updateSlider() {
                                    if (!multi)
                                        return;
                                    for (let i = 0; i < playerRepeater.count; i++) {
                                        const item = playerRepeater.itemAt(i);
                                        if (item && item.isCurrent) {
                                            const mapped = item.mapToItem(sourcePill, 0, 0);
                                            chipSlider.x = mapped.x;
                                            chipSlider.width = item.width;
                                            return;
                                        }
                                    }
                                }

                                onWidthChanged: Qt.callLater(updateSlider)
                                onVisibleChanged: Qt.callLater(updateSlider)

                                Connections {
                                    target: MediaPlayerState
                                    function onCurrentPlayerChanged() {
                                        Qt.callLater(sourcePill.updateSlider);
                                    }
                                    function onPlayersChanged() {
                                        Qt.callLater(sourcePill.updateSlider);
                                    }
                                }
                            }

                            Item {
                                height: 36
                                width: 36
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: cardStack.frontCard.colSurfaceContainerHigh
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 400
                                        }
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰴸"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 15
                                    color: cardStack.frontCard.colOnPrimaryContainer
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 400
                                        }
                                    }
                                }
                                MouseArea {
                                    id: hpMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        pavuProc.running = true;
                                        root.close();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Process {
                id: pavuProc
                command: ['qs', '-c', 'isra', 'ipc', 'call', 'settings', 'open', 'sound']
                running: false
            }
        }
    }
}