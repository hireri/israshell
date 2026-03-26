import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import QtQuick.Effects
import Quickshell.Widgets

import qs.style
import qs.services

Item {
    id: root

    required property var panelWindow

    implicitWidth: button.width
    height: button.height

    property bool isOpen: false

    function getNetworkIcon() {
        if (NetworkService.ethConnected)
            return "󰌗";
        if (!NetworkService.wifiEnabled)
            return "󰤭";
        if (!NetworkService.wifiConnected)
            return "󰤯";
        if (NetworkService.wifiSignal >= 75)
            return "󰤨";
        return "󰤟";
    }

    function getBluetoothIcon() {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter?.enabled)
            return "󰂲";

        const devices = Bluetooth.devices.values;

        const isConnecting = devices.some(d => d.connecting);

        if (adapter.discovering || isConnecting)
            return "󰂰";

        if (devices.some(d => d.connected))
            return "󰂱";

        return "󰂯";
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [drawer]
        active: root.isOpen
        onCleared: root.isOpen = false
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
        radius: 12
        implicitWidth: btnRow.implicitWidth + 20
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

            Rectangle {
                implicitWidth: ((Bluetooth.defaultAdapter?.enabled) || AudioService.muted || CaffeineService.active || NightLightService.active) ? 12 : 0
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
                    opacity: 0.3
                }
            }

            Item {
                implicitWidth: 26
                height: 24
                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    font.family: Config.fontFamily
                    font.pixelSize: 16
                    color: root.isOpen ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isOpen = !root.isOpen
        }
    }

    PopupWindow {
        id: drawer
        anchor.window: root.panelWindow
        anchor.rect.x: root.panelWindow.width - implicitWidth - 12
        anchor.rect.y: root.panelWindow.height + 12
        implicitWidth: 320
        height: contentCol.implicitHeight + 24
        visible: drawerContent.opacity > 0
        color: "transparent"

        Rectangle {
            id: drawerContent
            anchors.fill: parent
            radius: 16
            color: Colors.md3.surface_container_high
            border.color: Colors.md3.outline_variant
            border.width: 1
            opacity: root.isOpen ? 1 : 0
            scale: 0.95 + (opacity * 0.05)
            transformOrigin: Item.TopRight

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }

            ColumnLayout {
                id: contentCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: Colors.md3.primary_container

                        Text {
                            anchors.centerIn: parent
                            text: Quickshell.env("USER").charAt(0).toUpperCase()
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            font.family: Config.fontFamily
                            color: Colors.md3.on_primary_container
                            visible: profileImage.status !== Image.Ready
                        }

                        Rectangle {
                            id: maskRect
                            anchors.fill: parent
                            radius: 18
                            antialiasing: true
                            visible: false
                            layer.enabled: true
                            layer.samples: 4
                        }

                        Image {
                            id: profileImage
                            source: "file://" + Quickshell.env("HOME") + "/.face"
                            anchors.fill: parent

                            sourceSize: Qt.size(144, 144)

                            fillMode: Image.PreserveAspectCrop
                            antialiasing: true
                            smooth: true
                            mipmap: true
                            visible: false
                            cache: false
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: profileImage
                            maskEnabled: true
                            maskSource: maskRect
                            visible: profileImage.status === Image.Ready
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
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Text {
                            id: hostText
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: "loading..."
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 12
                        antialiasing: true

                        color: editMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container

                        scale: editMouse.pressed ? 0.92 : 1

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
                            font.pixelSize: 14
                            font.family: Config.fontFamily
                            color: editMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                        }
                        MouseArea {
                            id: editMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                sysProc.command = ["code", Quickshell.env("HOME") + "/.config/hypr"];
                                sysProc.running = true;
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 12
                        antialiasing: true

                        color: pwrMouse.containsMouse ? Colors.md3.error : Colors.md3.on_error

                        scale: pwrMouse.pressed ? 0.92 : 1

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
                            font.pixelSize: 16
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
                                sysProc.command = ["wlogout", "-p", "layer-shell"];
                                sysProc.running = true;
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.5
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    QsToggleChip {
                        icon: root.getNetworkIcon()
                        active: NetworkService.wifiEnabled || NetworkService.ethConnected
                        onToggled: NetworkService.toggle()
                        onRightClicked: {
                            root.isOpen = false;
                            appletProc.command = ["nm-connection-editor"];
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
                            appletProc.command = ["blueman-manager"];
                            appletProc.running = true;
                        }
                    }

                    QsToggleChip {
                        icon: CaffeineService.active ? "󰅶" : "󰾪"
                        active: CaffeineService.active
                        onToggled: CaffeineService.toggle()
                    }

                    QsToggleChip {
                        icon: NightLightService.active ? "󱩌" : "󱩍"
                        active: NightLightService.active
                        onToggled: NightLightService.toggle()
                    }
                }

                QsSliderRow {
                    value: AudioService.volume
                    onMoved: function (val) {
                        AudioService.setVolume(val);
                    }
                    onMuteClicked: AudioService.toggleMute()
                    dimmed: AudioService.muted
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
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

    component QsToggleChip: Rectangle {
        id: chip
        property string icon: ""
        property bool active: false
        signal toggled
        signal rightClicked

        Layout.fillWidth: true
        Layout.preferredHeight: 52

        radius: active ? 18 : 14
        color: active ? Colors.md3.primary : Colors.md3.surface_container
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
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
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
        property real _dragRatio: -1
        property real _displayRatio: _dragRatio >= 0 ? _dragRatio : ((to - from > 0) ? (value - from) / (to - from) : 0)

        Layout.fillWidth: true
        Layout.preferredHeight: 52

        Rectangle {
            id: trackBg
            anchors.fill: parent
            radius: 14
            color: Colors.md3.surface_container

            Rectangle {
                id: trackFill
                x: 4
                y: 4
                height: parent.height - 8
                radius: 10
                readonly property real minW: height
                readonly property real usable: trackBg.width - 8 - minW
                implicitWidth: minW + sliderRow._displayRatio * usable
                color: sliderRow.dimmed ? Colors.md3.outline : (sliderRow.value > 1.0 ? Colors.md3.error : Colors.md3.primary)

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
                    text: sliderRow.dimmed ? "󰝟" : (sliderRow.value <= 0.01 ? "󰕿" : (sliderRow.value < 0.5 ? "󰖀" : "󰕾"))
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
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                property bool dragStarted: false
                property real startX: 0

                onWheel: wheel => sliderRow.moved(wheel.angleDelta.y > 0 ? Math.min(sliderRow.to, sliderRow.value + 0.05) : Math.max(sliderRow.from, sliderRow.value - 0.05))
                onPressed: mouse => {
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
