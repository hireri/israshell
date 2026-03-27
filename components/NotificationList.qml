import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.services

ColumnLayout {
    spacing: 10

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Notifications"
            color: Colors.md3.on_surface
            font.pixelSize: 16
            font.bold: true
            font.family: Config.fontFamily
            Layout.fillWidth: true
        }

        Text {
            text: "Clear all"
            color: Colors.md3.primary
            font.pixelSize: 12
            font.family: Config.fontFamily
            visible: NotificationService.history.length > 0

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationService.clearHistory()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: 8
        color: NotificationService.dnd ? Colors.md3.error_container : Colors.md3.surface_container

        Text {
            anchors.centerIn: parent
            text: NotificationService.dnd ? "󰂛  Do Not Disturb: On" : "󰂚  Do Not Disturb: Off"
            color: NotificationService.dnd ? Colors.md3.on_error_container : Colors.md3.on_surface
            font.family: Config.fontFamily
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationService.dnd = !NotificationService.dnd
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: 300
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            width: parent.width
            spacing: 5

            Repeater {
                model: ScriptModel {
                    values: NotificationService.history
                }

                delegate: NotificationCard {
                    required property var modelData
                    historyData: modelData
                    width: parent.width
                }
            }

            Item {
                width: parent.width
                height: 60
                visible: NotificationService.history.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                }
            }
        }
    }
}
