pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.services
import qs.style

Item {
    id: root

    // groups[groupKey] = {
    //   appName, groupSummary,
    //   messages: [{ body, summary, image, appIcon, time, notifId }],
    //   liveNotification: <Notification | null>
    // }
    function _notifId(appName, summary, body) {
        return appName + "\u001f" + summary + "\u001f" + body;
    }
    property var groups: ({})
    property bool dnd: false

    readonly property ListModel popupGroupModel: ListModel {}
    readonly property ListModel qsGroupModel: ListModel {}
    readonly property ListModel historyModel: ListModel {}
    readonly property int historyLimit: 50

    readonly property int visibleHistoryCount: {
        let n = 0;
        for (let i = 0; i < historyModel.count; i++)
            if (!root.groups[historyModel.get(i).groupKey ?? ""])
                n++;
        return n;
    }

    function isGroupLive(gKey) {
        return gKey !== undefined && root.groups[gKey] !== undefined;
    }

    readonly property bool suppressPopups: PanelService.current?.suppressNotificationPopups ?? false

    Item {
        id: popupCleanupTimer
        property var _pending: ({})

        Component {
            id: cleanupTimerComponent
            Timer { interval: 600; repeat: false }
        }

        function schedule(gKey, appName, groupSummary) {
            if (_pending[gKey]) {
                _pending[gKey].restart();
                return;
            }
            const t = cleanupTimerComponent.createObject(popupCleanupTimer);
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

            console.log("[Notification]", JSON.stringify({
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency?.toString(),
                hints: notification.hints
            }, null, 2));

            const appName = notification.appName || "Unknown";
            const groupSummary = notification.summary || "";
            const gKey = appName + "|" + groupSummary;

            const msg = {
                body: notification.body || "",
                summary: groupSummary,
                image: notification.image || "",
                appIcon: notification.appIcon || "",
                desktopEntry: notification.desktopEntry || "",
                materialIcon: notification.hints?.["x-material-icon"] ?? "",
                time: Date.now(),
                notifId: root._notifId(appName, groupSummary, notification.body || "")
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
            root._captureHistory(gKey);

            const isCritical = notification.urgency?.toString() === "2";

            const hints = notification.hints || {};
            const isSilencedApp = Config.sounds.silentApps.some(a => a.toLowerCase() === appName.toLowerCase());
            if (!hints["suppress-sound"] && !isSilencedApp && (!root.dnd || isCritical))
                SoundService.notification(isCritical);

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
        root._releaseHistory(gKey);

        const gs = Object.assign({}, root.groups);
        delete gs[gKey];
        root.groups = gs;
        _removeGroupFromModel(popupGroupModel, gKey);
        _removeGroupFromModel(qsGroupModel, gKey);
    }

    function _captureHistory(gKey) {
        const g = root.groups[gKey];
        if (!g || g.messages.length === 0)
            return;
        const latest = g.messages[g.messages.length - 1];
        const nId = latest.notifId ?? root._notifId(g.appName, latest.summary, latest.body);
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).notifId === nId) {
                historyModel.remove(i);
                break;
            }
        }
        historyModel.insert(0, {
            appName: g.appName,
            groupSummary: g.groupSummary,
            groupKey: gKey,
            body: latest.body,
            summary: latest.summary,
            image: latest.image,
            appIcon: latest.appIcon,
            desktopEntry: latest.desktopEntry,
            materialIcon: latest.materialIcon,
            time: latest.time,
            urgency: g.urgency,
            count: g.messages.length,
            notifId: nId,
            live: true
        });
        while (historyModel.count > root.historyLimit)
            historyModel.remove(historyModel.count - 1);
        _writeHistoryDebouncer.restart();
    }

    function _releaseHistory(gKey) {
        for (let i = 0; i < historyModel.count; i++) {
            const e = historyModel.get(i);
            if (e.groupKey === gKey && e.live) {
                historyModel.setProperty(i, "live", false);
                _writeHistoryDebouncer.restart();
                return;
            }
        }
    }

    function removeHistoryEntry(index) {
        historyModel.remove(index);
        _writeHistoryDebouncer.restart();
    }

    function clearHistory() {
        historyModel.clear();
        _writeHistoryDebouncer.restart();
    }

    function _loadHistory() {
        try {
            const text = historyFile.text();
            if (!text)
                return;
            const entries = JSON.parse(text);
            const seen = {};
            for (const entry of entries) {
                entry.groupKey = entry.groupKey ?? "";
                entry.live = false;
                entry.notifId = entry.notifId ?? root._notifId(entry.appName ?? "", entry.summary ?? "", entry.body ?? "");
                if (seen[entry.notifId])
                    continue;
                seen[entry.notifId] = true;
                historyModel.append(entry);
            }
        } catch (e) {
            console.log("NotificationService: history load failed:", e);
        }
    }

    function _writeHistory() {
        const entries = [];
        for (let i = 0; i < historyModel.count; i++)
            entries.push(historyModel.get(i));
        historyFile.setText(JSON.stringify(entries, null, 2));
    }

    Timer {
        id: _writeHistoryDebouncer
        interval: 300
        onTriggered: root._writeHistory()
    }

    FileView {
        id: historyFile
        path: Config.configDir + "/notification_history.json"
        watchChanges: false
        blockLoading: true
        Component.onCompleted: root._loadHistory()
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
