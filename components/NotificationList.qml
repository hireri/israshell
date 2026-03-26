import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.style

ColumnLayout {
    spacing: 10
    property var service

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Notifications"
            color: Colors.md3.on_surface
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
        }

        Button {
            text: "Clear"
            onClicked: service.clearHistory()
            visible: service.history.length > 0
        }
    }

    Button {
        Layout.fillWidth: true
        contentItem: RowLayout {
            Text {
                text: service.dnd ? "󰂛 Do Not Disturb: On" : "󰂚 Do Not Disturb: Off"
                color: service.dnd ? Colors.md3.error : Colors.md3.primary
                Layout.fillWidth: true
            }
        }
        onClicked: service.dnd = !service.dnd
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: 300
        spacing: 5
        clip: true
        model: service.history

        delegate: Rectangle {
            width: parent.width
            height: 60
            color: Colors.md3.surface_container
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 8
                Text {
                    text: modelData.summary
                    color: Colors.md3.on_surface
                    font.bold: true
                }
                Text {
                    text: modelData.body
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "No notifications"
            color: Colors.md3.on_surface_variant
            visible: service.history.length === 0
        }
    }
}
