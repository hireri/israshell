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

    component PopupPanel: PanelWindow {
        id: root
        required property var targetScreen
        anchors.top: true
        anchors.right: true
        anchors.bottom: true
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:notificationPopup"
        WlrLayershell.screen: targetScreen
        exclusiveZone: 0
        margins.top: 12
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
                height: implicitHeight
            }
        }
    }

    Loader {
        active: outer.keepActive && !Config.notifications.showAllMonitors
        sourceComponent: Component {
            PopupPanel {
                targetScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            }
        }
    }

    Variants {
        model: (Config.notifications.showAllMonitors && outer.keepActive) ? Quickshell.screens : []
        Scope {
            id: screenScope
            required property var modelData
            PopupPanel {
                targetScreen: screenScope.modelData
            }
        }
    }
}
