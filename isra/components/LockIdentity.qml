import QtQuick
import QtQuick.Effects
import Quickshell
import qs.style
import qs.icons

Row {
    id: root

    property real avatarSize: 44
    property real nameSize: 14
    property bool showStatus: true

    readonly property string user: Quickshell.env("USER")

    spacing: 10

    Item {
        width: root.avatarSize
        height: root.avatarSize
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: face
            anchors.fill: parent
            source: "file://" + Quickshell.env("HOME") + "/.face"
            sourceSize: Qt.size(root.avatarSize * 2, root.avatarSize * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        MaterialShape {
            id: mask
            anchors.fill: parent
            name: "cookie12"
            immediate: true
            shapeSize: root.avatarSize
            color: "white"
            opacity: 0
            layer.enabled: true
            layer.smooth: true
        }

        MultiEffect {
            anchors.fill: parent
            source: face
            opacity: face.status === Image.Ready ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.5
        }

        MaterialShape {
            anchors.fill: parent
            visible: face.status === Image.Error
            name: "cookie12"
            immediate: true
            shapeSize: root.avatarSize
            color: Colors.md3.primary

            Text {
                anchors.centerIn: parent
                text: root.user.charAt(0).toUpperCase()
                color: Colors.md3.on_primary
                font.pixelSize: root.avatarSize * 0.4
                font.weight: Font.Medium
            }
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            text: root.user
            color: Colors.md3.on_surface
            font.pixelSize: root.nameSize
            font.weight: Font.Medium
        }
        Text {
            visible: root.showStatus
            text: Localization.t("lockSurface.locked")
            color: Colors.md3.on_surface_variant
            font.pixelSize: 11
        }
    }
}
