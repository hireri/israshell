import QtQuick
import qs.style
import qs.services
import "format.js" as Fmt

QtObject {
    id: root

    property string checkId: ""
    property string detail: ""

    readonly property var res: HealthService.results[root.checkId] ?? null
    readonly property string sev: root.res ? root.res.severity : ""
    readonly property bool live: HealthService.isApplicable(root.checkId) && HealthService.isEnabled(root.checkId)
    readonly property string label: Localization.t("systemApp.check_" + root.checkId.replace(".", "_"))
    readonly property string text: root._text()
    readonly property string tone: root.sev === "bad" ? "bad" : root.sev === "warn" ? "warn" : root.sev === "ok" ? "ok" : root.sev === "info" ? "primary" : "neutral"

    function _n(key: string, n: int): string {
        return Localization.t(key).replace("%1", n);
    }

    function _auto(id: string, r: var): string {
        switch (id) {
        case "updates.repo":
        case "updates.aur":
        case "updates.flatpak":
            return r.count > 0 ? root._n("systemApp.det_updates", r.count) : Localization.t("systemApp.det_up_to_date");
        case "pkg.orphans":
            return r.count > 0 ? (r.bytes === null ? root._n("systemApp.det_orphans_count", r.count) : root._n("systemApp.det_orphans", r.count).replace("%2", Fmt.bytes(r.bytes))) : Localization.t("systemApp.det_none");
        case "pkg.pacnew":
            return r.count > 0 ? root._n("systemApp.det_pacnew", r.count) : Localization.t("systemApp.det_none");
        case "pkg.cache":
            return Fmt.bytes(r.bytes);
        case "pkg.deps":
            return r.issues.length > 0 ? root._n("systemApp.det_dep_issues", r.issues.length) : Localization.t("systemApp.det_consistent");
        case "pkg.news":
            return r.unread > 0 ? root._n("systemApp.det_news", r.unread) : Localization.t("systemApp.det_no_news");
        case "storage.mounts":
        case "storage.inodes": {
            const w = r.mounts.reduce((a, m) => (m.pct ?? -1) > (a?.pct ?? -1) ? m : a, null);
            return w ? Localization.t("systemApp.det_fullest").replace("%1", w.mount).replace("%2", w.pct) : Localization.t("systemApp.det_none");
        }
        case "storage.smart":
            return r.passed === false ? Localization.t("systemApp.det_smart_fail") : (r.percentUsed !== null ? root._n("systemApp.det_wear", r.percentUsed) : (r.device ?? Localization.t("systemApp.det_healthy")));
        case "storage.trash":
        case "storage.logs":
            return Fmt.bytes(r.bytes);
        case "hw.temps": {
            const top = r.sensors.reduce((a, s) => Math.max(a, s.celsius), 0);
            return top > 0 ? Localization.t("systemApp.det_hottest").replace("%1", Math.round(top)) : Localization.t("systemApp.det_none");
        }
        case "hw.battery":
            return r.present ? (r.batteries[0].healthPct !== null ? root._n("systemApp.det_battery_health", r.batteries[0].healthPct) : Localization.t("systemApp.det_healthy")) : Localization.t("systemApp.det_no_battery");
        case "svc.list":
            return r.failed.length > 0 ? r.failed.join(", ") : Localization.t("systemApp.n_running").replace("%1", r.services.filter(s => s.state === "run").length);
        case "sys.reboot":
            return r.needed ? Localization.t("systemApp.det_reboot").replace("%1", r.running).replace("%2", r.installed) : Localization.t("systemApp.det_current_kernel");
        case "sys.timesync":
            return r.synced ? Localization.t("systemApp.det_synced") : Localization.t("systemApp.det_not_synced");
        case "sys.memory":
            return Localization.t("systemApp.det_memory").replace("%1", Fmt.bytes(r.memTotal - r.memAvailable)).replace("%2", Fmt.bytes(r.memTotal));
        }
        return "";
    }

    function _text(): string {
        if (root.detail !== "")
            return root.detail;
        if (!root.res)
            return Localization.t("systemApp.sub_checking");
        if (root.sev === "unavailable")
            return Localization.t("systemApp.reason_" + (root.res.reason ?? "failed"));
        if (root.sev === "permission")
            return Localization.t("systemApp.reason_permission");
        return root._auto(root.checkId, root.res);
    }
}
