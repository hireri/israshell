import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Wayland

import qs.style
import qs.services

Item {
    id: root

    required property var panelWindow

    implicitWidth: button.width
    height: button.height

    property bool isOpen: false
    property bool _sidebarVisible: false

    onIsOpenChanged: {
        if (isOpen) {
            _sidebarVisible = true;
        } else {
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: 310
        onTriggered: if (!root.isOpen)
            root._sidebarVisible = false
    }

    GlobalShortcut {
        name: "openQuickSettings"
        description: "Toggle quick settings sidebar"
        onPressed: {
            const screen = root.panelWindow.screen;
            if (!screen)
                return;
            if (Hyprland.focusedMonitor?.name !== screen.name)
                return;
            root.isOpen = !root.isOpen;
            if (root.isOpen)
                NotificationService.sendAllToPanel();
        }
    }

    function getDndIcon() {
        return NotificationService.dnd ? "󰂠" : "󰂞";
    }

    function getNetworkIcon() {
        if (NetworkService.ethConnected)
            return "󰌗";
        if (!NetworkService.wifiEnabled)
            return "󰤮";
        if (!NetworkService.wifiConnected)
            return "󰤫";
        if (NetworkService.wifiSignal >= 80)
            return "󰤨";
        if (NetworkService.wifiSignal >= 75)
            return "󰤥";
        if (NetworkService.wifiSignal >= 50)
            return "󰤢";
        if (NetworkService.wifiSignal >= 25)
            return "󰤟";
        return "󰤯";
    }

    function getBluetoothIcon() {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter?.enabled)
            return "󰂲";
        const devices = Bluetooth.devices.values;
        if (adapter.discovering || devices.some(d => d.connecting))
            return "󰂰";
        if (devices.some(d => d.connected))
            return "󰂱";
        return "󰂯";
    }

    Process {
        id: infoProc
        command: ["sh", "-c", "hostname; uptime -p"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                if (lines.length >= 2) {
                    hostText.text = lines[0] + " · " + lines[1].replace("up ", "").replace(" hours", "h").replace(" hour", "h").replace(" minutes", "m").replace(" minute", "m");
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: root.isOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: infoProc.running = true
    }

    Rectangle {
        id: button
        color: root.isOpen ? Colors.md3.secondary_container : (Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high)
        radius: 18
        implicitWidth: btnRow.implicitWidth + 10
        height: 32

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 0
            leftPadding: (Bluetooth.defaultAdapter?.enabled || AudioService.muted || CaffeineService.active || NightLightService.active || NotificationService.dnd) ? 5 : 2

            StatusIcon {
                active: true
                icon: root.getNetworkIcon()
            }
            StatusIcon {
                active: Bluetooth.defaultAdapter?.enabled ?? false
                icon: root.getBluetoothIcon()
            }
            StatusIcon {
                active: AudioService.muted
                icon: "󰝟"
                iconColor: Colors.md3.error
            }
            StatusIcon {
                active: CaffeineService.active
                icon: "󰅶"
            }
            StatusIcon {
                active: NightLightService.active
                icon: "󱩌"
            }
            StatusIcon {
                active: NotificationService.dnd
                icon: "󰂠"
            }

            Rectangle {
                implicitWidth: (Bluetooth.defaultAdapter?.enabled || AudioService.muted || CaffeineService.active || NightLightService.active || NotificationService.dnd) ? 12 : 0
                height: 14
                color: "transparent"
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 14
                    color: root.isOpen ? Colors.md3.on_secondary_container : Colors.md3.outline_variant
                    opacity: root.isOpen ? 0.3 : 0.7

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
            }

            Item {
                implicitWidth: 26
                height: 24

                Rectangle {
                    anchors.centerIn: parent
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: Colors.md3.primary_container
                    visible: btnProfileImage.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: Quickshell.env("USER").charAt(0).toUpperCase()
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.family: Config.fontFamily
                        color: Colors.md3.on_primary_container
                    }
                }

                ClippingRectangle {
                    anchors.centerIn: parent
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    clip: true
                    layer.enabled: true
                    layer.smooth: true
                    antialiasing: true
                    visible: btnProfileImage.status === Image.Ready
                    color: "transparent"

                    Image {
                        id: btnProfileImage
                        source: "file://" + Quickshell.env("HOME") + "/.face"
                        anchors.fill: parent
                        sourceSize: Qt.size(40, 40)
                        fillMode: Image.PreserveAspectCrop
                        antialiasing: true
                        smooth: true
                        cache: false
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.isOpen = !root.isOpen;
                if (root.isOpen)
                    NotificationService.sendAllToPanel();
            }
        }
    }

    HyprlandFocusGrab {
        windows: [sidebarLoader.item]
        active: root.isOpen && sidebarLoader.active
        onCleared: root.isOpen = false
    }
    LazyLoader {
        id: sidebarLoader
        active: root._sidebarVisible

        PopupWindow {
            id: sidebar
            anchor.window: root.panelWindow
            anchor.rect.x: (root.panelWindow.screen?.width ?? 1920) - implicitWidth
            anchor.rect.y: root.panelWindow.height + 12
            implicitWidth: 432
            anchor.adjustment: PopupAdjustment.None
            implicitHeight: Math.round((root.panelWindow.screen?.height ?? 1080) * 0.75)
            color: "transparent"
            visible: root._sidebarVisible

            Keys.onEscapePressed: root.isOpen = false

            property bool _ready: false
            Component.onCompleted: Qt.callLater(() => _ready = true)

            property real slideX: (_ready && root.isOpen) ? 0 : 452

            Behavior on slideX {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on slideX {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: sidebarCard
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 12
                width: 420

                radius: 18
                color: Colors.md3.surface_container_low
                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)
                border.width: 1
                clip: true

                transform: Translate {
                    x: sidebar.slideX
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: userRow.implicitHeight + 28
                        color: Colors.md3.surface_container
                        radius: 24

                        RowLayout {
                            id: userRow
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            Item {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 22
                                    color: Colors.md3.primary_container

                                    Text {
                                        anchors.centerIn: parent
                                        text: Quickshell.env("USER").charAt(0).toUpperCase()
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                        font.family: Config.fontFamily
                                        color: Colors.md3.on_primary_container
                                        visible: profileImage.status !== Image.Ready
                                    }
                                }

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: 22
                                    clip: true
                                    layer.enabled: true
                                    layer.smooth: true
                                    antialiasing: true
                                    visible: profileImage.status === Image.Ready
                                    color: "transparent"

                                    Image {
                                        id: profileImage
                                        source: "file://" + Quickshell.env("HOME") + "/.face"
                                        anchors.fill: parent
                                        sourceSize: Qt.size(144, 144)
                                        fillMode: Image.PreserveAspectCrop
                                        antialiasing: true
                                        smooth: true
                                        mipmap: true
                                        cache: false
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: Quickshell.env("USER")
                                    color: Colors.md3.on_surface
                                    font.family: Config.fontFamily
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    id: hostText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: "loading..."
                                    color: Colors.md3.on_surface_variant
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 12
                                color: editMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰏫"
                                    font.pixelSize: 15
                                    font.family: Config.fontFamily
                                    color: editMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                                }

                                MouseArea {
                                    id: editMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        root.isOpen = false;
                                        sysProc.command = ["code", Quickshell.env("HOME") + "/.config/hypr"];
                                        sysProc.running = true;
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 12
                                color: pwrMouse.containsMouse ? Colors.md3.error : Colors.md3.error_container

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐥"
                                    font.pixelSize: 17
                                    font.family: Config.fontFamily
                                    color: pwrMouse.containsMouse ? Colors.md3.on_error : Colors.md3.error
                                }
                                MouseArea {
                                    id: pwrMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        root.isOpen = false;
                                        onClicked: PowerMenuState.toggle();
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: qsCol.implicitHeight + 28
                        color: Colors.md3.surface_container
                        radius: 24

                        ColumnLayout {
                            id: qsCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                QsToggleChip {
                                    icon: root.getNetworkIcon()
                                    active: NetworkService.wifiEnabled || NetworkService.ethConnected
                                    onToggled: NetworkService.toggle()
                                    onRightClicked: {
                                        root.isOpen = false;
                                        appletProc.environment = {
                                            "QS_PAGE": "network"
                                        };
                                        appletProc.command = ["qs", "-n", "-p", Quickshell.env("HOME") + "/.config/quickshell/settings.qml"];
                                        appletProc.running = true;
                                    }
                                }

                                QsToggleChip {
                                    icon: root.getBluetoothIcon()
                                    active: Bluetooth.defaultAdapter?.enabled ?? false
                                    onToggled: if (Bluetooth.defaultAdapter)
                                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                    onRightClicked: {
                                        root.isOpen = false;
                                        appletProc.environment = {
                                            "QS_PAGE": "network"
                                        };
                                        appletProc.command = ["qs", "-n", "-p", Quickshell.env("HOME") + "/.config/quickshell/settings.qml"];
                                        appletProc.running = true;
                                    }
                                }

                                QsToggleChip {
                                    icon: CaffeineService.active ? "󰅶" : "󰾪"
                                    active: CaffeineService.active
                                    onToggled: CaffeineService.toggle()
                                }

                                QsToggleChip {
                                    icon: NightLightService.active ? "󱩌" : "󰛨"
                                    active: NightLightService.active
                                    onToggled: NightLightService.toggle()
                                }
                            }

                            QsSliderRow {
                                Layout.fillWidth: true
                                value: AudioService.volume
                                onMoved: val => AudioService.setVolume(val)
                                onMuteClicked: AudioService.toggleMute()
                                onRightClicked: {
                                    root.isOpen = false;
                                    appletProc.environment = {
                                        "QS_PAGE": "sound"
                                    };
                                    appletProc.command = ["qs", "-n", "-p", Quickshell.env("HOME") + "/.config/quickshell/settings.qml"];
                                    appletProc.running = true;
                                }
                                dimmed: AudioService.muted
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            color: Colors.md3.surface_container

                            topRightRadius: 22
                            topLeftRadius: 22

                            RowLayout {
                                anchors.fill: parent
                                anchors {
                                    leftMargin: 8
                                    rightMargin: 8
                                    topMargin: 8
                                    bottomMargin: 0
                                }
                                spacing: 4

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.fillHeight: true
                                    radius: 10
                                    topLeftRadius: 18
                                    color: dndMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.getDndIcon()
                                        font.pixelSize: 16
                                        font.family: Config.fontFamily
                                        color: Colors.md3.on_surface
                                    }

                                    MouseArea {
                                        id: dndMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: NotificationService.dnd = !NotificationService.dnd
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 10
                                    color: Colors.md3.surface_container_high

                                    Text {
                                        anchors.centerIn: parent
                                        text: NotificationService.qsGroupModel.count === 0 ? "No notifications" : NotificationService.qsGroupModel.count + " notification" + (NotificationService.qsGroupModel.count === 1 ? "" : "s")
                                        font.pixelSize: 13
                                        font.family: Config.fontFamily
                                        font.weight: Font.Medium
                                        color: Colors.md3.on_surface
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.fillHeight: true
                                    radius: 10
                                    topRightRadius: 18
                                    color: clearMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                                    opacity: NotificationService.qsGroupModel.count > 0 ? 1 : 0.3

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰩹"
                                        font.pixelSize: 16
                                        font.family: Config.fontFamily
                                        color: Colors.md3.on_surface
                                    }

                                    MouseArea {
                                        id: clearMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        enabled: NotificationService.qsGroupModel.count > 0
                                        onClicked: NotificationService.dismissAll()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 24
                            topRightRadius: 0
                            topLeftRadius: 0
                            color: Colors.md3.surface_container
                            clip: true

                            Column {
                                anchors.centerIn: parent
                                spacing: 12
                                visible: NotificationService.qsGroupModel.count === 0

                                Rectangle {
                                    implicitWidth: 200
                                    implicitHeight: 80
                                    radius: 24
                                    color: Colors.md3.primary_container

                                    Text {
                                        anchors.centerIn: parent
                                        text: "(˶˃ ᵕ ˂˶) .ᐟ.ᐟ"
                                        font.pixelSize: 32
                                        color: Colors.md3.on_primary_container
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "All caught up . . !"
                                    font.pixelSize: 16
                                    font.family: Config.fontFamily
                                    color: Colors.md3.on_surface_variant
                                    opacity: 0.8
                                }
                            }

                            Flickable {
                                id: qsFlick
                                anchors.fill: parent
                                anchors.margins: 8
                                contentHeight: notifCol.implicitHeight
                                clip: false
                                flickableDirection: Flickable.VerticalFlick
                                flickDeceleration: 4000
                                maximumFlickVelocity: 1200
                                boundsBehavior: Flickable.DragAndOvershootBounds
                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AlwaysOff
                                }

                                Column {
                                    id: notifCol
                                    width: qsFlick.width
                                    spacing: 6

                                    NotificationListView {
                                        id: qsNotifList
                                        width: parent.width
                                        implicitHeight: contentHeight
                                        height: contentHeight

                                        model: NotificationService.qsGroupModel

                                        delegate: NotificationGroup {
                                            required property int index
                                            readonly property var row: qsNotifList.model.get(index) ?? {}
                                            appName: row.appName ?? ""
                                            groupSummary: row.groupSummary ?? ""
                                            groupIdx: index
                                            listRef: qsNotifList
                                            showAll: true
                                            inPanel: true
                                            popup: false
                                            width: qsNotifList.width
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: appletProc
    }
    Process {
        id: sysProc
    }
    Process {
        id: settingsProc
    }

    component QsToggleChip: Rectangle {
        id: chip
        property string icon: ""
        property bool active: false
        signal toggled
        signal rightClicked

        Layout.fillWidth: true
        Layout.preferredHeight: 52

        radius: active ? 18 : 14
        color: {
            if (active)
                return Colors.md3.primary;
            if (hovered)
                return Colors.md3.surface_container_highest;
            return Colors.md3.surface_container_high;
        }

        property bool hovered: mouseArea.containsMouse

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.centerIn: parent
            text: chip.icon
            font.pixelSize: 22
            font.family: Config.fontFamily
            color: chip.active ? Colors.md3.on_primary : Colors.md3.on_surface_variant
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onClicked: mouse => mouse.button === Qt.RightButton ? chip.rightClicked() : chip.toggled()
        }
    }

    component QsSliderRow: Item {
        id: sliderRow
        property real value: 0
        property real from: 0
        property real to: 1.5
        property bool dimmed: false
        signal moved(real val)
        signal muteClicked
        signal rightClicked
        property real _dragRatio: -1
        property real _displayRatio: _dragRatio >= 0 ? _dragRatio : ((to - from > 0) ? (value - from) / (to - from) : 0)

        Layout.fillWidth: true
        Layout.preferredHeight: 52

        Rectangle {
            id: trackBg
            anchors.fill: parent
            radius: 14
            color: Colors.md3.surface_container_high

            Rectangle {
                id: trackFill
                x: 4
                y: 4
                height: parent.height - 8
                radius: 10
                readonly property real minW: height
                readonly property real usable: trackBg.width - 8 - minW
                implicitWidth: minW + sliderRow._displayRatio * usable
                color: sliderRow.dimmed ? Colors.md3.outline : (sliderRow.value > 1.005 ? Colors.md3.error : Colors.md3.primary)

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: sliderRow._dragRatio >= 0 ? 0 : 150
                        easing.type: Easing.OutQuart
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 75
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: sliderRow.dimmed ? "󰝟" : (sliderRow.value > 1.0 ? "󱄡" : (sliderRow.value < 0.33 ? "󰕿" : (sliderRow.value < 0.66 ? "󰖀" : "󰕾")))
                    font.pixelSize: 20
                    font.family: Config.fontFamily
                    color: sliderRow.dimmed ? Colors.md3.surface_container_highest : (sliderRow.value > 1.0 ? Colors.md3.on_error : Colors.md3.on_primary)
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(sliderRow.value * 100) + "%"
                font.pixelSize: 13
                font.bold: true
                font.family: Config.fontFamily
                color: {
                    if (trackFill.width > (parent.width - 50)) {
                        if (sliderRow.dimmed)
                            return Colors.md3.surface_container_highest;
                        return sliderRow.value > 1.0 ? Colors.md3.on_error : Colors.md3.on_primary;
                    }
                    return Colors.md3.on_surface_variant;
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                property bool dragStarted: false
                property real startX: 0

                onWheel: wheel => sliderRow.moved(wheel.angleDelta.y > 0 ? Math.min(sliderRow.to, sliderRow.value + 0.05) : Math.max(sliderRow.from, sliderRow.value - 0.05))
                onPressed: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        sliderRow.rightClicked();
                        return;
                    }
                    if (mouse.button === Qt.MiddleButton) {
                        sliderRow.muteClicked();
                        return;
                    }
                    startX = mouse.x;
                    dragStarted = false;
                }

                onPositionChanged: mouse => {
                    if (!pressed || mouse.button === Qt.MiddleButton)
                        return;
                    if (Math.abs(mouse.x - startX) > 4)
                        dragStarted = true;
                    if (dragStarted) {
                        let ratio = Math.max(0, Math.min(1, (mouse.x - (4 + trackFill.minW / 2)) / (trackBg.width - 8 - trackFill.minW)));
                        sliderRow._dragRatio = ratio;
                        sliderRow.moved(sliderRow.from + ratio * (sliderRow.to - sliderRow.from));
                    }
                }

                onReleased: mouse => {
                    if (mouse.button === Qt.MiddleButton)
                        return;
                    if (!dragStarted) {
                        if (startX <= 48)
                            sliderRow.muteClicked();
                        else {
                            let ratio = Math.max(0, Math.min(1, (mouse.x - (4 + trackFill.minW / 2)) / (trackBg.width - 8 - trackFill.minW)));
                            sliderRow.moved(sliderRow.from + ratio * (sliderRow.to - sliderRow.from));
                        }
                    }

                    sliderRow._dragRatio = -1;
                }
            }
        }
    }

    component StatusIcon: Item {
        property bool active: true
        property string icon: ""
        property color iconColor: root.isOpen ? Colors.md3.on_secondary_container : Colors.md3.on_surface

        implicitWidth: active ? 26 : 0
        height: 24
        clip: true
        opacity: active ? 1 : 0
        scale: active ? 1 : 0.4

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutBack
            }
        }

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: Config.fontFamily
            font.pixelSize: 16
            color: parent.iconColor
        }
    }
}
