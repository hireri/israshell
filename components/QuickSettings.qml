import QtQuick
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

    HyprlandFocusGrab {
        id: focusGrab
        windows: [drawer]
        active: drawer.visible
        onCleared: drawer.visible = false
    }

    Rectangle {
        id: button
        color: drawer.visible ? Colors.md3.secondary_container : (Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high)
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
                color: drawer.visible ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                font.pixelSize: 16
                font.family: Config.fontFamily
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Settings"
                color: drawer.visible ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: drawer.visible = !drawer.visible
        }
    }

    PopupWindow {
        id: drawer

        anchor.window: root.panelWindow
        anchor.rect.x: root.panelWindow.width - width - 8
        anchor.rect.y: root.panelWindow.height + 8

        width: 280
        height: contentCol.implicitHeight + 24
        visible: false
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Colors.md3.surface_container_high
            border.color: Colors.md3.outline_variant
            border.width: 1

            Column {
                id: contentCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                }
                spacing: 4

                Text {
                    text: "Quick Settings"
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    leftPadding: 4
                    topPadding: 4
                    bottomPadding: 2
                }

                Row {
                    width: parent.width
                    spacing: 8

                    QsToggleChip {
                        label: "Wi-Fi"
                        icon: NetworkService.wifiEnabled ? "󰤨" : "󰤭"
                        active: NetworkService.wifiEnabled
                        onToggled: NetworkService.toggle()
                        onRightClicked: {
                            drawer.visible = false;
                            appletProc.command = ["nm-connection-editor"];
                            appletProc.running = true;
                        }
                    }

                    QsToggleChip {
                        label: "Bluetooth"
                        icon: BluetoothService.bluetoothEnabled ? "󰂯" : "󰂲"
                        active: BluetoothService.bluetoothEnabled
                        onToggled: BluetoothService.toggle()
                        onRightClicked: {
                            drawer.visible = false;
                            appletProc.command = ["blueman-manager"];
                            appletProc.running = true;
                        }
                    }

                    QsToggleChip {
                        label: "Caffeine"
                        icon: CaffeineService.active ? "󰅶" : "󰾪"
                        active: CaffeineService.active
                        onToggled: CaffeineService.toggle()
                    }

                    QsToggleChip {
                        label: "Night"
                        icon: NightLightService.active ? "󱩌" : "󱩍"
                        active: NightLightService.active
                        onToggled: NightLightService.toggle()
                    }
                }

                QsSliderRow {
                    width: parent.width
                    label: AudioService.muted ? "󰝟  Muted" : "󰕾  Volume"
                    value: AudioService.volume
                    from: 0.0
                    to: 1.5
                    onMoved: val => AudioService.setVolume(val)
                    onLabelClicked: AudioService.toggleMute()
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
        property string label: ""
        property string icon: ""
        property bool active: false
        signal toggled
        signal rightClicked

        width: (contentCol.width - 24) / 4
        height: 64
        radius: 12
        color: active ? Colors.md3.secondary_container : Colors.md3.surface_container_highest

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: chip.icon
                font.pixelSize: 20
                font.family: Config.fontFamily
                color: chip.active ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: chip.label
                font.pixelSize: 11
                font.family: Config.fontFamily
                color: chip.active ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    chip.rightClicked();
                else
                    chip.toggled();
            }
        }
    }

    component QsSliderRow: Item {
        id: sliderRow
        property string label: ""
        property real value: 0
        property real from: 0
        property real to: 1
        property bool dimmed: false
        signal moved(real val)
        signal labelClicked

        property real _dragRatio: -1
        property real _displayRatio: {
            if (_dragRatio >= 0)
                return _dragRatio;
            const range = to - from;
            return range > 0 ? (value - from) / range : 0;
        }

        height: 40

        Row {
            anchors.fill: parent
            spacing: 8

            Text {
                width: 80
                anchors.verticalCenter: parent.verticalCenter
                text: sliderRow.label
                font.pixelSize: 13
                font.family: Config.fontFamily
                color: sliderRow.dimmed ? Colors.md3.on_surface_variant : Colors.md3.on_surface
                elide: Text.ElideRight

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sliderRow.labelClicked()
                }
            }

            Item {
                id: trackContainer
                width: parent.width - 80 - 8
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter

                readonly property real trackWidth: trackContainer.width
                readonly property real handleWidth: 16
                readonly property real usable: trackWidth - handleWidth

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Colors.md3.surface_container_highest

                    Rectangle {
                        width: Math.max(0, sliderRow._displayRatio * trackContainer.usable + trackContainer.handleWidth / 2)
                        height: parent.height
                        radius: 2
                        color: sliderRow.dimmed ? Colors.md3.outline : Colors.md3.primary
                    }
                }

                Rectangle {
                    id: handle
                    width: trackContainer.handleWidth
                    height: 16
                    radius: 8
                    anchors.verticalCenter: track.verticalCenter
                    color: sliderRow.dimmed ? Colors.md3.outline : Colors.md3.primary
                    x: sliderRow._displayRatio * trackContainer.usable

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        preventStealing: true

                        property real startMouseX: 0
                        property real startRatio: 0

                        onPressed: mouse => {
                            startMouseX = mouse.x + handle.x;
                            startRatio = sliderRow._displayRatio;
                            sliderRow._dragRatio = startRatio;
                        }

                        onPositionChanged: mouse => {
                            if (!pressed)
                                return;
                            const newX = Math.max(0, Math.min(trackContainer.usable, mouse.x + handle.x));
                            sliderRow._dragRatio = newX / trackContainer.usable;
                            sliderRow.moved(sliderRow.from + sliderRow._dragRatio * (sliderRow.to - sliderRow.from));
                        }

                        onReleased: {
                            sliderRow._dragRatio = -1;
                        }
                    }
                }

                MouseArea {
                    anchors.fill: track
                    z: -1
                    onClicked: mouse => {
                        const ratio = Math.max(0, Math.min(1, mouse.x / track.width));
                        sliderRow._dragRatio = ratio;
                        sliderRow.moved(sliderRow.from + ratio * (sliderRow.to - sliderRow.from));
                        sliderRow._dragRatio = -1;
                    }
                }
            }
        }
    }
}
