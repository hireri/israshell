import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.style
import qs.services

Rectangle {
    id: root

    required property var panelScreen

    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 18
    implicitWidth: 240
    height: 32

    readonly property bool isOpen: MediaPlayerState.openScreen === panelScreen
    property bool popupWindowVisible: false

    onIsOpenChanged: {
        if (isOpen) {
            popupWindowVisible = true;
            popup.anchor.updateAnchor();
        }
    }

    function closePopup() {
        MediaPlayerState.close();
        closeDelayTimer.start();
    }

    Timer {
        id: closeDelayTimer
        interval: 220
        onTriggered: root.popupWindowVisible = false
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
        spacing: 8

        Item {
            id: pillCover
            implicitWidth: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isPlaying: MediaPlayerState.displayPlayer?.playbackState === MprisPlaybackState.Playing
            readonly property bool shouldSpin: Config.spinningCover && isPlaying

            ClippingRectangle {
                anchors.fill: parent
                radius: 30
                color: Colors.md3.surface_container_highest
                Text {
                    anchors.centerIn: parent
                    text: "󰝚"
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 14
                    font.family: Config.fontFamily
                }
            }

            ClippingRectangle {
                anchors.fill: parent
                radius: 30
                visible: pillArt.status === Image.Ready
                color: "transparent"

                Image {
                    id: pillArt
                    anchors.fill: parent
                    source: MediaPlayerState.displayPlayer?.trackArtUrl ?? ""
                    antialiasing: true
                    smooth: true
                    layer.enabled: true
                    layer.smooth: true

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
            implicitWidth: 200
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
                text: marqueeText.text
            }

            Rectangle {
                anchors.left: parent.left
                implicitWidth: 20
                height: parent.height
                visible: marqueeContainer.shouldScroll
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Colors.md3.surface_container_high
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }
            Rectangle {
                anchors.right: parent.right
                implicitWidth: 20
                height: parent.height
                visible: marqueeContainer.shouldScroll
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1.0
                        color: Colors.md3.surface_container_high
                    }
                }
            }
        }
    }

    property bool _cardAIsFront: true
    readonly property var _frontCard: _cardAIsFront ? cardA : cardB
    readonly property var _backCard: _cardAIsFront ? cardB : cardA

    function _syncBackCard() {
        const players = MediaPlayerState.players;
        const frontPlayer = _frontCard.player;
        const other = players.find(p => p !== frontPlayer) ?? null;
        if (_backCard.player !== other) {
            _backCard.suppressAnimations = true;
            _backCard.player = other;
            Qt.callLater(() => {
                _backCard.suppressAnimations = false;
            });
        }
    }

    Connections {
        target: MediaPlayerState

        function onPlayersChanged() {
            root._syncBackCard();
        }

        function onPlayerSwitched(oldPlayer, newPlayer) {
            _backCard.suppressAnimations = true;
            _backCard.player = newPlayer;
            _backCard.syncPosition();
            Qt.callLater(() => {
                _backCard.suppressAnimations = false;
                swapOut.start();
            });
        }

        function onPlayerChangedSilently(newPlayer) {
            _frontCard.suppressAnimations = true;
            _frontCard.player = newPlayer;
            Qt.callLater(() => {
                _frontCard.suppressAnimations = false;
            });
        }
    }

    PopupWindow {
        id: popup
        anchor.item: root
        anchor.rect {
            x: Math.round(root.width / 2 - implicitWidth / 2)
            y: root.height + 2
            width: implicitWidth
            height: 1
        }
        implicitWidth: 380
        implicitHeight: animContainer.implicitHeight
        color: "transparent"
        visible: root.popupWindowVisible

        HyprlandFocusGrab {
            windows: [popup]
            active: root.isOpen
            onCleared: root.closePopup()
        }

        Item {
            id: animContainer
            anchors.fill: parent
            implicitHeight: popupCol.implicitHeight + 32
            opacity: root.isOpen ? 1 : 0
            scale: root.isOpen ? 1 : 0.94
            transformOrigin: Item.Top

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

            Item {
                anchors.fill: parent
                focus: root.isOpen
                Keys.onEscapePressed: root.closePopup()
            }

            Column {
                id: popupCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 16
                    topMargin: 16
                }
                spacing: 10

                Item {
                    id: cardStack
                    width: parent.width
                    height: cardA.implicitHeight

                    PlayerCard {
                        id: cardA
                        z: root._cardAIsFront ? 1 : 0
                        enabled: root._cardAIsFront
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: root._cardAIsFront ? 1 : 0
                        scale: root._cardAIsFront ? 1 : 0.92
                        pinned: MediaPlayerState.pinnedPlayer === player
                        showPin: MediaPlayerState.players.length >= 2
                        onPinToggled: MediaPlayerState.pin(player)
                        Component.onCompleted: {
                            player = MediaPlayerState.currentPlayer;
                            Qt.callLater(() => root._syncBackCard());
                        }
                    }

                    PlayerCard {
                        id: cardB
                        z: root._cardAIsFront ? 0 : 1
                        enabled: !root._cardAIsFront
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: root._cardAIsFront ? 0 : 1
                        scale: root._cardAIsFront ? 0.92 : 1
                        pinned: MediaPlayerState.pinnedPlayer === player
                        showPin: MediaPlayerState.players.length >= 2
                        onPinToggled: MediaPlayerState.pin(player)
                    }

                    ParallelAnimation {
                        id: swapOut
                        NumberAnimation {
                            target: root._frontCard
                            property: "opacity"
                            to: 0
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: root._frontCard
                            property: "scale"
                            to: 0.92
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                        onFinished: {
                            root._cardAIsFront = !root._cardAIsFront;

                            root._frontCard.opacity = 0;
                            root._frontCard.scale = 0.92;

                            root._syncBackCard();
                            swapIn.start();
                        }
                    }

                    ParallelAnimation {
                        id: swapIn
                        onStarted: {
                            animationOp.target = root._frontCard;
                            animationSc.target = root._frontCard;
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
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 44
                    implicitWidth: chipRow.implicitWidth + 10

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: root._frontCard.colSurfaceContainer
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
                                color: root._frontCard.colSurface
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
                                    text: sourcePill.noPlayers ? "No players" : root.getPlayerName(MediaPlayerState.players[0])
                                    color: root._frontCard.colOnSurface
                                    font.pixelSize: 13
                                    font.family: Config.fontFamily
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
                                color: root._frontCard.colPrimary
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

                                        Text {
                                            anchors.centerIn: parent
                                            font.family: Config.fontFamily
                                            font.pixelSize: 15
                                            text: "󰝚"
                                            visible: !appIcon.visible
                                            color: isCurrent ? root._frontCard.colOnPrimary : root._frontCard.colOnPrimaryContainer
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
                                color: root._frontCard.colSurface
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
                                color: root._frontCard.colOnPrimaryContainer
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
                                    root.closePopup();
                                }
                            }
                        }
                    }
                }
            }
        }

        Process {
            id: pavuProc
            command: ['qs', 'ipc', 'call', 'settings', 'open', 'sound']
            running: false
        }
    }
}
