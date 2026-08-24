import QtQuick
import QtQuick.Layouts
import qs.style
import "IconSlotSync.js" as IconSlotSync

Rectangle {
    id: root

    property int page: 0
    property string label: ""
    property string sublabel: ""
    property bool active: false
    property bool collapsed: false

    property real topRadius: 18
    property real bottomRadius: 18

    property color restColor: Config.dim(Colors.md3.surface_container)
    property color hoverColor: Config.dim(Colors.md3.surface_container_high)

    default property alias iconChild: iconSlot.data

    signal clicked

    implicitHeight: 54
    Layout.fillWidth: true

    color: root.active ? Colors.md3.secondary_container : (hover.containsMouse ? root.hoverColor : root.restColor)

    topLeftRadius: root.topRadius
    topRightRadius: root.topRadius
    bottomLeftRadius: root.bottomRadius
    bottomRightRadius: root.bottomRadius

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 14
            topMargin: 8
            bottomMargin: 8
        }
        spacing: 12

        Item {
            id: iconSlot
            width: 20
            height: 20
            Layout.alignment: Qt.AlignVCenter
            onChildrenChanged: deferSync.restart()
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            opacity: root.collapsed ? 0 : 1
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            Text {
                text: root.label
                font.family: Config.fontFamily
                font.pixelSize: 13
                font.weight: root.active ? Font.Medium : Font.Normal
                color: root.active ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: root.sublabel
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: root.active ? Colors.md3.secondary : Colors.md3.outline
                visible: root.sublabel !== ""
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    Timer {
        id: deferSync
        interval: 0
        onTriggered: root._syncIcon()
    }

    Component.onCompleted: deferSync.restart()
    onActiveChanged: _syncIcon()

    function _syncIcon() {
        IconSlotSync.syncIconSlot(iconSlot.children, 20, root.active ? Colors.md3.on_secondary_container : Colors.md3.outline, root.active);
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
