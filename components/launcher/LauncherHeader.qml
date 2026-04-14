import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string mode: "apps"
    property int count: 0
    property int skinToneIndex: 0
    property bool sortAlpha: true

    signal clearRequested
    signal sortToggled
    signal skinToneChanged(int index)

    implicitHeight: row.implicitHeight + 10
    implicitWidth: parent ? parent.width : 400

    readonly property var _toneIcons: ["🖐️", "🖐🏻", "🖐🏼", "🖐🏽", "🖐🏾", "🖐🏿"]

    RowLayout {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 6
            rightMargin: 6
        }
        spacing: 3

        Item {
            Layout.preferredWidth: visible ? implicitWidth : 0
            implicitWidth: 0
            visible: false
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 14
            topRightRadius: 8
            bottomRightRadius: 8
            bottomLeftRadius: 8

            color: Colors.md3.surface_container_high

            Text {
                id: statusText
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                    rightMargin: 10
                }
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (root.mode === "clipboard")
                        return root.count + (root.count === 1 ? " Entry" : " Entries");
                    if (root.mode === "emoji")
                        return root.count + (root.count === 1 ? " Emoji" : " Emojis");
                    return root.count + (root.count === 1 ? " App" : " Apps");
                }
                font.pixelSize: 12
                color: Colors.md3.on_surface_variant
                font.family: Config.fontFamily
            }
        }

        Pill {
            visible: root.mode === "clipboard"
            Layout.alignment: Qt.AlignVCenter
            iconText: root.count === 0 ? "󰩺" : "󰩹"
            enabled: root.count > 0
            onClicked: root.clearRequested()
        }

        Pill {
            visible: root.mode === "apps"
            Layout.alignment: Qt.AlignVCenter
            iconText: root.sortAlpha ? "󰖽" : "󰒼"
            onClicked: {
                root.sortAlpha = !root.sortAlpha;
                root.sortToggled();
            }
        }

        Pill {
            visible: root.mode === "emoji"
            Layout.alignment: Qt.AlignVCenter
            iconText: root._toneIcons[root.skinToneIndex]
            onClicked: {
                root.skinToneIndex = (root.skinToneIndex + 1) % 6;
                root.skinToneChanged(root.skinToneIndex);
            }
        }
    }

    component Pill: Rectangle {
        id: pill

        property string iconText: ""
        property bool enabled: true
        signal clicked

        implicitWidth: 32
        implicitHeight: 28
        radius: 14
        topLeftRadius: 8
        bottomLeftRadius: 8
        bottomRightRadius: 8

        color: {
            if (!pill.enabled)
                return Colors.md3.surface_container_high;
            if (ma.containsMouse)
                return Colors.md3.surface_container_highest;
            return Colors.md3.surface_container_high;
        }
        opacity: pill.enabled ? 1.0 : 0.4

        Behavior on color {
            ColorAnimation {
                duration: 80
            }
        }

        Text {
            anchors.centerIn: parent
            text: pill.iconText
            font.pixelSize: 14
            font.family: Config.fontFamily
            color: Colors.md3.on_surface_variant
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: pill.enabled
            cursorShape: pill.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: pill.enabled
            onClicked: if (pill.enabled)
                pill.clicked()
        }
    }
}
