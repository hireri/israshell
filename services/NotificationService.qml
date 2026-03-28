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
        property bool dismissing: false

        readonly property string iconSrc: {
            const raw = image || appIcon;
            if (!raw)
                return "";
            if (raw.startsWith("/"))
                return "file://" + raw;
            return "image://icon/" + raw;
        }
    }

    component NotifWrapperComponent: NotifWrapper {}

    property bool dnd: false
    property var list: []

    readonly property int listCount: list.length

    readonly property ListModel popupGroupModel: ListModel {}

    readonly property ListModel qsGroupModel: ListModel {}

    property var latestTimeForApp: ({})

    readonly property var popupAppNames: {
        const _ = popupGroupModel.count;
        const names = [];
        for (let i = 0; i < popupGroupModel.count; i++)
            names.push(popupGroupModel.get(i).appName);
        return names.sort((a, b) => (root.latestTimeForApp[b] ?? 0) - (root.latestTimeForApp[a] ?? 0));
    }

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

            const lt = root.latestTimeForApp;
            lt[wrapper.appName] = wrapper.time;
            root.latestTimeForApp = lt;

            if (!root.dnd) {
                root._ensurePopupGroup(wrapper.appName);
            } else {
                wrapper.popup = false;
            }

            root._ensureQsGroup(wrapper.appName);

            notification.closed.connect(reason => {
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
                root._cleanupQsGroup(wrapper.appName);

                const lt2 = root.latestTimeForApp;
                if (!root.list.some(w => w.appName === wrapper.appName)) {
                    delete lt2[wrapper.appName];
                    root.latestTimeForApp = lt2;
                }

                wrapper.destroy();
            });
        }
    }

    function _popupGroupIndex(appName) {
        for (let i = 0; i < popupGroupModel.count; i++)
            if (popupGroupModel.get(i).appName === appName)
                return i;
        return -1;
    }

    function _ensurePopupGroup(appName) {
        if (_popupGroupIndex(appName) === -1)
            popupGroupModel.insert(0, {
                appName: appName
            });
    }

    function _cleanupPopupGroup(appName) {
        if (root.list.some(w => w.appName === appName && w.popup && !w.dismissing))
            return;
        const idx = _popupGroupIndex(appName);
        if (idx !== -1)
            popupGroupModel.remove(idx);
    }

    function _qsGroupIndex(appName) {
        for (let i = 0; i < qsGroupModel.count; i++)
            if (qsGroupModel.get(i).appName === appName)
                return i;
        return -1;
    }

    function _ensureQsGroup(appName) {
        if (_qsGroupIndex(appName) === -1)
            qsGroupModel.insert(0, {
                appName: appName
            });
    }

    function _cleanupQsGroup(appName) {
        if (root.list.some(w => w.appName === appName))
            return;
        const idx = _qsGroupIndex(appName);
        if (idx !== -1)
            qsGroupModel.remove(idx);
    }

    function sendGroupToPanel(appName) {
        const idx = _popupGroupIndex(appName);
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
