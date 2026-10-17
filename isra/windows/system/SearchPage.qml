pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.services
import qs.icons
import qs.windows
import qs.windows.components
import "format.js" as Fmt
import "../../services/fuzzy.js" as Fuzzy

PageBase {
    id: page

    property string query: ""
    signal openPage(string key)

    readonly property string q: page.query.trim().toLowerCase()
    readonly property int limit: 8
    readonly property var groups: page.q === "" ? [] : page._build(page.q)
    readonly property int count: page.groups.reduce((a, g) => a + g.entries.length, 0)

    title: Localization.t("systemApp.search_results")
    subtitle: Localization.t("systemApp.results_count").replace("%1", page.count)

    Component.onCompleted: {
        HealthService.registerView();
        ScreenTimeService.registerView();
    }

    Component.onDestruction: {
        HealthService.unregisterView();
        ScreenTimeService.unregisterView();
    }

    function _score(text: string): var {
        return Fuzzy.scoreText(page.q, text.toLowerCase(), { exact: 1000, startsWith: 800, includes: 500, fuzzy: 200, lenPenalty: 1 });
    }

    function _pick(list: var, key: var): var {
        const out = [];
        for (const e of list) {
            const s = page._score(key(e));
            if (s !== undefined)
                out.push({ s: s, e: e });
        }
        out.sort((a, b) => b.s - a.s);
        return out.slice(0, page.limit).map(x => x.e);
    }

    function _build(q: string): var {
        const out = [];
        const add = (title, entries) => {
            if (entries.length > 0)
                out.push({ title: title, entries: entries });
        };
        const t = Localization.t;

        add(t("systemApp.search_pages"), page._pick(SystemPages.pages.map(p => ({ page: p.key, label: SystemPages.pageTitle(p), sublabel: SystemPages.sublabel(p.key), icon: p.icon })), e => e.label));

        const checks = [];
        for (const g of ["packages", "storage", "hardware", "services", "system"])
            for (const c of HealthService.checks(g))
                if (HealthService.isApplicable(c.id) && HealthService.isEnabled(c.id))
                    checks.push({ check: c.id, page: g === "packages" || g === "storage" ? g : "system", label: t("systemApp.check_" + c.id.replace(".", "_")) });
        add(t("systemApp.checks"), page._pick(checks, e => e.label));

        const updates = [];
        for (const s of [["updates.repo", "repo"], ["updates.aur", "AUR"], ["updates.flatpak", "Flatpak"]])
            for (const it of (HealthService.result(s[0])?.items ?? []))
                updates.push({ page: "packages", label: it.name, sublabel: it.from !== "" ? it.from + " → " + it.to : it.to, tag: s[1] });
        add(t("systemApp.pending_updates"), page._pick(updates, e => e.label));

        add(t("systemApp.news"), page._pick((HealthService.result("pkg.news")?.items ?? []).map(n => ({ page: "packages", label: n.title, sublabel: n.date > 0 ? Qt.formatDate(new Date(n.date), Qt.locale().dateFormat(Locale.ShortFormat)) : "", link: n.link })), e => e.label));

        add(t("systemApp.storage"), page._pick((HealthService.result("storage.mounts")?.mounts ?? []).map(m => ({ page: "storage", label: m.mount, sublabel: Fmt.bytes(m.used) + " / " + Fmt.bytes(m.total) + " · " + m.fstype, tag: m.pct + "%" })), e => e.label));

        const sys = [];
        for (const s of (HealthService.result("svc.list")?.services ?? []))
            sys.push({ page: "system", label: s.name, sublabel: t("systemApp.services"), tag: s.state === "failed" ? t("systemApp.svc_failed") : s.state === "run" ? t("systemApp.svc_running") : t("systemApp.svc_down"), tone: s.state === "failed" ? "bad" : s.state === "run" ? "ok" : "neutral", service: s.name });
        for (const s of (HealthService.result("hw.temps")?.sensors ?? []))
            sys.push({ page: "system", label: s.label !== "" ? s.label : s.name, sublabel: t("systemApp.temperatures"), tag: s.celsius.toFixed(0) + "°C" });
        add(t("systemApp.system"), page._pick(sys, e => e.label));

        add(t("systemApp.apps"), page._pick(ScreenTimeService.view.apps.map(a => ({ page: "screentime", label: ScreenTimeService.appName(a.id), sublabel: Fmt.duration(a.seconds), icon: "", iconName: ScreenTimeService.appIcon(a.id) })), e => e.label));

        const settings = ["appFocus", "hourly", "workspaces", "fullscreen", "media", "notifications", "unlocks", "windowTitles"].map(d => ({ page: "settings", label: t("screenTime.dim_" + d), sublabel: t("screenTime.dim_" + d + "_sub") }));
        settings.push(
            { page: "settings", label: t("screenTime.pause_tracking"), sublabel: t("screenTime.pause_tracking_sub") },
            { page: "settings", label: t("screenTime.idle_after"), sublabel: t("screenTime.idle_after_sub") },
            { page: "settings", label: t("screenTime.retention"), sublabel: t("screenTime.retention_sub") },
            { page: "settings", label: t("screenTime.excluded_apps"), sublabel: t("screenTime.excluded_sub") },
            { page: "settings", label: t("screenTime.export"), sublabel: t("screenTime.export_sub") },
            { page: "settings", label: t("screenTime.delete_all"), sublabel: t("screenTime.delete_all_sub") },
            { page: "settings", label: t("systemApp.interval"), sublabel: t("systemApp.interval_sub") }
        );
        add(t("systemApp.settings"), page._pick(settings, e => e.label + " " + e.sublabel));

        return out;
    }

    SectionCard {
        Layout.fillWidth: true
        visible: page.groups.length === 0

        SettingRow {
            label: Localization.t("systemApp.no_results")
            isLast: true
        }
    }

    Repeater {
        model: page.groups

        SectionCard {
            id: card
            required property var modelData
            label: card.modelData.title
            Layout.fillWidth: true

            Repeater {
                model: card.modelData.entries

                Item {
                    id: hit
                    required property var modelData
                    required property int index

                    width: parent?.width ?? 0
                    height: row.implicitHeight

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.openPage(hit.modelData.page)
                    }

                    SettingRow {
                        id: row
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        compact: true
                        isLast: hit.index === card.modelData.entries.length - 1
                        label: hit.modelData.label
                        sublabel: hit.modelData.sublabel ?? ""
                        iconSource: (hit.modelData.iconName ?? "") !== "" ? Quickshell.iconPath(hit.modelData.iconName, true) : ""

                        MaterialIcon {
                            visible: (hit.modelData.icon ?? "") !== ""
                            anchors.verticalCenter: parent?.verticalCenter
                            name: hit.modelData.icon ?? "search"
                            iconSize: 18
                            color: Colors.md3.outline
                        }

                        StatusTag {
                            text: hit.modelData.tag ?? ""
                            tone: hit.modelData.tone ?? "neutral"
                        }

                        ActionButton {
                            visible: hit.modelData.service !== undefined
                            icon: "restart"
                            label: Localization.t("systemApp.restart")
                            onClicked: HealthService.runAction("restartService", hit.modelData.service)
                        }

                        ActionButton {
                            visible: hit.modelData.link !== undefined
                            icon: "arrow-outward"
                            label: Localization.t("systemApp.read")
                            onClicked: HealthService.runAction("openNews", hit.modelData.link)
                        }
                    }
                }
            }
        }
    }
}
