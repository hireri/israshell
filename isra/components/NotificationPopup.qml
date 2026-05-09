import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.style
import qs.services

Item {
    id: outer
    property bool keepActive: false

    readonly property bool isBottom: {
        const pos = Config.notifications.popupPosition ?? 0;
        if (pos === 1)
            return false;
        if (pos === 2)
            return true;
        return (Config.barPosition ?? 0) === 1;
    }

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
        margins.top: outer.isBottom ? 0 : 12
        margins.bottom: outer.isBottom ? 2 : 0
        implicitWidth: 700
        color: "transparent"
        mask: Region {
            item: notifList
        }

        NotificationListView {
            id: notifList
            property int hoveredCount: 0
            property bool anyHovered: hoveredCount > 0

            anchors.top: outer.isBottom ? undefined : parent.top
            anchors.bottom: outer.isBottom ? parent.bottom : undefined
            anchors.right: parent.right
            anchors.rightMargin: 12

            verticalLayoutDirection: outer.isBottom ? ListView.BottomToTop : ListView.TopToBottom

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
