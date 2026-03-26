import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets

import qs.style
import qs.services

Item {
    id: root

    required property var panelWindow

    width: button.width
    height: button.height

    property bool isOpen: false

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
                    hostText.text = lines[0] + " • " + lines[1].replace("up ", "");
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
        width: btnRow.implicitWidth + 20
        height: 32

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰒓"
                color: root.isOpen ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                font.pixelSize: 16
                font.family: Config.fontFamily
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Settings"
                color: root.isOpen ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
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
        anchor.rect.x: root.panelWindow.width - width - 12
        anchor.rect.y: root.panelWindow.height + 12
        width: 320
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

            Column {
                id: contentCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                }
                spacing: 12

                Rectangle {
                    width: parent.width
                    height: 128
                    color: Colors.md3.surface_container
                    radius: 10

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: Quickshell.env("USER")
                                    color: Colors.md3.on_surface
                                    font.family: Config.fontFamily
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    id: hostText
                                    Layout.fillWidth: true
                                    text: "Loading..."
                                    color: Colors.md3.on_surface_variant
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                }
                            }

                            IconButton {
                                icon: "󰏫"
                                onClicked: {
                                    sysProc.command = ["code", Quickshell.env("HOME") + "/.config/hypr"];
                                    sysProc.running = true;
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            PowerButton {
                                icon: "󰌾"
                                Layout.fillWidth: true
                                onClicked: {
                                    sysProc.command = ["hyprctl", "dispatch", "exit"];
                                    sysProc.running = true;
                                }
                            }
                            PowerButton {
                                icon: "󰤄"
                                Layout.fillWidth: true
                                onClicked: {
                                    sysProc.command = ["systemctl", "suspend"];
                                    sysProc.running = true;
                                }
                            }
                            PowerButton {
                                icon: "󰜉"
                                Layout.fillWidth: true
                                onClicked: {
                                    sysProc.command = ["systemctl", "reboot"];
                                    sysProc.running = true;
                                }
                            }
                            PowerButton {
                                icon: ""
                                primary: true
                                Layout.fillWidth: true
                                onClicked: {
                                    sysProc.command = ["systemctl", "poweroff"];
                                    sysProc.running = true;
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    QsToggleChip {
                        icon: (function () {
                                if (NetworkService.ethConnected)
                                    return "󰌗";
                                if (!NetworkService.wifiEnabled)
                                    return "󰤭";
                                if (!NetworkService.wifiConnected)
                                    return "󰤯";
                                if (NetworkService.wifiSignal >= 75)
                                    return "󰤨";
                                return "󰤟";
                            })()
                        active: NetworkService.wifiEnabled || NetworkService.ethConnected
                        onToggled: NetworkService.toggle()
                        onRightClicked: {
                            root.isOpen = false;
                            appletProc.command = ["nm-connection-editor"];
                            appletProc.running = true;
                        }
                    }

                    QsToggleChip {
                        icon: BluetoothService.bluetoothEnabled ? "󰂯" : "󰂲"
                        active: BluetoothService.bluetoothEnabled
                        onToggled: BluetoothService.toggle()
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
                    width: parent.width
                    value: AudioService.volume
                    onMoved: function (val) {
                        AudioService.setVolume(val);
                    }
                    onMuteClicked: AudioService.toggleMute()
                    dimmed: AudioService.muted
                }

                Item {
                    width: 1
                    height: 4
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

    component IconButton: Rectangle {
        property string icon: ""
        signal clicked
        width: 32
        height: 48
        radius: 16
        color: "transparent"
        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.pixelSize: 18
            font.family: Config.fontFamily
            color: Colors.md3.on_surface_variant
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: parent.color = Colors.md3.surface_container_highest
            onExited: parent.color = "transparent"
            onClicked: parent.clicked()
        }
    }

    component PowerButton: Rectangle {
        property string icon: ""
        property bool primary: false
        signal clicked
        height: 36
        radius: 12
        color: primary ? Colors.md3.error_container : Colors.md3.surface_container_highest

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.pixelSize: 18
            font.family: Config.fontFamily
            color: primary ? Colors.md3.on_error_container : Colors.md3.on_surface
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: if (!primary)
                parent.color = Colors.md3.outline_variant
            onExited: if (!primary)
                parent.color = Colors.md3.surface_container_highest
            onClicked: parent.clicked()
        }
    }

    component QsToggleChip: Rectangle {
        id: chip
        property string icon: ""
        property bool active: false
        signal toggled
        signal rightClicked
        width: (contentCol.width - 24) / 4
        height: 52
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
        height: 52
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
                width: minW + sliderRow._displayRatio * usable
                color: sliderRow.dimmed ? Colors.md3.outline : (sliderRow.value > 1.0 ? Colors.md3.error : Colors.md3.primary)
                Behavior on width {
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
                color: trackFill.width > (parent.width - 50) ? (sliderRow.value > 1.0 ? Colors.md3.on_error : Colors.md3.on_primary) : Colors.md3.on_surface_variant
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                property bool dragStarted: false
                property real startX: 0
                onWheel: wheel => sliderRow.moved(wheel.angleDelta.y > 0 ? Math.min(sliderRow.to, sliderRow.value + 0.05) : Math.max(sliderRow.from, sliderRow.value - 0.05))
                onPressed: mouse => {
                    startX = mouse.x;
                    dragStarted = false;
                }
                onPositionChanged: mouse => {
                    if (!pressed)
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
}
