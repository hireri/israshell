pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.style
import qs.icons

Item {
    id: root

    property string shape: "circle"
    property string icon: ""
    property string image: ""
    property real size: 40
    property color fill: Colors.md3.primary_container
    property color ink: Colors.md3.on_primary_container
    property bool immediate: true

    implicitWidth: root.size
    implicitHeight: root.size

    MaterialShape {
        anchors.centerIn: parent
        shapeSize: root.size
        name: root.shape
        color: root.fill
        immediate: root.immediate
    }

    Loader {
        anchors.centerIn: parent
        active: root.image !== ""

        sourceComponent: Item {
            implicitWidth: root.size * 0.56
            implicitHeight: root.size * 0.56

            IconImage {
                id: logo
                anchors.fill: parent
                source: root.image
                visible: false
                asynchronous: true
            }

            MultiEffect {
                anchors.fill: logo
                source: logo
                brightness: 0.4
                colorization: 1.0
                colorizationColor: root.ink
            }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        visible: root.icon !== ""
        name: root.icon
        iconSize: root.size * 0.5
        color: root.ink
        transitionType: "none"
    }
}
