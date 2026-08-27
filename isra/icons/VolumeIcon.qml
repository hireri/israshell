import QtQuick

Item {
    id: root

    property bool muted: false
    property int volume: 0
    property color color: "white"
    property real iconSize: 24
    property bool filled: true

    width: iconSize
    height: iconSize

    readonly property string _name: {
        if (root.muted) return "volume-off";
        if (root.volume >= 66) return "volume-up";
        if (root.volume >= 33) return "volume-down";
        return "volume-mute";
    }

    MaterialIcon {
        anchors.fill: parent
        name: root._name
        iconSize: root.iconSize
        filled: root.filled
        color: root.color
    }
}
