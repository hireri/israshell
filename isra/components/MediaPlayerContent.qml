pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.style
import qs.services
import qs.icons
import "PlayerIcon.js" as PlayerIcon

Item {
    id: root

    property var controller: null

    readonly property bool isOpen: controller ? controller.isOpen : false

    readonly property bool _barAtBottom: Config.bar.position === 1

    anchors.fill: parent

    function getIconSource(player) {
        return PlayerIcon.getIconSource(player, DesktopEntries);
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

    readonly property real popupWidth: 380
    readonly property real contentMargin: 16
    readonly property real popupHeight: cardStack.height + chipItem.height + 10 + (contentMargin * 2)
    readonly property real screenEdgeMargin: 12
    readonly property real verticalGap: 8

    property real calculatedX: 0
    property real calculatedY: 0

    function updatePosition() {
        if (!root.controller)
            return;

        const screen = root.controller.panelWindow.screen;
        const screenWidth = root.width > 0 ? root.width : (screen?.geometry?.width ?? screen?.width ?? 1920);
        const screenHeight = root.height > 0 ? root.height : (screen?.geometry?.height ?? screen?.height ?? 1080);

        const pillPos = root.controller.mapToItem(root, 0, 0);
        const barHeight = root.controller.panelWindow.barHeight;

        calculatedX = _clampedCenteredX(pillPos.x, screenWidth);
        calculatedY = root._barAtBottom ? _yAboveBottomBar(screenHeight, barHeight) : _yBelowTopBar(barHeight);
    }

    function _clampedCenteredX(pillX, screenWidth) {
        const idealX = pillX + (root.controller.width / 2) - (popupWidth / 2);
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
    onIsOpenChanged: {
        updatePosition();
        if (isOpen)
            Qt.callLater(() => escHandler.forceActiveFocus());
    }

    Component.onCompleted: {
        updatePosition();
        Qt.callLater(updatePosition);
    }

    Connections {
        target: root.controller
        function onXChanged() { root.updatePosition(); }
        function onYChanged() { root.updatePosition(); }
        function onWidthChanged() { root.updatePosition(); }
    }

    Connections {
        target: cardStack
        function onHeightChanged() { root.updatePosition(); }
    }

    Item {
        id: animContainer
        x: root.calculatedX
        y: root.calculatedY
        width: root.popupWidth
        height: root.popupHeight

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
            id: escHandler
            anchors.fill: parent
            focus: root.isOpen
            Keys.onEscapePressed: if (root.controller)
                root.controller.close()
        }

        Item {
            id: popupContent
            anchors.fill: parent
            anchors.margins: root.contentMargin

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
                        cardStack.backCard.snapToPosition();
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
                                if (root.controller)
                                    root.controller.close();
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
