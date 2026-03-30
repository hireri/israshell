import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.style
import qs.services

Item {
    id: outer

    property bool keepActive: false

    Timer {
        id: deactivateTimer
        interval: 400
        onTriggered: outer.keepActive = false
    }

    Connections {
        target: NotificationService.popupGroupModel
        function onCountChanged() {
            if (NotificationService.popupGroupModel.count > 0) {
                outer.keepActive = true;
                deactivateTimer.stop();
            } else {
                deactivateTimer.restart();
            }
        }
    }

    Loader {
        active: outer.keepActive
        sourceComponent: PanelWindow {
            id: root

            anchors.top: true
            anchors.right: true
            anchors.bottom: true
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:notificationPopup"
            WlrLayershell.screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            exclusiveZone: 0
            margins.top: Config.floatingBar ? 64 : 54

            implicitWidth: 700
            color: "transparent"

            mask: Region {
                item: notifList
            }

            NotificationListView {
                id: notifList
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 12
                implicitWidth: 320
                implicitHeight: contentHeight
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
                    inPanel: false
                    width: 320
                }
            }
        }
    }
}
