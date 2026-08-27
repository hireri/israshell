import QtQuick

Item {
    id: root

    property int profileMode: 1
    property color color: "white"
    property real iconSize: 24
    property bool filled: true

    width: iconSize
    height: iconSize

    readonly property string _name: {
        switch (root.profileMode) {
        case 0: return "speed-3";
        case 2: return "local-fire-department";
        default: return "energy-savings-leaf";
        }
    }

    MaterialIcon {
        anchors.fill: parent
        name: root._name
        iconSize: root.iconSize
        filled: root.filled
        color: root.color
    }
}
