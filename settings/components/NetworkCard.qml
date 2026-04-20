import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property bool enabled: false
    property color tint: Colors.md3.surface_container
    property color onTint: Colors.md3.on_surface

    property Component iconComponent: null

    property string title: ""
    property string subtitle: ""

    property bool hasSwitch: true
    property bool switchChecked: false

    signal switchToggled

    implicitHeight: cardRow.implicitHeight + 28
    radius: 18
    color: root.enabled ? root.tint : Colors.md3.surface_container

    Behavior on color {
        ColorAnimation {
            duration: 180
        }
    }

    RowLayout {
        id: cardRow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 18
            rightMargin: 18
        }
        spacing: 14

        Item {
            width: 24
            height: 24
            Layout.alignment: Qt.AlignVCenter
            opacity: root.enabled ? 1 : 0.4
            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            Loader {
                anchors.centerIn: parent
                sourceComponent: root.iconComponent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            Text {
                text: root.title
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
                color: root.enabled ? root.onTint : Colors.md3.on_surface
                Layout.fillWidth: true
                elide: Text.ElideRight
                Behavior on color {
                    ColorAnimation {
                        duration: 180
                    }
                }
            }

            Text {
                text: root.subtitle
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: root.enabled ? root.onTint : Colors.md3.outline
                opacity: 0.75
                Layout.fillWidth: true
                elide: Text.ElideRight
                Behavior on color {
                    ColorAnimation {
                        duration: 180
                    }
                }
            }
        }

        Md3Switch {
            visible: root.hasSwitch
            checked: root.switchChecked
            Layout.alignment: Qt.AlignVCenter
            onToggled: v => root.switchToggled()
        }
    }
}
