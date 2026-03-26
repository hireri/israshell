import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

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

    Connections {
        target: Hyprland
        function onActiveMonitorChanged() {
            root.isOpen = false;
        }
        function onActiveWindowChanged() {
            root.isOpen = false;
        }
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
            spacing: 6

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
        anchor.rect.x: root.panelWindow.width - width - 8
        anchor.rect.y: root.panelWindow.height + 8

        width: 280
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

                Text {
                    text: "Quick Settings"
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    leftPadding: 4
                    topPadding: 4
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
                                if (NetworkService.wifiSignal >= 50)
                                    return "󰤥";
                                if (NetworkService.wifiSignal >= 25)
                                    return "󰤢";
                                return "󰤟";
                            })()
                        active: NetworkService.wifiEnabled || NetworkService.ethConnected
                        onToggled: NetworkService.toggle()
                        onRightClicked: {
                            root.isOpen = false;
                            appletProc.command = ["kitty", "-e", "nmtui"];
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
                    from: 0.0
                    to: 1.5
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

    component QsToggleChip: Rectangle {
        id: chip
        property string icon: ""
        property bool active: false
        signal toggled
        signal rightClicked

        width: (contentCol.width - 24) / 4
        height: 48
        radius: active ? 16 : 12
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
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton)
                    chip.rightClicked();
                else
                    chip.toggled();
            }
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

        height: 48

        Rectangle {
            id: trackBg
            anchors.fill: parent
            radius: 12
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

                color: {
                    if (sliderRow.dimmed)
                        return Colors.md3.outline;
                    if (sliderRow.value > 1.0)
                        return Colors.md3.error;
                    return Colors.md3.primary;
                }

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
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (sliderRow.dimmed)
                            return "󰝟";
                        if (sliderRow.value <= 0.01)
                            return "󰕿";
                        if (sliderRow.value < 0.5)
                            return "󰖀";
                        return "󰕾";
                    }
                    font.pixelSize: 20
                    font.family: Config.fontFamily
                    color: {
                        if (sliderRow.dimmed)
                            return Colors.md3.surface_container_highest;
                        if (sliderRow.value > 1.0)
                            return Colors.md3.on_error;
                        return Colors.md3.on_primary;
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 75
                        }
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(sliderRow.value * 100) + "%"
                font.pixelSize: 14
                font.bold: true
                font.family: Config.fontFamily

                color: {
                    if (trackFill.width > (parent.width - 50)) {
                        if (sliderRow.dimmed)
                            return Colors.md3.surface_container_highest;
                        if (sliderRow.value > 1.0)
                            return Colors.md3.on_error;
                        return Colors.md3.on_primary;
                    }
                    return Colors.md3.on_surface_variant;
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 75
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                property bool dragStarted: false
                property real startX: 0

                onWheel: function (wheel) {
                    let step = 0.05 * (sliderRow.to - sliderRow.from);
                    if (wheel.angleDelta.y > 0) {
                        sliderRow.moved(Math.min(sliderRow.to, sliderRow.value + step));
                    } else {
                        sliderRow.moved(Math.max(sliderRow.from, sliderRow.value - step));
                    }
                }

                onPressed: function (mouse) {
                    startX = mouse.x;
                    dragStarted = false;
                }

                onPositionChanged: function (mouse) {
                    if (!pressed)
                        return;
                    if (Math.abs(mouse.x - startX) > 4)
                        dragStarted = true;

                    if (dragStarted) {
                        let startXPos = 4 + trackFill.minW / 2;
                        let dragSpace = trackBg.width - 8 - trackFill.minW;
                        let ratio = Math.max(0, Math.min(1, (mouse.x - startXPos) / dragSpace));
                        sliderRow._dragRatio = ratio;
                        sliderRow.moved(sliderRow.from + ratio * (sliderRow.to - sliderRow.from));
                    }
                }

                onReleased: function (mouse) {
                    if (!dragStarted) {
                        if (startX <= 48) {
                            sliderRow.muteClicked();
                        } else {
                            let startXPos = 4 + trackFill.minW / 2;
                            let dragSpace = trackBg.width - 8 - trackFill.minW;
                            let ratio = Math.max(0, Math.min(1, (mouse.x - startXPos) / dragSpace));
                            sliderRow.moved(sliderRow.from + ratio * (sliderRow.to - sliderRow.from));
                        }
                    }
                    sliderRow._dragRatio = -1;
                }
            }
        }
    }
}
