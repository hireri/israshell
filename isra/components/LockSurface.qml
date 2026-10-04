import QtQuick

Item {
    LockLayout {
        anchors.fill: parent
    }

    LockSwitcher {
        z: 20
        anchors {
            right: parent.right
            rightMargin: 20
            bottom: parent.bottom
            bottomMargin: 20
        }
    }
}
