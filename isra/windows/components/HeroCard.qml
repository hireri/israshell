import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import "IconSlotSync.js" as IconSlotSync

Rectangle {
    id: root

    property color iconBg: Colors.md3.primary_container
    property color cardColor: Colors.md3.surface_container_high
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property bool hasSwitch: true

    signal toggled(bool checked)

    property string settingKey: ""
    property string settingKeywords: ""
    property string settingType: "switch"
    property string settingsPath: ""

    function applyValue(value) {
        root.toggled(value);
    }

    implicitHeight: 72
    radius: 18
    color: (Config.dim(root.cardColor))

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 20
            topMargin: 12
            bottomMargin: 12
        }
        spacing: 14

        Rectangle {
            width: 48
            height: 48
            radius: 10
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

    Component.onCompleted: {
        SettingsRegistry.register(root);
        deferSync.restart();
    }
    Component.onDestruction: SettingsRegistry.unregister(root)

    function _syncIcon() {
        IconSlotSync.syncIconSlot(iconSlot.children, 24, () => Colors.md3.on_surface, root.checked);
    }

    onCheckedChanged: _syncIcon()
}
