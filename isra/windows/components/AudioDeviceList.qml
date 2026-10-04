import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services

Item {
    id: root

    property bool sink: true
    property int inset: 10

    implicitWidth: parent?.width ?? 0
    implicitHeight: list.implicitHeight

    Column {
        id: list
        width: root.width

        Repeater {
            model: AudioService.nodes.filter(n => n.audio && !n.isStream && n.isSink === root.sink)

            delegate: Item {
                id: device
                required property var modelData

                readonly property bool active: root.sink ? AudioService.isDefaultSink(modelData) : AudioService.isDefaultSource(modelData)

                width: list.width
                implicitHeight: 52

                Rectangle {
                    anchors {
                        fill: parent
                        leftMargin: root.inset
                        rightMargin: root.inset
                        topMargin: 4
                        bottomMargin: 4
                    }
                    radius: 14
                    color: device.active ? Colors.md3.primary_container : Config.dim(Colors.md3.surface_container_high)

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 14
                        }
                        spacing: 12

                        Text {
                            text: root.sink ? "󰕾" : "󰍬"
                            font.pixelSize: 16
                            font.family: Config.fontMonospace
                            color: device.active ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                        }

                        Text {
                            Layout.fillWidth: true
                            text: AudioService.deviceName(device.modelData)
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: device.active ? Font.Medium : Font.Normal
                            color: device.active ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: device.active
                            text: "󰄬"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Colors.md3.on_primary_container
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: device.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !device.active
                        onClicked: root.sink ? AudioService.setDefaultSink(device.modelData) : AudioService.setDefaultSource(device.modelData)
                    }
                }
            }
        }
    }
}
