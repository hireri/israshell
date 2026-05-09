import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property int page: 0
    property string label: ""
    property string sublabel: ""
    property bool active: false

    property real topRadius: 18
    property real bottomRadius: 18

    default property alias iconChild: iconSlot.data

    signal clicked

    implicitHeight: 54
    implicitWidth: 224

    color: root.active ? Colors.md3.secondary_container : (hover.containsMouse ? Colors.md3.surface_container_high : Colors.md3.surface_container)

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
        for (let i = 0; i < iconSlot.children.length; i++) {
            const ico = iconSlot.children[i];
            if (ico.hasOwnProperty("iconSize")) {
                ico.iconSize = 20;
            }
            if (ico.hasOwnProperty("color")) {
                ico.color = Qt.binding(() => root.active ? Colors.md3.on_secondary_container : Colors.md3.outline);
            }
            if (ico.hasOwnProperty("filled")) {
                ico.filled = Qt.binding(() => root.active);
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
