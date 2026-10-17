pragma Singleton
import QtQuick
import Quickshell
import qs.style
import qs.services
import "system/format.js" as Fmt

Singleton {
    id: root

    signal openPage(string key)

    readonly property var aliases: ({
        hardware: "system",
        services: "system",
        apps: "screentime",
        notifications: "screentime",
        healthsettings: "settings",
        wellbeingsettings: "settings"
    })

    readonly property var pages: [
        { key: "overview", titleKey: "systemApp.overview", icon: "overview", iconTransition: "wipe-right", group: 0, source: "SystemOverviewPage.qml" },
        { key: "packages", titleKey: "systemApp.packages", icon: "inventory-2", iconTransition: "wipe-up", group: 0, source: "PackagesPage.qml" },
        { key: "storage", titleKey: "systemApp.storage", icon: "folder", iconTransition: "wipe-right", group: 0, source: "StoragePage.qml" },
        { key: "system", titleKey: "systemApp.system", icon: "speed-3", iconTransition: "circle", group: 0, source: "SystemStatusPage.qml" },
        { key: "screentime", titleKey: "systemApp.screentime", icon: "analog-clock", iconTransition: "circle", group: 0, source: "ScreenTimePage.qml" },
        { key: "settings", titleKey: "systemApp.settings", icon: "settings", iconTransition: "none", group: 1, source: "SettingsPage.qml" }
    ]

    readonly property var groupIds: [0, 1]
    readonly property var pageKeys: root.pages.map(p => p.key)

    function resolve(key: string): string {
        return root.aliases[key] ?? key;
    }

    function pageDef(key: string): var {
        const k = root.resolve(key);
        return root.pages.find(p => p.key === k) ?? null;
    }

    function pageIndex(key: string): int {
        const k = root.resolve(key);
        return root.pages.findIndex(p => p.key === k);
    }

    function pageTitle(def: var): string {
        return Localization.t(def.titleKey);
    }

    function sublabel(key: string): string {
        switch (key) {
        case "overview":
            return HealthService.attention > 0 ? Localization.t("systemApp.sub_needs").replace("%1", HealthService.attention) : (HealthService.probed ? Localization.t("systemApp.sub_all_clear") : Localization.t("systemApp.sub_checking"));
        case "packages": {
            const n = (HealthService.result("updates.repo")?.count ?? 0) + (HealthService.result("updates.aur")?.count ?? 0) + (HealthService.result("updates.flatpak")?.count ?? 0);
            return HealthService.result("updates.repo") ? Localization.t("systemApp.sub_updates").replace("%1", n) : Localization.t("systemApp.sub_checking");
        }
        case "storage": {
            const m = HealthService.result("storage.mounts")?.mounts ?? [];
            const root_ = m.find(x => x.mount === "/");
            return root_ ? Localization.t("systemApp.sub_used").replace("%1", Math.round(root_.pct)) : Localization.t("systemApp.sub_checking");
        }
        case "system": {
            if (HealthService.result("sys.reboot")?.needed)
                return Localization.t("systemApp.sub_reboot");
            const d = (HealthService.result("svc.list")?.failed ?? []).length;
            if (d > 0)
                return Localization.t("systemApp.sub_down").replace("%1", d);
            const s = HealthService.result("hw.temps")?.sensors ?? [];
            const top = s.reduce((a, x) => Math.max(a, x.celsius), 0);
            return top > 0 ? Math.round(top) + "°C" : Localization.t("systemApp.sub_checking");
        }
        case "screentime":
            return ScreenTimeService.today.hasData ? Fmt.duration(ScreenTimeService.today.total) : Localization.t("systemApp.sub_no_data");
        case "settings":
            return ScreenTimeService.tracking ? Localization.t("systemApp.sub_recording") : Localization.t("systemApp.sub_not_recording");
        }
        return "";
    }
}
