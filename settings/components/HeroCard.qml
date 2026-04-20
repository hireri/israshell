import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property color iconBg: Colors.md3.primary_container
    property color cardColor: Colors.md3.surface_container_high
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property bool hasSwitch: true

    signal toggled(bool checked)

    implicitHeight: 72
    radius: 18
    color: root.cardColor

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 20
            rightMargin: 20
            topMargin: 12
            bottomMargin: 12
        }
        spacing: 14

        Rectangle {
            width: 48
            height: 48
            radius: 24
            color: root.iconBg
            Layout.alignment: Qt.AlignVCenter

            Item {
                id: iconSlot
                anchors.centerIn: parent
                width: 24
                height: 24

                onChildrenChanged: _syncIcon()
            }

            Timer {
                id: deferSync
                interval: 0
                onTriggered: root._syncIcon()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            Text {
                text: root.title
                font.family: Config.fontFamily
                font.pixelSize: 15
                font.weight: Font.Medium
                color: Colors.md3.on_surface
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: root.subtitle
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.outline
                visible: root.subtitle !== ""
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        Md3Switch {
            visible: root.hasSwitch
            checked: root.checked
            Layout.alignment: Qt.AlignVCenter
            onToggled: v => {
                root.toggled(v);
            }
        }
    }

    default property alias iconChild: iconSlot.data

    Component.onCompleted: deferSync.restart()

    function _syncIcon() {
        for (let i = 0; i < iconSlot.children.length; i++) {
            const ico = iconSlot.children[i];
            if (ico.hasOwnProperty("iconSize"))
                ico.iconSize = 24;
            if (ico.hasOwnProperty("color"))
                ico.color = Colors.md3.on_surface;
            if (ico.hasOwnProperty("filled"))
                ico.filled = root.checked;
        }
    }

    onCheckedChanged: _syncIcon()
}
