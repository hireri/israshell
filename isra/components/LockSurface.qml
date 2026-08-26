import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import qs.services
import qs.style
import qs.icons

Item {
    id: root

    Component {
        id: previousIconComp
        MaterialIcon { name: "next-prev"; iconSize: 15; color: Colors.md3.on_surface }
    }
    Component {
        id: nextIconComp
        MaterialIcon { name: "next-prev"; iconSize: 15; color: Colors.md3.on_surface; filled: true }
    }
    Component {
        id: playIconComp
        MaterialIcon { name: "play-pause"; iconSize: 16; color: Colors.md3.on_surface }
    }
    Component {
        id: pauseIconComp
        MaterialIcon { name: "play-pause"; iconSize: 16; color: Colors.md3.on_surface; filled: true }
    }
    Component {
        id: musicNoteIconComp
        MaterialIcon { name: "music-note"; iconSize: 15; color: Colors.md3.on_surface_variant }
    }
    Component {
        id: arrowRightIconComp
        MaterialIcon { name: "arrow-forward"; iconSize: 18 }
    }
    Component {
        id: logoutIconComp
        MaterialIcon { name: "logout"; iconSize: 18 }
    }
    Component {
        id: restartIconComp
        MaterialIcon { name: "reboot"; iconSize: 18 }
    }
    Component {
        id: powerIconComp
        MaterialIcon { name: "shutdown"; iconSize: 18 }
    }

    Component {
        id: notifBellIconComp
        MaterialIcon { name: "notifications"; iconSize: 16; color: Colors.md3.on_surface_variant }
    }
    Component {
        id: notifBellIconFilledComp
        MaterialIcon { name: "notifications"; iconSize: 16; color: Colors.md3.on_surface_variant; filled: true }
    }
    Component {
        id: dndIconComp
        MaterialIcon { name: "dnd"; iconSize: 16; color: Colors.md3.on_surface_variant }
    }
    Component {
        id: capsLockIconComp
        MaterialIcon { name: "shift-lock"; iconSize: 16; color: Colors.md3.on_surface_variant }
    }
    Component {
        id: capsLockIconFilledComp
        MaterialIcon { name: "shift-lock"; iconSize: 16; color: Colors.md3.on_surface_variant; filled: true }
    }

    readonly property var dotMaterialShapes: ["clover4", "arrow", "pill", "softBurst", "diamond", "clamShell", "pentagon"]

    Component {
        id: dotSquareComp
        Rectangle {
            width: 16
            height: 16
            radius: 4
            color: Colors.md3.on_surface
        }
    }
    Component {
        id: dotCircleComp
        Rectangle {
            width: 16
            height: 16
            radius: 8
            color: Colors.md3.on_surface
        }
    }
    Component {
        id: dotMaterialComp
        MaterialShape {
            shapeSize: 16
            color: Colors.md3.on_surface
            random: true
            shapes: root.dotMaterialShapes
        }
    }

    component MarqueeLine: Item {
        id: marqueeLine

        property string label: ""
        property int fontPixelSize: 13
        property int fontWeight: Font.Normal
        property color textColor: Colors.md3.on_surface

        height: lineText.implicitHeight
        clip: true

        readonly property bool shouldScroll: lineText.implicitWidth > width
        property real scrollPos: 0

        onLabelChanged: {
            if (shouldScroll)
                marqueeAnim.restart();
            else {
                marqueeAnim.stop();
                scrollPos = 0;
            }
        }

        Component.onCompleted: {
            if (shouldScroll)
                marqueeAnim.restart();
        }

        NumberAnimation {
            id: marqueeAnim
            target: marqueeLine
            property: "scrollPos"
            from: 0
            to: lineText.implicitWidth + 24
            duration: (lineText.implicitWidth + 24) * 1000 / Config.carouselSpeed
            loops: Animation.Infinite
        }

        Text {
            id: lineText
            anchors.verticalCenter: parent.verticalCenter
            x: marqueeLine.shouldScroll ? -marqueeLine.scrollPos : (marqueeLine.width - implicitWidth) / 2
            color: marqueeLine.textColor
            font.pixelSize: marqueeLine.fontPixelSize
            font.weight: marqueeLine.fontWeight
            text: marqueeLine.label
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: lineText.x + lineText.implicitWidth + 24
            visible: marqueeLine.shouldScroll
            color: marqueeLine.textColor
            font.pixelSize: marqueeLine.fontPixelSize
            font.weight: marqueeLine.fontWeight
            text: lineText.text
        }

        Rectangle {
            anchors.left: parent.left
            width: 14
            height: parent.height
            visible: marqueeLine.shouldScroll
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
            visible: marqueeLine.shouldScroll
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Colors.md3.surface_container }
            }
        }
    }

    readonly property var powerEntries: [
        {
            label: Localization.t("lockSurface.log_out"),
            icon: logoutIconComp,
            command: ["sh", "-c", "loginctl terminate-user \"$USER\""],
            bg: Colors.md3.secondary_container,
            on: Colors.md3.on_secondary_container
        },
        {
            label: Localization.t("lockSurface.shut_down"),
            icon: powerIconComp,
            command: ["sh", "-c", "systemctl poweroff || loginctl poweroff"],
            bg: Colors.md3.primary_container,
            on: Colors.md3.on_primary_container
        },
        {
            label: Localization.t("lockSurface.restart"),
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

            const oldLen = passwordModel.count
            const newLen = text.length
            if (newLen > oldLen) {
                const insertCount = newLen - oldLen
                const insertAt = Math.max(0, Math.min(oldLen, cursorPosition - insertCount))
                for (let i = 0; i < insertCount; i++)
                    passwordModel.insert(insertAt + i, {})
            } else if (newLen < oldLen) {
                const removeCount = oldLen - newLen
                const removeAt = Math.max(0, Math.min(newLen, cursorPosition))
                for (let i = 0; i < removeCount; i++)
                    passwordModel.remove(removeAt)
            }

            textCursor.opacity = 1
            cursorBlinkAnim.restart()
        }

        onCursorPositionChanged: {
            dotListView.ensureCaretVisible()
            textCursor.opacity = 1
            cursorBlinkAnim.restart()
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
                SoundService.unlock();
                hiddenPasswordInput.text = ""
            }
            function onShowFailureChanged() {
                if (LockscreenService.showFailure) {
                    SoundService.unlockFail();
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

    readonly property bool hasBattery: BatteryService.hasBattery

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
                    antialiasing: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/.face"
                        sourceSize: Qt.size(44, 44)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
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
                    text: Localization.t("lockSurface.password")
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
                    cacheBuffer: 0

                    readonly property int dotW: 16
                    readonly property int dotSpacing: 6

                    function caretX(idx) {
                        return idx <= 0 ? 0 : idx * (dotW + dotSpacing) - dotSpacing
                    }

                    function caretCenterX(idx) {
                        return idx <= 0 ? 0 : idx * (dotW + dotSpacing) - dotSpacing / 2
                    }

                    function ensureCaretVisible() {
                        const caret = caretX(hiddenPasswordInput.cursorPosition)
                        let cx = contentX
                        if (caret < cx) cx = caret
                        else if (caret > cx + width) cx = caret - width
                        contentX = Math.max(0, Math.min(cx, Math.max(0, contentWidth - width)))
                    }

                    Behavior on contentX {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    onContentWidthChanged: ensureCaretVisible()

                    delegate: Item {
                        width: 16
                        height: dotListView.height

                        Loader {
                            id: dotVisual
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            sourceComponent: {
                                switch (Config.lockscreen.dotShape) {
                                case "circle": return dotCircleComp;
                                case "material": return dotMaterialComp;
                                default: return dotSquareComp;
                                }
                            }

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

                Rectangle {
                    id: textCursor
                    width: 2
                    height: 18
                    radius: 1
                    color: Colors.md3.on_surface
                    visible: hiddenPasswordInput.activeFocus && !LockscreenService.unlockInProgress
                    anchors.verticalCenter: dotListView.verticalCenter
                    x: {
                        const idx = hiddenPasswordInput.cursorPosition
                        const center = dotListView.caretCenterX(idx) - dotListView.contentX
                        const aligned = idx <= 0 ? center : center - textCursor.width / 2
                        const minX = dotListView.x
                        const maxX = dotListView.x + dotListView.width - textCursor.width
                        return Math.max(minX, Math.min(maxX, dotListView.x + aligned))
                    }

                    Behavior on x {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    SequentialAnimation {
                        id: cursorBlinkAnim
                        loops: Animation.Infinite
                        running: textCursor.visible

                        PauseAnimation { duration: 600 }
                        NumberAnimation { target: textCursor; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: 300 }
                        NumberAnimation { target: textCursor; property: "opacity"; to: 1; duration: 300; easing.type: Easing.InOutQuad }
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
        implicitWidth: leftRow.implicitWidth + 20

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
                width: 44
                height: 44

                readonly property bool showRing: leftPill.hasPlayer && (Config.bar.playerRing ?? false)
                readonly property bool hasArt: leftPill.hasPlayer && (leftPill.player.trackArtUrl ?? "") !== ""
                property real coverMargin: showRing ? 4 : 0
                property real ringStrokeWidth: showRing ? 2.6 : 0

                Behavior on coverMargin {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                Behavior on ringStrokeWidth {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                MprisProgress {
                    id: coverProgress
                    player: leftPill.player
                    active: root.visible
                }

                ProgressRing {
                    anchors.fill: parent
                    progress: coverProgress.progress
                    strokeWidth: coverArt.ringStrokeWidth
                    gapDegrees: 10
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: coverArt.coverMargin
                    radius: height / 2
                    color: Colors.md3.surface_container_highest

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: musicNoteIconComp
                        visible: !coverArt.hasArt
                    }
                }

                CrossfadeArt {
                    id: coverArtImg
                    anchors.fill: parent
                    anchors.margins: coverArt.coverMargin
                    radius: height / 2
                    antialiasing: true
                    url: leftPill.hasPlayer ? (leftPill.player.trackArtUrl ?? "") : ""
                    renderSize: Qt.size(72, 72)

                    property real angle: 0
                    property real velocity: leftPill.shouldSpin ? 0.5 : 0
                    rotation: angle

                    Behavior on velocity {
                        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                    }

                    Timer {
                        interval: 16
                        running: true
                        repeat: true
                        onTriggered: {
                            if (Math.abs(coverArtImg.velocity) > 0.001)
                                coverArtImg.angle = (coverArtImg.angle + coverArtImg.velocity) % 360;
                        }
                    }
                }
            }

            Column {
                id: marqueeContainer
                Layout.alignment: Qt.AlignVCenter
                width: 112
                spacing: 2

                MarqueeLine {
                    width: parent.width
                    label: leftPill.hasPlayer ? leftPill.player.trackTitle : Localization.t("mediaPlayer.no_media_playing")
                    fontPixelSize: 13
                    fontWeight: Font.Medium
                    textColor: Colors.md3.on_surface
                }

                MarqueeLine {
                    width: parent.width
                    visible: leftPill.hasPlayer && !!leftPill.player.trackArtist
                    label: leftPill.hasPlayer ? leftPill.player.trackArtist : ""
                    fontPixelSize: 12
                    textColor: Colors.md3.on_surface_variant
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

            MaterialIcon {
                name: "battery"
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
