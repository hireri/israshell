import QtQuick
import qs.style
import qs.services

Item {
    id: root

    required property var win
    readonly property bool atBottom: (Config.notifications.popupPosition ?? 0) === 0 ? Config.bar.position === 1 : Config.notifications.popupPosition === 2
    readonly property real edgeInset: atBottom === (Config.bar.position === 1) ? (win?.barHeight ?? 0) : (win?.frameInset ?? 0)
    readonly property real pad: 6
    readonly property Item box: box

    readonly property real shadowGap: 10
    property real meltH: notifList.height > 0.5 ? notifList.height - shadowGap + pad * 2 : 0
    Behavior on meltH {
        enabled: countAnim.running
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: countAnim
        interval: 300
    }
    Connections {
        target: notifList
        function onCountChanged() {
            countAnim.restart();
        }
    }

    MeltReporter {
        win: root.win
        key: "notifications"
        rect: Qt.rect(box.x, box.y, box.width, box.height)
        active: root.meltH > 0.5
        edge: root.atBottom ? 1 : 0
    }

    Item {
        id: box
        x: root.width - (root.win?.frameInset ?? 0) - width
        y: root.atBottom ? root.height - root.edgeInset - height : root.edgeInset
        width: 320 + root.pad * 2
        height: root.meltH
        clip: true

        NotificationListView {
            id: notifList
            property int hoveredCount: 0
            property bool anyHovered: hoveredCount > 0

            anchors.top: root.atBottom ? undefined : parent.top
            anchors.bottom: root.atBottom ? parent.bottom : undefined
            anchors.topMargin: root.pad
            anchors.bottomMargin: root.pad - root.shadowGap
            anchors.horizontalCenter: parent.horizontalCenter

            verticalLayoutDirection: root.atBottom ? ListView.BottomToTop : ListView.TopToBottom

            width: 320
            height: contentHeight
            popup: true
            model: NotificationService.popupGroupModel
            delegate: NotificationGroup {
                required property var model
                required property int index
                appName: model.appName ?? ""
                groupSummary: model.groupSummary ?? ""
                groupIdx: index
                listRef: notifList
                popup: true
                melted: true
                inPanel: false
                width: 320
                height: implicitHeight
            }
        }
    }
}
