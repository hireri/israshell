import QtQuick
import QtQuick.Controls

ListView {
    id: root

    property int dragIndex: -1
    property real dragDistance: 0

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
                from: 0
                to: 1
                duration: 250
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.88
                to: 1
                duration: 280
                easing.type: Easing.OutCubic
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
        ParallelAnimation {
            NumberAnimation {
                property: "x"
                to: 380
                duration: 220
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 180
                easing.type: Easing.OutCubic
            }
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
