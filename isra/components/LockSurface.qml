import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

import qs.services
import qs.style
import qs.icons

Item {
    id: root

    Component {
        id: previousIconComp
        NextPrevIcon { iconSize: 15; color: Colors.md3.on_surface }
    }
    Component {
        id: nextIconComp
        NextPrevIcon { iconSize: 15; color: Colors.md3.on_surface; filled: true }
    }
    Component {
        id: playIconComp
        PlayPauseIcon { iconSize: 16; color: Colors.md3.on_surface }
    }
    Component {
        id: pauseIconComp
        PlayPauseIcon { iconSize: 16; color: Colors.md3.on_surface; filled: true }
    }
    Component {
        id: musicNoteIconComp
        MusicNoteIcon { iconSize: 15; color: Colors.md3.on_surface_variant }
    }
    Component {
        id: arrowRightIconComp
        ArrowForwardIcon { iconSize: 18 }
    }
    Component {
        id: logoutIconComp
        LogoutIcon { iconSize: 18 }
    }
    Component {
        id: restartIconComp
        RestartIcon { iconSize: 18 }
    }
    Component {
        id: powerIconComp
        ShutdownIcon { iconSize: 18 }
    }

    Component {
        id: notifBellIconComp
        NotificationsIcon { iconSize: 16; color: Colors.md3.on_surface_variant }
    }
    Component {
        id: notifBellIconFilledComp
        NotificationsIcon { iconSize: 16; color: Colors.md3.on_surface_variant; filled: true }
    }
    Component {
        id: dndIconComp
        DndIcon { iconSize: 16; color: Colors.md3.on_surface_variant }
    }
    Component {
        id: capsLockIconComp
        ShiftLockIcon { iconSize: 16; color: Colors.md3.on_surface_variant }
    }
    Component {
        id: capsLockIconFilledComp
        ShiftLockIcon { iconSize: 16; color: Colors.md3.on_surface_variant; filled: true }
    }

    readonly property var powerEntries: [
        {
            label: "Log Out",
            icon: logoutIconComp,
            command: ["sh", "-c", "loginctl terminate-user \"$USER\""],
            bg: Colors.md3.secondary_container,
            on: Colors.md3.on_secondary_container
        },
        {
            label: "Shut Down",
            icon: powerIconComp,
            command: ["sh", "-c", "systemctl poweroff || loginctl poweroff"],
            bg: Colors.md3.primary_container,
            on: Colors.md3.on_primary_container
        },
        {
            label: "Restart",
            icon: restartIconComp,
            command: ["sh", "-c", "systemctl reboot || loginctl reboot"],
            bg: Colors.md3.primary_container,
            on: Colors.md3.on_primary_container
        }
    ]

    ListModel { id: passwordModel }

    TextInput {
        id: hiddenPasswordInput
        anchors.fill: parent
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        enabled: !LockscreenService.unlockInProgress

        onActiveFocusChanged: {
            if (!activeFocus)
                forceActiveFocus()
        }

        onTextChanged: {
            LockscreenService.currentText = text
            while (passwordModel.count < text.length)  passwordModel.append({})
            while (passwordModel.count > text.length)  passwordModel.remove(passwordModel.count - 1)
        }

        Keys.onReturnPressed: LockscreenService.tryUnlock()
        Keys.onEnterPressed:  LockscreenService.tryUnlock()

        Connections {
            target: LockscreenService

            function onCurrentTextChanged() {
                if (hiddenPasswordInput.text !== LockscreenService.currentText)
                    hiddenPasswordInput.text = LockscreenService.currentText
            }
            function onUnlocked() {
                hiddenPasswordInput.text = ""
            }
            function onShowFailureChanged() {
                if (LockscreenService.showFailure) {
                    shakeAnimation.start()
                    hiddenPasswordInput.text = ""
                }
            }
        }
    }

    Process {
        id: powerProc
        running: false
    }

    property bool capsLockOn: false

    Process {
        id: capsLockProc
        command: [Quickshell.shellDir + "/scripts/check-capslock.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.capsLockOn = this.text.trim().length > 0
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: capsLockProc.running = true
    }

    readonly property int notifCount: {
        let c = 0;
        const groups = NotificationService.groups;
        for (const k in groups)
            c += groups[k].messages.length;
        return c;
    }

    readonly property var activeNet: NetworkService.activeNetwork
    readonly property bool netSecured: {
        const sec = root.activeNet?.security ?? "";
        return sec !== "" && sec !== "--";
    }

    readonly property bool hasBattery: UPower.displayDevice && UPower.displayDevice.isLaptopBattery

    Rectangle {
        id: centerPill
        anchors {
            bottom: parent.bottom
            bottomMargin: 48
            horizontalCenter: parent.horizontalCenter
        }
        height: 64
        width: centerRow.implicitWidth + 24
        radius: height / 2
        color: Colors.md3.surface_container

        SequentialAnimation {
            id: shakeAnimation
            loops: 2
            PropertyAnimation { target: centerPill; property: "x"; to: -12; duration: 40; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: centerPill; property: "x"; to:  12; duration: 80; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: centerPill; property: "x"; to:   0; duration: 40; easing.type: Easing.InOutQuad }
        }

        RowLayout {
            id: centerRow
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: 12
            }
            spacing: 16

            RowLayout {
                spacing: 10

                ClippingRectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: Colors.md3.surface_container_high

                    Image {
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/.face"
                        sourceSize: Qt.size(44, 44)
                        fillMode: Image.PreserveAspectCrop
                        antialiasing: true
                        smooth: true
                    }
                }

                Text {
                    text: Quickshell.env("USER")
                    color: Colors.md3.on_surface
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                id: inputPill
                height: 44
                width: 200
                radius: height / 2
                color: Colors.md3.surface_container_lowest

                Text {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 16
                    }
                    text: "Password"
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 14
                    opacity: 0.6
                    visible: hiddenPasswordInput.text.length === 0
                }

                ListView {
                    id: dotListView
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 12
                    }
                    clip: true
                    model: passwordModel
                    orientation: ListView.Horizontal
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds

                    Behavior on contentX {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    onContentWidthChanged: {
                        contentX = contentWidth > width ? contentWidth - width : 0
                    }

                    delegate: Item {
                        width: 12
                        height: dotListView.height

                        Rectangle {
                            id: dotVisual
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            radius: 4
                            color: Colors.md3.on_surface

                            SequentialAnimation {
                                running: LockscreenService.unlockInProgress
                                loops: Animation.Infinite

                                ParallelAnimation {
                                    NumberAnimation { target: dotVisual; property: "opacity"; to: 0.3; duration: 750; easing.type: Easing.InOutQuad }
                                    NumberAnimation { target: dotVisual; property: "scale";   to: 0.85; duration: 750; easing.type: Easing.InOutQuad }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: dotVisual; property: "opacity"; to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                                    NumberAnimation { target: dotVisual; property: "scale";   to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }

                    add: Transition {
                        NumberAnimation { property: "scale"; from: 0; to: 1; duration: 160; easing.type: Easing.OutBack }
                    }
                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "scale"; to: 0; duration: 120; easing.type: Easing.InQuad }
                            NumberAnimation { property: "width"; to: 0; duration: 120; easing.type: Easing.InQuad }
                        }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: 160; easing.type: Easing.OutCubic }
                    }
                }
            }

            Rectangle {
                id: submitButton
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: -8
                width: 44
                height: 44
                radius: 22
                enabled: !LockscreenService.unlockInProgress

                readonly property bool hasText: hiddenPasswordInput.text.length > 0

                color: {
                    if (!enabled) return Colors.md3.surface_container_high;
                    if (hasText) return Colors.md3.primary;
                    return submitMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high;
                }

                Behavior on color { ColorAnimation { duration: 150 } }

                Loader {
                    id: submitIconLoader
                    anchors.centerIn: parent
                    sourceComponent: arrowRightIconComp

                    Binding {
                        target: submitIconLoader.item
                        property: "color"
                        value: (submitButton.enabled && submitButton.hasText) ? Colors.md3.on_primary : Colors.md3.on_surface
                        when: submitIconLoader.status === Loader.Ready && submitIconLoader.item && submitIconLoader.item.hasOwnProperty("color")
                    }
                }

                MouseArea {
                    id: submitMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !LockscreenService.unlockInProgress
                    onClicked: LockscreenService.tryUnlock()
                }
            }
        }
    }

    Rectangle {
        id: leftPill
        anchors {
            verticalCenter: centerPill.verticalCenter
            right: centerPill.left
            rightMargin: 16
        }
        height: 64
        radius: height / 2
        color: Colors.md3.surface_container
        implicitWidth: leftRow.implicitWidth + 24

        readonly property var player: MediaPlayerState.displayPlayer
        readonly property bool hasPlayer: player !== null && player !== undefined
        readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing
        readonly property bool canPrev: hasPlayer && !!player.canGoPrevious
        readonly property bool canNext: hasPlayer && !!player.canGoNext
        readonly property bool canToggle: hasPlayer && !!player.canTogglePlaying
        readonly property bool shouldSpin: hasPlayer && Config.bar.spinningCover && isPlaying

        Behavior on implicitWidth {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        RowLayout {
            id: leftRow
            anchors.centerIn: parent
            spacing: 10

            Item {
                id: coverArt
                Layout.alignment: Qt.AlignVCenter
                width: 36
                height: 36

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 18
                    color: Colors.md3.surface_container_highest

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: musicNoteIconComp
                        visible: !leftPill.hasPlayer || coverArtImg.status !== Image.Ready
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 18
                    visible: leftPill.hasPlayer && coverArtImg.status === Image.Ready
                    color: "transparent"

                    Image {
                        id: coverArtImg
                        anchors.fill: parent
                        source: leftPill.hasPlayer ? (leftPill.player.trackArtUrl ?? "") : ""
                        fillMode: Image.PreserveAspectCrop
                        antialiasing: true
                        smooth: true
                        layer.enabled: true
                        layer.smooth: true

                        property real angle: 0
                        property real velocity: leftPill.shouldSpin ? 0.5 : 0
                        rotation: angle

                        Behavior on velocity {
                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                        }

                        Timer {
                            interval: 16
                            running: coverArtImg.visible
                            repeat: true
                            onTriggered: {
                                if (Math.abs(coverArtImg.velocity) > 0.001)
                                    coverArtImg.angle = (coverArtImg.angle + coverArtImg.velocity) % 360;
                            }
                        }
                    }
                }
            }

            Item {
                id: marqueeContainer
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 112
                height: 20
                clip: true

                readonly property string fullText: leftPill.hasPlayer
                    ? (leftPill.player.trackTitle + "  •  " + leftPill.player.trackArtist)
                    : "No media playing"
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
                    to: marqueeText.implicitWidth + 24
                    duration: (marqueeText.implicitWidth + 24) * 1000 / Config.carouselSpeed
                    loops: Animation.Infinite
                }

                Text {
                    id: marqueeText
                    anchors.verticalCenter: parent.verticalCenter
                    x: marqueeContainer.shouldScroll ? -marqueeContainer.scrollPos : (marqueeContainer.width - implicitWidth) / 2
                    color: Colors.md3.on_surface
                    font.pixelSize: 13
                    text: marqueeContainer.fullText

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
                    x: marqueeText.x + marqueeText.implicitWidth + 24
                    visible: marqueeContainer.shouldScroll
                    color: Colors.md3.on_surface
                    font.pixelSize: 13
                    text: marqueeText.text
                }

                Rectangle {
                    anchors.left: parent.left
                    width: 14
                    height: parent.height
                    visible: marqueeContainer.shouldScroll
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Colors.md3.surface_container }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    width: 14
                    height: parent.height
                    visible: marqueeContainer.shouldScroll
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Colors.md3.surface_container }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Item {
                    width: 26
                    height: 26
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: prevMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: previousIconComp
                        opacity: leftPill.canPrev ? 1 : 0.35
                    }
                    MouseArea {
                        id: prevMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: leftPill.canPrev
                        onClicked: leftPill.player.previous()
                    }
                }

                Item {
                    width: 30
                    height: 30
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: playMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: leftPill.isPlaying ? pauseIconComp : playIconComp
                        opacity: leftPill.canToggle ? 1 : 0.35
                    }
                    MouseArea {
                        id: playMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: leftPill.canToggle
                        onClicked: leftPill.isPlaying ? leftPill.player.pause() : leftPill.player.play()
                    }
                }

                Item {
                    width: 26
                    height: 26
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: nextMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: nextIconComp
                        opacity: leftPill.canNext ? 1 : 0.35
                    }
                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: leftPill.canNext
                        onClicked: leftPill.player.next()
                    }
                }
            }

        }
    }

    Rectangle {
        id: rightPill
        anchors {
            verticalCenter: centerPill.verticalCenter
            left: centerPill.right
            leftMargin: 16
        }
        height: 64
        radius: height / 2
        color: Colors.md3.surface_container
        implicitWidth: rightRow.implicitWidth + 20

        RowLayout {
            id: rightRow
            anchors.centerIn: parent
            spacing: 12

            GridLayout {
                id: statusGrid
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 10
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                WifiIcon {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    iconSize: 15
                    color: Colors.md3.on_surface_variant
                    mode: NetworkService.ethConnected ? "ethernet" : (NetworkService.wifiConnected ? "wifi" : "disconnected")
                    strength: NetworkService.wifiSignal
                    secured: root.netSecured
                }

                BluetoothIcon {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    iconSize: 15
                    color: Colors.md3.on_surface_variant
                    enabled: BluetoothService.enabled
                    connected: BluetoothService.connectedCount > 0
                    discovering: BluetoothService.discovering
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    width: 18
                    height: 18

                    Loader {
                        id: notifIconLoader
                        anchors.centerIn: parent
                        sourceComponent: NotificationService.dnd
                            ? dndIconComp
                            : (root.notifCount > 0 ? notifBellIconFilledComp : notifBellIconComp)
                    }

                    Rectangle {
                        id: notifBadge
                        visible: root.notifCount > 0
                        width: Math.max(14, badgeText.implicitWidth + 6)
                        height: 14
                        radius: 7
                        color: Colors.md3.primary
                        anchors {
                            top: parent.top
                            right: parent.right
                            topMargin: -4
                            rightMargin: -6
                        }

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: root.notifCount > 9 ? "9+" : String(root.notifCount)
                            color: Colors.md3.on_primary
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    width: 18
                    height: 18

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: root.capsLockOn ? capsLockIconFilledComp : capsLockIconComp
                    }
                }
            }

            BatteryIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: root.hasBattery
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 26
                color: Colors.md3.outline_variant
                opacity: 0.6
            }

            Row {
                id: powerButtonsRow
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                Repeater {
                    model: root.powerEntries

                    delegate: Item {
                        id: powerBtn
                        required property var modelData
                        width: 44
                        height: 44

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: powerBtn.modelData.bg
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: powerBtn.modelData.on
                            opacity: powerMa.containsMouse ? 0.10 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Loader {
                            id: powerIconLoader
                            anchors.centerIn: parent
                            sourceComponent: powerBtn.modelData.icon

                            Binding {
                                target: powerIconLoader.item
                                property: "color"
                                value: powerBtn.modelData.on
                                when: powerIconLoader.status === Loader.Ready && powerIconLoader.item && powerIconLoader.item.hasOwnProperty("color")
                            }
                        }

                        MouseArea {
                            id: powerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerProc.command = powerBtn.modelData.command;
                                powerProc.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
