import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.style
import qs.services

PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    anchors.bottom: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notificationPopup"
    exclusiveZone: 0
    margins.top: 12

    implicitWidth: 700

    mask: Region {
        item: notifList
    }
    color: "transparent"

    visible: NotificationService.popupGroupModel.count > 0

    NotificationListView {
        id: notifList
        anchors.top: parent.top
        anchors.right: parent.right
        implicitWidth: 320
        implicitHeight: contentHeight
        height: contentHeight
        anchors.rightMargin: 12

        model: ScriptModel {
            values: NotificationService.popupAppNames
        }

        delegate: NotificationGroup {
            required property var modelData
            required property int index
            appName: modelData
            groupIdx: index
            listRef: notifList
            popup: true
            inPanel: false
            width: 320
        }
    }
}
