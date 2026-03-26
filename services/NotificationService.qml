pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    property bool dnd: false

    readonly property ListModel history: ListModel {}

    readonly property NotificationServer server: NotificationServer {
        id: notificationServer

        onNotification: notification => {
            notification.tracked = true;

            root.history.insert(0, {
                "summary": notification.summary || "",
                "body": notification.body || "",
                "appName": notification.appName || "",
                "appIcon": notification.appIcon || "",
                "image": notification.image || "",
                "time": new Date().toLocaleTimeString([], {
                    hour: '2-digit',
                    minute: '2-digit'
                })
            });

            if (root.history.count > 50)
                root.history.remove(50);
        }
    }

    readonly property var activeNotifications: notificationServer.trackedNotifications

    function clearHistory() {
        root.history.clear();
    }
}
