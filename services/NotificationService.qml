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

        readonly property string groupKey: appName + "|" + summary

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

    property var latestTimeForKey: ({})

    readonly property var history: []

    Item {
        id: cleanupTimer
        property var _queue: []

        function schedule(appName, summary, gKey, wrapper) {
            _queue.push({
                appName,
                summary,
                gKey,
                wrapper
            });
            _timer.restart();
        }

        Timer {
            id: _timer
            interval: 300
            repeat: false
            onTriggered: {
                cleanupTimer._queue.forEach(entry => {
                    root._cleanupQsGroup(entry.appName, entry.summary);
                    const lt = root.latestTimeForKey;
                    if (!root.list.some(w => w.groupKey === entry.gKey)) {
                        delete lt[entry.gKey];
                        root.latestTimeForKey = lt;
                    }
                    entry.wrapper.destroy();
                });
                cleanupTimer._queue = [];
            }
        }
    }

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

            if (notification.replacesId && notification.replacesId > 0) {
                const replaced = root.list.find(w => {
                    return false;
                });
            }

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

            const lt = root.latestTimeForKey;
            lt[wrapper.groupKey] = wrapper.time;
            root.latestTimeForKey = lt;

            const isCritical = wrapper.urgency === "critical";
            if (!root.dnd || isCritical) {
                root._ensurePopupGroup(wrapper.appName, wrapper.summary);
            } else {
                wrapper.popup = false;
            }

            root._ensureQsGroup(wrapper.appName, wrapper.summary);

            notification.closed.connect(reason => {
                const reasonStr = {
                    [NotificationCloseReason.Expired]: "Expired",
                    [NotificationCloseReason.Dismissed]: "Dismissed",
                    [NotificationCloseReason.CloseRequested]: "CloseRequested"
                }[reason] ?? `Unknown(${reason})`;

                if (reason === NotificationCloseReason.CloseRequested) {
                    wrapper.notification = null;
                    return;
                }

                wrapper.popup = false;
                root.list = root.list.filter(w => w !== wrapper);
                root._cleanupPopupGroup(wrapper.appName, wrapper.summary);

                const appN = wrapper.appName;
                const summ = wrapper.summary;
                const gKey = wrapper.groupKey;
                cleanupTimer.schedule(appN, summ, gKey, wrapper);
            });
        }
    }

    function _popupGroupIndex(appName, groupSummary) {
        const key = appName + "|" + groupSummary;
        for (let i = 0; i < popupGroupModel.count; i++)
            if (popupGroupModel.get(i).groupKey === key)
                return i;
        return -1;
    }

    function _ensurePopupGroup(appName, groupSummary) {
        if (_popupGroupIndex(appName, groupSummary) === -1) {
            const key = appName + "|" + groupSummary;
            popupGroupModel.insert(0, {
                appName: appName,
                groupSummary: groupSummary,
                groupKey: key
            });
        }
    }

    function _cleanupPopupGroup(appName, groupSummary) {
        const key = appName + "|" + groupSummary;
        if (root.list.some(w => w.groupKey === key && w.popup && !w.dismissing))
            return;
        const idx = _popupGroupIndex(appName, groupSummary);
        if (idx !== -1) {
            popupGroupModel.remove(idx);
        }
    }

    function _qsGroupIndex(appName, groupSummary) {
        const key = appName + "|" + groupSummary;
        for (let i = 0; i < qsGroupModel.count; i++)
            if (qsGroupModel.get(i).groupKey === key)
                return i;
        return -1;
    }

    function _ensureQsGroup(appName, groupSummary) {
        if (_qsGroupIndex(appName, groupSummary) === -1) {
            qsGroupModel.insert(0, {
                appName: appName,
                groupSummary: groupSummary,
                groupKey: appName + "|" + groupSummary
            });
        }
    }

    function _cleanupQsGroup(appName, groupSummary) {
        const key = appName + "|" + groupSummary;
        if (root.list.some(w => w.groupKey === key))
            return;
        const idx = _qsGroupIndex(appName, groupSummary);
        if (idx !== -1) {
            qsGroupModel.remove(idx);
        }
    }

    function sendGroupToPanel(appName, groupSummary) {
        const key = appName + "|" + groupSummary;
        const idx = _popupGroupIndex(appName, groupSummary);
        if (idx !== -1)
            popupGroupModel.remove(idx);
        root.list.forEach(w => {
            if (w.groupKey === key) {
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
    }
}
