import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.services

Column {
    id: group

    property string appName: ""

    readonly property var notifs: {
        const _ = NotificationService.list;
        return NotificationService.list.filter(w => w.appName === group.appName && w.popup).reverse();
    }
    readonly property int count: notifs.length

    onNotifsChanged: {
        if (count > 0)
            groupTimer.restart();
    }

    property bool expandedState: false

    width: 320
    spacing: 4

    Timer {
        id: groupTimer
        running: group.count > 0
        interval: {
            if (group.notifs.length === 0)
                return 5000;

            const latest = group.notifs[group.notifs.length - 1];
            const t = latest.notification?.expireTimeout ?? 0;
            return t > 0 ? t : 5000;
        }
        onTriggered: NotificationService.sendGroupToPanel(group.appName)
    }

    RowLayout {
        width: parent.width

        Text {
            text: group.appName
            color: Colors.md3.on_surface_variant
            font.pixelSize: 11
            font.family: Config.fontFamily
            Layout.fillWidth: true
        }

        Text {
            text: "Dismiss all"
            color: Colors.md3.primary
            font.pixelSize: 11
            font.family: Config.fontFamily
            visible: group.count > 1

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: group.notifs.slice().forEach(w => w.notification?.dismiss())
            }
        }
    }

    Repeater {
        model: ScriptModel {
            values: group.expandedState ? group.notifs : group.notifs.slice(0, 2)
        }

        delegate: NotificationCard {
            required property var modelData
            wrapper: modelData
            width: group.width
        }
    }

    Rectangle {
        visible: group.count > 2 && !group.expandedState
        width: group.width
        height: 28
        color: Colors.md3.surface_container
        radius: 8

        Text {
            anchors.centerIn: parent
            text: "+" + (group.count - 2) + " more"
            color: Colors.md3.on_surface_variant
            font.pixelSize: 11
            font.family: Config.fontFamily
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: group.expandedState = true
        }
    }
}
