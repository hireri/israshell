pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.icons
import qs.services
import qs.style

Item {
    id: root

    implicitWidth: 280
    implicitHeight: column.implicitHeight

    function iconFor(type) {
        switch (type) {
        case UPowerDeviceType.GamingInput:
            return "game-mode";
        case UPowerDeviceType.Mouse:
        case UPowerDeviceType.Touchpad:
            return "mouse";
        case UPowerDeviceType.Keyboard:
            return "keyboard";
        case UPowerDeviceType.Phone:
            return "mobile";
        case UPowerDeviceType.Headset:
        case UPowerDeviceType.Headphones:
        case UPowerDeviceType.Speakers:
        case UPowerDeviceType.OtherAudio:
            return "headphones";
        default:
            return "battery-android-full";
        }
    }

    ScriptModel {
        id: devices
        values: UPower.devices.values.filter(d => d.isPresent && d.type !== UPowerDeviceType.LinePower)
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            visible: devices.values.length === 0
            text: Localization.t("gameOverlay.no_devices")
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.outline
            renderType: Text.NativeRendering
        }

        Repeater {
            model: devices

            delegate: Item {
                id: row
                required property var modelData

                readonly property int percent: Math.round(modelData.percentage * 100)
                readonly property bool charging: modelData.state === UPowerDeviceState.Charging
                readonly property bool low: row.percent <= 15 && !row.charging

                Layout.fillWidth: true
                implicitHeight: card.implicitHeight

                RowLayout {
                    id: card
                    anchors.fill: parent
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignVCenter
                        radius: 20
                        color: row.low ? Colors.md3.error_container : Colors.md3.primary_container

                        MaterialIcon {
                            anchors.centerIn: parent
                            name: root.iconFor(row.modelData.type)
                            iconSize: 22
                            color: row.low ? Colors.md3.on_error_container : Colors.md3.on_primary_container
                            transitionType: "none"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.model !== "" ? row.modelData.model : UPowerDeviceType.toString(row.modelData.type)
                                font.family: Config.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: Colors.md3.on_surface
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }

                            Text {
                                visible: row.charging
                                text: Localization.t("gameOverlay.charging")
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                color: Colors.md3.on_surface_variant
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: row.percent + "%"
                                font.family: Config.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                font.features: { "tnum": 1 }
                                color: row.low ? Colors.md3.error : Colors.md3.on_surface
                                renderType: Text.NativeRendering
                            }
                        }

                        Item {
                            id: bar
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8

                            readonly property real gap: 4
                            property real fraction: Math.max(0, Math.min(row.percent / 100, 1))
                            readonly property real fillLen: fraction * width

                            Behavior on fraction {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                            readonly property real trackLen: Math.max(width - fillLen - (fillLen > 0.5 ? gap : 0), 0)

                            Rectangle {
                                visible: bar.fillLen > 0.5
                                width: bar.fillLen
                                height: parent.height
                                radius: height / 2
                                color: row.low ? Colors.md3.error : Colors.md3.primary
                            }

                            Rectangle {
                                visible: bar.trackLen > 0.5
                                x: bar.width - width
                                width: bar.trackLen
                                height: parent.height
                                radius: height / 2
                                color: Colors.md3.surface_variant
                            }
                        }
                    }
                }
            }
        }
    }
}
