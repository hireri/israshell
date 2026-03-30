import QtQuick
import QtQuick.Controls

ListView {
    id: root

    property int dragIndex: -1
    property real dragDistance: 0
    property bool popup: false

    function resetDrag() {
        dragIndex = -1;
        dragDistance = 0;
    }

    spacing: 8
    clip: false
    interactive: false

    add: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: root.popup ? 1 : 0
                to: 1
                duration: root.popup ? 0 : 220
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "x"
                from: root.popup ? 60 : 0
                to: 0
                duration: root.popup ? 280 : 0
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: root.popup ? 1 : 0.92
                to: 1
                duration: root.popup ? 0 : 250
                easing.type: Easing.OutBack
            }
        }
    }

    addDisplaced: Transition {
        NumberAnimation {
            property: "y"
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    remove: Transition {
        NumberAnimation {
            property: "height"
            to: 0
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    removeDisplaced: Transition {
        NumberAnimation {
            property: "y"
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
}
