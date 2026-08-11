pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.services

Item {
    id: root

    // groups[groupKey] = {
    //   appName, groupSummary,
    //   messages: [{ body, summary, image, appIcon, time }],
    //   liveNotification: <Notification | null>
    // }
    property var groups: ({})
    property bool dnd: false

    readonly property ListModel popupGroupModel: ListModel {}
    readonly property ListModel qsGroupModel: ListModel {}
    readonly property var history: []

    readonly property bool suppressPopups: PanelService.current?.suppressNotificationPopups ?? false

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

            const isCritical = notification.urgency?.toString() === "2";
            if ((!root.dnd || isCritical) && !root.suppressPopups)
                root._ensureGroupInModel(popupGroupModel, appName, groupSummary, gKey);
            root._ensureGroupInModel(qsGroupModel, appName, groupSummary, gKey);

            notification.closed.connect(reason => {
                if (reason === NotificationCloseReason.CloseRequested) {
                    const gs2 = Object.assign({}, root.groups);
                    if (gs2[gKey]) {
                        gs2[gKey] = Object.assign({}, gs2[gKey], {
                            liveNotification: null
                        });
                        root.groups = gs2;
                    }
                    popupCleanupTimer.schedule(gKey, appName, groupSummary);
                } else {
                    root._removeGroup(gKey);
                }
            });
        }
    }

    function _removeGroup(gKey) {
        const gs = Object.assign({}, root.groups);
        delete gs[gKey];
        root.groups = gs;
        _removeGroupFromModel(popupGroupModel, gKey);
        _removeGroupFromModel(qsGroupModel, gKey);
    }

    function _groupIndex(model, gKey) {
        for (let i = 0; i < model.count; i++)
            if (model.get(i).groupKey === gKey)
                return i;
        return -1;
    }

    function _ensureGroupInModel(model, appName, groupSummary, gKey) {
        if (_groupIndex(model, gKey) === -1) {
            model.insert(0, {
                appName,
                groupSummary,
                groupKey: gKey
            });
        }
    }

    function _removeGroupFromModel(model, gKey) {
        const idx = _groupIndex(model, gKey);
        if (idx !== -1)
            model.remove(idx);
    }

    function sendGroupToPanel(gKey) {
        _removeGroupFromModel(popupGroupModel, gKey);
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
