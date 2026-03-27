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
    margins.top: Config.floatingBar ? 64 : 54
    margins.right: 12

    mask: Region {
        item: groupCol
    }
    color: "transparent"
    implicitWidth: 320

    visible: NotificationService.popupGroupModel.count > 0

    Column {
        id: groupCol
        width: 320
        spacing: 8
        anchors.top: parent.top
        anchors.right: parent.right

        Repeater {
            model: NotificationService.popupGroupModel

            delegate: NotificationGroup {
                required property var model
                appName: model.appName
                width: 320
            }
        }
    }
}
