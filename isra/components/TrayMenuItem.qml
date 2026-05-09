import QtQuick
import Quickshell
import qs.style

Item {
    id: root

    required property var menuEntry
    required property real totalWidth
    required property real itemH
    required property real sepH

    signal submenuClicked(var entry)
    signal hoveredWithSubmenu(var entry, real globalY)
    signal hoveredNoSubmenu
    signal triggered

    readonly property bool isSep: menuEntry?.isSeparator ?? false
    readonly property bool hasChildren: menuEntry?.hasChildren ?? false
    readonly property bool isEnabled: menuEntry?.enabled ?? true
    readonly property bool isChecked: (menuEntry?.checkState ?? 0) > 0

    width: totalWidth
    height: isSep ? sepH : itemH

    Rectangle {
        visible: root.isSep
        anchors {
            left: parent.left
            leftMargin: 12
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        height: 1
        color: Colors.md3.outline_variant
    }

    Item {
        visible: !root.isSep
        anchors.fill: parent
        clip: true
        opacity: root.isEnabled ? 1.0 : 0.38

        Rectangle {
            id: hoverBg
            anchors {
                fill: parent
                leftMargin: 6
                rightMargin: 8
                topMargin: 2
                bottomMargin: 2
            }
            radius: 12
            color: Colors.md3.on_surface
            opacity: 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 60
                }
            }
        }

        Rectangle {
            visible: root.isChecked
            anchors {
                left: parent.left
                leftMargin: 18
                verticalCenter: parent.verticalCenter
            }
            width: 4
            height: 4
            radius: 2
            color: Colors.md3.primary
        }

        Image {
            id: icon
            visible: source !== ""
            source: root.menuEntry?.icon ?? ""
            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            width: 15
            height: 15
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(15, 15)
        }

        Text {
            anchors {
                left: icon.visible ? icon.right : parent.left
                leftMargin: icon.visible ? 7 : 14
                right: parent.right
                rightMargin: root.hasChildren ? 30 : 14
                verticalCenter: parent.verticalCenter
            }
            text: root.menuEntry?.text ?? ""
            color: Colors.md3.on_surface
            font.pixelSize: 12
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            id: chevron
            visible: root.hasChildren
            anchors {
                right: parent.right
                rightMargin: 16
                verticalCenter: parent.verticalCenter
            }
            text: "󰅂"
            color: Colors.md3.on_surface_variant
            font.pixelSize: 15
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.isEnabled && !root.isSep
            cursorShape: Qt.PointingHandCursor
            onEntered: hoverBg.opacity = 0.08
            onExited: hoverBg.opacity = 0
            onClicked: {
                if (root.hasChildren)
                    root.submenuClicked(root.menuEntry);
                else {
                    root.menuEntry?.triggered();
                    root.triggered();
                }
            }
        }
    }
}
