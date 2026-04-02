pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    // groups[groupKey] = {
    //   appName, groupSummary,
    //   messages: [{ body, summary, image, appIcon, time }],
    //   liveNotification: <Notification | null>
    // }
    property var groups: ({})
    property int version: 0
    property bool dnd: false

    readonly property ListModel popupGroupModel: ListModel {}
    readonly property ListModel qsGroupModel: ListModel {}
    readonly property var history: []

    Item {
        id: popupCleanupTimer
        property var _pending: ({})

        function schedule(gKey, appName, groupSummary) {
            if (_pending[gKey]) {
                _pending[gKey].restart();
                return;
            }
            const t = Qt.createQmlObject('import QtQuick; Timer { interval: 600; repeat: false }', popupCleanupTimer);
            _pending[gKey] = t;
            t.triggered.connect(() => {
                console.log("[NOTIF] ⏱ popup cleanup timeout:", gKey);
                root._removeGroup(gKey);
                t.destroy();
                delete popupCleanupTimer._pending[gKey];
            });
            t.start();
        }

        function cancel(gKey) {
            if (_pending[gKey]) {
                _pending[gKey].stop();
                _pending[gKey].destroy();
                delete _pending[gKey];
                console.log("[NOTIF] ✓ popup cleanup cancelled (replacement arrived):", gKey);
            }
        }
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

            const appName = notification.appName || "Unknown";
            const groupSummary = notification.summary || "";
            const gKey = appName + "|" + groupSummary;

            const msg = {
                body: notification.body || "",
                summary: groupSummary,
                image: notification.image || "",
                appIcon: notification.appIcon || "",
                desktopEntry: notification.desktopEntry || "",
                time: Date.now()
            };

            console.log("[NOTIF] ▶ ARRIVE", "id:", notification.id, "replacesId:", notification.replacesId, "gKey:", gKey, "body:", msg.body.substring(0, 60), "urgency:", notification.urgency?.toString(), "image:", msg.image || "(none)", "appIcon:", msg.appIcon || "(none)", "actions:", (notification.actions || []).map(a => a.identifier).join(",") || "(none)");

            popupCleanupTimer.cancel(gKey);

            const gs = Object.assign({}, root.groups);
            if (!gs[gKey]) {
                gs[gKey] = {
                    appName,
                    groupSummary,
                    messages: [],
                    liveNotification: null,
                    urgency: "normal"
                };
            }
            gs[gKey] = Object.assign({}, gs[gKey], {
                messages: [...gs[gKey].messages, msg],
                liveNotification: notification,
                urgency: notification.urgency?.toString() ?? "normal"
            });
            root.groups = gs;
            root.version++;

            const isCritical = notification.urgency?.toString() === "2";
            if (!root.dnd || isCritical)
                root._ensurePopupGroup(appName, groupSummary, gKey);
            root._ensureQsGroup(appName, groupSummary, gKey);

            notification.closed.connect(reason => {
                const reasonStr = {
                    [NotificationCloseReason.Expired]: "Expired",
                    [NotificationCloseReason.Dismissed]: "Dismissed",
                    [NotificationCloseReason.CloseRequested]: "CloseRequested"
                }[reason] ?? `Unknown(${reason})`;

                console.log("[NOTIF] ✗ CLOSE", "reason:", reasonStr, "gKey:", gKey, "body:", msg.body.substring(0, 40));

                if (reason === NotificationCloseReason.CloseRequested) {
                    const gs2 = Object.assign({}, root.groups);
                    if (gs2[gKey]) {
                        gs2[gKey] = Object.assign({}, gs2[gKey], {
                            liveNotification: null
                        });
                        root.groups = gs2;
                        root.version++;
                    }
                    popupCleanupTimer.schedule(gKey, appName, groupSummary);
                    console.log("[NOTIF] ↷ CloseRequested — nulled liveNotification, waiting for replacement");
                } else {
                    console.log("[NOTIF] ✗ REMOVING group:", gKey);
                    root._removeGroup(gKey);
                }
            });
        }
    }

    function _removeGroup(gKey) {
        const gs = Object.assign({}, root.groups);
        delete gs[gKey];
        root.groups = gs;
        root.version++;
        _removePopupGroup(gKey);
        _removeQsGroup(gKey);
        console.log("[NOTIF] - group removed:", gKey);
    }

    function _popupGroupIndex(gKey) {
        for (let i = 0; i < popupGroupModel.count; i++)
            if (popupGroupModel.get(i).groupKey === gKey)
                return i;
        return -1;
    }

    function _ensurePopupGroup(appName, groupSummary, gKey) {
        if (_popupGroupIndex(gKey) === -1) {
            console.log("[NOTIF] + popupGroup:", gKey);
            popupGroupModel.insert(0, {
                appName,
                groupSummary,
                groupKey: gKey
            });
        }
    }

    function _removePopupGroup(gKey) {
        const idx = _popupGroupIndex(gKey);
        if (idx !== -1) {
            console.log("[NOTIF] - popupGroup:", gKey);
            popupGroupModel.remove(idx);
        }
    }

    function _qsGroupIndex(gKey) {
        for (let i = 0; i < qsGroupModel.count; i++)
            if (qsGroupModel.get(i).groupKey === gKey)
                return i;
        return -1;
    }

    function _ensureQsGroup(appName, groupSummary, gKey) {
        if (_qsGroupIndex(gKey) === -1) {
            console.log("[NOTIF] + qsGroup:", gKey);
            qsGroupModel.insert(0, {
                appName,
                groupSummary,
                groupKey: gKey
            });
        }
    }

    function _removeQsGroup(gKey) {
        const idx = _qsGroupIndex(gKey);
        if (idx !== -1) {
            console.log("[NOTIF] - qsGroup:", gKey);
            qsGroupModel.remove(idx);
        }
    }

    function sendGroupToPanel(gKey) {
        console.log("[NOTIF] → sendGroupToPanel:", gKey);
        _removePopupGroup(gKey);
    }

    function dismissGroup(gKey) {
        const g = root.groups[gKey];
        if (g?.liveNotification)
            g.liveNotification.dismiss();
        else
            root._removeGroup(gKey);
    }

    function dismissAll() {
        const gKeys = Object.keys(root.groups);
        for (let i = 0; i < gKeys.length; i++) {
            const gKey = gKeys[i];
            const g = root.groups[gKey];
            if (g?.liveNotification) {
                g.liveNotification.dismiss();
            } else {
                root._removeGroup(gKey);
            }
        }
    }

    function sendAllToPanel() {
        popupGroupModel.clear();
    }
}
