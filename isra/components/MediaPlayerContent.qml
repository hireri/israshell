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

    readonly property var win: root.controller?.panelWindow ?? null
    readonly property bool melt: win?.meltActive ?? false
    anchors.topMargin: melt && !_barAtBottom ? win.barHeight : 0
    anchors.bottomMargin: melt && _barAtBottom ? win.barHeight : 0
    clip: melt

    property real meltP: isOpen ? 1 : 0
    Behavior on meltP {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }
    readonly property real meltTop: Math.max(root.y + animContainer.y, root.y)
    readonly property real meltBottom: Math.min(root.y + animContainer.y + animContainer.height, root.y + root.height)
    readonly property real meltVisible: Math.max(0, meltBottom - meltTop)

    MeltReporter {
        win: root.win
        key: "media"
        rect: Qt.rect(root.x + animContainer.x, root.meltTop, animContainer.width, root.meltVisible)
        active: root.melt && (root.isOpen || root.meltVisible > 0.5)
    }

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
    readonly property real inPad: melt ? 12 : 0
    readonly property real contentMargin: 16
    readonly property real popupHeight: cardStack.height + chipItem.height + 10 + (melt ? 6 + inPad : contentMargin * 2)
    readonly property real screenEdgeMargin: (win?.frameInset ?? 0) + (melt ? 0 : (win?.panelGap ?? 12))
    readonly property real verticalGap: win?.panelGap ?? 12

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
        calculatedY = root.melt ? (root._barAtBottom ? screenHeight - popupHeight : 0) : root._barAtBottom ? _yAboveBottomBar(screenHeight, barHeight) : _yBelowTopBar(barHeight);
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

    onMeltChanged: updatePosition()
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
        y: root.calculatedY + (root.melt ? (1 - root.meltP) * (root._barAtBottom ? root.popupHeight : -root.popupHeight) : 0)
        width: root.popupWidth
        height: root.popupHeight

        opacity: (root.isOpen || root.melt) ? 1 : 0
        scale: (root.isOpen || root.melt) ? 1 : 0.92

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
            anchors.leftMargin: root.melt ? 6 : root.contentMargin
            anchors.rightMargin: root.melt ? 6 : root.contentMargin
            anchors.topMargin: root.melt ? (root._barAtBottom ? 6 : 0) : root.contentMargin
            anchors.bottomMargin: root.melt ? (root._barAtBottom ? 0 : 6) : root.contentMargin
            opacity: root.melt ? Math.max(0, Math.min(1, (root.meltP - 0.5) * 2)) : 1

            Rectangle {
                id: meltBg
                visible: root.melt
                anchors.fill: parent
                readonly property real far: Math.max(0, (root.win?.meltRadius ?? 18) - 6)
                radius: far
                color: cardStack.frontCard.colSurface
                Behavior on color {
                    ColorAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
            }

            ClippingRectangle {
                visible: root.melt
                anchors.fill: parent
                color: "transparent"
                radius: meltBg.far

                CrossfadeArt {
                    anchors.fill: parent
                    url: cardStack.frontCard.artUrl
                    blurEnabled: true
                    blurAmount: 1.0
                    blurMax: 30
                    renderSize: Qt.size(120, 120)
                    fadeDuration: 380
                }
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(cardStack.frontCard._overlayBase.r, cardStack.frontCard._overlayBase.g, cardStack.frontCard._overlayBase.b, 0.5)
                }
            }

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

                y: root._barAtBottom && !root.melt ? root.inPad + chipItem.height + 10 : 0
                width: parent.width
                height: cardA.implicitHeight

                PlayerCard {
                    id: cardA
                    outlined: !root.melt
                    flat: root.melt
                    width: root.melt ? parent.width : implicitWidth
                    flatCorner: meltBg.far
                    _flatBottom: root._barAtBottom
                    z: cardStack.cardAIsFront ? 1 : 0
                    enabled: cardStack.cardAIsFront
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: cardStack.cardAIsFront ? 1 : 0
                    scale: cardStack.cardAIsFront ? 1 : 0.92
                    pinned: MediaPlayerState.pinnedPlayer === player
                    showPin: !root.melt && MediaPlayerState.players.length >= 2
                    onPinToggled: MediaPlayerState.togglePin(player)
                    Component.onCompleted: {
                        player = MediaPlayerState.currentPlayer;
                        Qt.callLater(() => cardStack.syncBackCard());
                    }
                }

                PlayerCard {
                    id: cardB
                    outlined: !root.melt
                    flat: root.melt
                    width: root.melt ? parent.width : implicitWidth
                    flatCorner: meltBg.far
                    _flatBottom: root._barAtBottom
                    z: cardStack.cardAIsFront ? 0 : 1
                    enabled: !cardStack.cardAIsFront
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: cardStack.cardAIsFront ? 0 : 1
                    scale: cardStack.cardAIsFront ? 0.92 : 1
                    pinned: MediaPlayerState.pinnedPlayer === player
                    showPin: !root.melt && MediaPlayerState.players.length >= 2
                    onPinToggled: MediaPlayerState.togglePin(player)
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

                y: root._barAtBottom && !root.melt ? root.inPad : cardStack.height + 10
                anchors.horizontalCenter: root.melt ? undefined : parent.horizontalCenter
                anchors.left: root.melt ? parent.left : undefined
                anchors.right: root.melt ? parent.right : undefined
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                width: root.melt ? undefined : implicitWidth
                height: root.melt ? 36 : 44
                implicitWidth: chipRow.implicitWidth + 10

                Rectangle {
                    visible: !root.melt
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
                    anchors.horizontalCenter: root.melt ? undefined : parent.horizontalCenter
                    anchors.left: root.melt ? parent.left : undefined
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Item {
                        id: sourcePill
                        height: 36
                        readonly property bool multi: MediaPlayerState.players.length >= 2
                        readonly property bool noPlayers: MediaPlayerState.players.length === 0
                        readonly property int n: MediaPlayerState.players.length
                        readonly property int curIdx: Math.max(0, MediaPlayerState.players.indexOf(MediaPlayerState.currentPlayer))
                        readonly property real gap: 2
                        readonly property real meltW: chipItem.width - meltBtns.width - chipRow.spacing
                        readonly property real availW: meltW - 8 - gap * (n - 1)
                        readonly property real natCur: 18 + 6 + curMetrics.width + 20
                        readonly property real curW: root.melt ? Math.max(36, availW * 3 / (n + 2)) : Math.max(36, natCur)
                        readonly property real othW: root.melt ? Math.max(36, availW / (n + 2)) : 36
                        readonly property real rowW: curW + (n - 1) * (othW + gap)
                        width: multi ? (root.melt ? meltW : rowW + 8) : root.melt ? meltW : Math.max(singleRow.implicitWidth + 24, 60)
                        Behavior on width {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }

                        TextMetrics {
                            id: curMetrics
                            text: root.getPlayerName(MediaPlayerState.currentPlayer)
                            font.pixelSize: 13
                            font.family: Config.fontFamily
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
                            x: (sourcePill.width - sourcePill.rowW) / 2 + sourcePill.curIdx * (sourcePill.othW + sourcePill.gap)
                            width: sourcePill.curW
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
                                    id: dlg
                                    required property var modelData
                                    required property int index
                                    width: isCurrent ? sourcePill.curW : sourcePill.othW
                                    height: 36
                                    readonly property bool isCurrent: modelData === MediaPlayerState.currentPlayer
                                    readonly property real textW: Math.min(curMetrics.width, width - 18 - 6 - 20)
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 220
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        IconImage {
                                            id: appIcon
                                            anchors.verticalCenter: parent.verticalCenter
                                            implicitSize: 18
                                            source: root.getIconSource(dlg.modelData)
                                            visible: source !== "" && status !== Image.Error
                                            mipmap: true
                                            opacity: dlg.isCurrent ? 1.0 : 0.5
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 150
                                                }
                                            }
                                        }

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            iconSize: 16
                                            name: "music-note"
                                            visible: !appIcon.visible
                                            color: dlg.isCurrent ? cardStack.frontCard.colOnPrimary : cardStack.frontCard.colOnPrimaryContainer
                                            opacity: dlg.isCurrent ? 1.0 : 0.5
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

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: dlg.isCurrent && dlg.textW > 30
                                            width: Math.max(0, dlg.textW)
                                            text: root.getPlayerName(dlg.modelData)
                                            elide: Text.ElideRight
                                            color: cardStack.frontCard.colOnPrimary
                                            font.pixelSize: 13
                                            font.family: Config.fontFamily
                                            renderType: Text.NativeRendering
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: MediaPlayerState.switchTo(dlg.modelData)
                                    }
                                }
                            }
                        }
                    }

                    ChipBtn {
                        card: cardStack.frontCard
                        visible: !root.melt
                        glyph: "󰴸"
                        onClicked: root.openSound()
                    }
                }

                Row {
                    id: meltBtns
                    visible: root.melt
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    ChipBtn {
                        card: cardStack.frontCard
                        visible: MediaPlayerState.players.length >= 2
                        glyph: "󰐃"
                        active: MediaPlayerState.pinnedPlayer !== null && MediaPlayerState.pinnedPlayer === cardStack.frontCard.player
                        onClicked: MediaPlayerState.togglePin(cardStack.frontCard.player)
                    }
                    ChipBtn {
                        card: cardStack.frontCard
                        glyph: "󰴸"
                        onClicked: root.openSound()
                    }
                }
            }
        }
    }

    function openSound() {
        pavuProc.running = true;
        if (controller)
            controller.close();
    }

    Process {
        id: pavuProc
        command: ['qs', '-c', 'isra', 'ipc', 'call', 'settings', 'open', 'sound']
        running: false
    }
}
