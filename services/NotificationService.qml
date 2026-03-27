pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    component NotifWrapper: QtObject {
        required property var notification

        property string summary: ""
        property string body: ""
        property string appName: ""
        property string appIcon: ""
        property string image: ""
        property string urgency: "normal"
        property double time: 0

        property bool expanded: false
        property bool popup: true

        readonly property string iconSrc: {
            const raw = image || appIcon;
            if (!raw)
                return "image://icon/dialog-information";
            if (raw.startsWith("/"))
                return "file://" + raw;
            return "image://icon/" + raw;
        }
    }

    component NotifWrapperComponent: NotifWrapper {}

    property bool dnd: false
    property var list: []

    readonly property ListModel popupGroupModel: ListModel {}

    PersistentProperties {
        id: persist
        reloadableId: "notificationHistory"
        property var history: []
    }
    readonly property var history: persist.history

    Component {
        id: wrapperComponent
        NotifWrapperComponent {}
    }

    readonly property NotificationServer server: NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;

            const wrapper = wrapperComponent.createObject(root, {
                notification: notification,
                summary: notification.summary || "",
                body: notification.body || "",
                appName: notification.appName || "Unknown",
                appIcon: notification.appIcon || "",
                image: notification.image || "",
                urgency: notification.urgency?.toString() ?? "normal",
                time: Date.now()
            });

            root.list = [...root.list, wrapper];

            if (!root.dnd) {
                root._ensurePopupGroup(wrapper.appName);
            } else {
                wrapper.popup = false;
            }

            notification.closed.connect(reason => {
                // only keep record if the notification expired naturally
                if (reason === NotificationCloseReason.Expired) {
                    const h = [
                        {
                            summary: wrapper.summary,
                            body: wrapper.body,
                            appName: wrapper.appName,
                            appIcon: wrapper.appIcon,
                            image: wrapper.image,
                            time: new Date().toLocaleTimeString([], {
                                hour: "2-digit",
                                minute: "2-digit"
                            })
                        },
                        ...persist.history];
                    if (h.length > 50)
                        h.length = 50;
                    persist.history = h;
                }

                root.list = root.list.filter(w => w !== wrapper);
                root._cleanupPopupGroup(wrapper.appName);
                wrapper.destroy();
            });
        }
    }

    function _groupIndex(appName) {
        for (let i = 0; i < popupGroupModel.count; i++)
            if (popupGroupModel.get(i).appName === appName)
                return i;
        return -1;
    }

    function _ensurePopupGroup(appName) {
        if (_groupIndex(appName) === -1)
            popupGroupModel.insert(0, {
                appName: appName
            });
    }

    function _cleanupPopupGroup(appName) {
        if (root.list.some(w => w.appName === appName))
            return;
        const idx = _groupIndex(appName);
        if (idx !== -1)
            popupGroupModel.remove(idx);
    }

    // public api 👀

    function sendGroupToPanel(appName) {
        const idx = _groupIndex(appName);
        if (idx !== -1)
            popupGroupModel.remove(idx);
        root.list.forEach(w => {
            if (w.appName === appName) {
                w.popup = false;
                w.expanded = false;
            }
        });
    }

    function sendAllToPanel() {
        root.list.forEach(w => {
            w.popup = false;
            w.expanded = false;
        });
        popupGroupModel.clear();
    }

    function dismissAll() {
        root.list.slice().forEach(w => w.notification?.dismiss());
    }

    function clearHistory() {
        persist.history = [];
    }
}
