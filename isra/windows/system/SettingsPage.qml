pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.icons
import qs.windows
import qs.windows.components
import qs.components

PageBase {
    id: page

    title: Localization.t("systemApp.settings")
    subtitle: Localization.t("systemApp.settings_sub")

    readonly property var groups: ["packages", "storage", "hardware", "services", "system"]

    property bool deleteArmed: false
    property string notice: ""

    readonly property var dimensions: ["appFocus", "hourly", "workspaces", "fullscreen", "media", "notifications", "unlocks", "windowTitles"]
    readonly property var excluded: ScreenTimeService.cfg.excluded
    readonly property string storageText: ScreenTimeService.storageError === "openssl" ? Localization.t("screenTime.store_openssl") : ScreenTimeService.storageError === "unreadable" ? Localization.t("screenTime.store_unreadable") : ScreenTimeService.storageError === "write" ? Localization.t("screenTime.store_write") : Localization.t("screenTime.store_ok")

    Timer {
        id: disarm
        interval: 4000
        onTriggered: page.deleteArmed = false
    }

    Connections {
        target: ScreenTimeService

        function onExported(path) {
            page.notice = Localization.t("screenTime.exported").replace("%1", path);
        }

        function onExportFailed() {
            page.notice = Localization.t("screenTime.export_failed");
        }

        function onDataDeleted() {
            page.notice = Localization.t("screenTime.deleted");
        }
    }

    HeroCard {
        Layout.fillWidth: true
        title: Localization.t("systemApp.health_checks")
        subtitle: HealthService.enabled ? Localization.t("systemApp.health_on") : Localization.t("systemApp.health_off")
        cardColor: Colors.md3.surface_container
        checked: HealthService.enabled
        onToggled: v => HealthService.setOption("enabled", v)

        MaterialIcon {
            name: "overview"
            iconSize: 22
            color: Colors.md3.primary
        }
    }

    SectionCard {
        label: Localization.t("systemApp.schedule")
        Layout.fillWidth: true

        SettingChips {
            label: Localization.t("systemApp.interval")
            sublabel: Localization.t("systemApp.interval_sub")
            enabled: HealthService.enabled
            options: [
                { value: 15, label: "15m" },
                { value: 30, label: "30m" },
                { value: 60, label: "1h" },
                { value: 180, label: "3h" },
                { value: 720, label: "12h" }
            ]
            currentValue: HealthService.cfg.intervalMinutes
            onSelected: v => HealthService.setOption("intervalMinutes", v)
        }

        SettingChips {
            label: Localization.t("systemApp.bar_chip")
            sublabel: Localization.t("systemApp.bar_chip_sub")
            enabled: HealthService.enabled
            options: [
                { value: "info", label: Localization.t("systemApp.chip_info") },
                { value: "warn", label: Localization.t("systemApp.chip_warn") },
                { value: "bad", label: Localization.t("systemApp.chip_bad") },
                { value: "always", label: Localization.t("systemApp.chip_always") }
            ]
            currentValue: HealthService.cfg.barChipLevel
            onSelected: v => HealthService.setOption("barChipLevel", v)
        }
    }

    Repeater {
        model: page.groups

        SectionCard {
            id: card
            required property string modelData
            label: Localization.t("systemApp." + card.modelData)
            Layout.fillWidth: true

            Repeater {
                model: HealthService.checks(card.modelData)

                SettingSwitch {
                    id: row
                    required property var modelData
                    label: Localization.t("systemApp.check_" + row.modelData.id.replace(".", "_"))
                    sublabel: HealthService.probed && !HealthService.isApplicable(row.modelData.id) ? Localization.t("systemApp.not_available") : ""
                    enabled: HealthService.probed && HealthService.isApplicable(row.modelData.id)
                    checked: HealthService.isEnabled(row.modelData.id)
                    onToggled: v => HealthService.setCheckEnabled(row.modelData.id, v)
                }
            }
        }
    }

    HeroCard {
        Layout.fillWidth: true
        title: Localization.t("screenTime.record")
        subtitle: !ScreenTimeService.enabled ? Localization.t("screenTime.tracking_off") : ScreenTimeService.paused ? Localization.t("screenTime.tracking_paused") : Localization.t("screenTime.tracking_on")
        cardColor: Colors.md3.surface_container
        checked: ScreenTimeService.enabled
        onToggled: v => ScreenTimeService.setOption("enabled", v)

        MaterialIcon {
            name: "history"
            iconSize: 22
            color: Colors.md3.primary
        }
    }

    SectionCard {
        label: Localization.t("screenTime.what_recorded")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("screenTime.pause_tracking")
            sublabel: Localization.t("screenTime.pause_tracking_sub")
            enabled: ScreenTimeService.enabled
            checked: ScreenTimeService.paused
            onToggled: v => ScreenTimeService.setOption("paused", v)
        }

        Repeater {
            model: page.dimensions

            SettingSwitch {
                id: dim
                required property string modelData
                label: Localization.t("screenTime.dim_" + dim.modelData)
                sublabel: Localization.t("screenTime.dim_" + dim.modelData + "_sub")
                enabled: ScreenTimeService.enabled
                checked: ScreenTimeService.cfg[dim.modelData]
                onToggled: v => ScreenTimeService.setOption(dim.modelData, v)
            }
        }
    }

    SectionCard {
        label: Localization.t("screenTime.timing")
        Layout.fillWidth: true

        SettingSlider {
            label: Localization.t("screenTime.idle_after")
            sublabel: Localization.t("screenTime.idle_after_sub")
            from: 30
            to: 600
            stepSize: 30
            unit: "s"
            value: ScreenTimeService.cfg.idleSeconds
            onMoved: v => ScreenTimeService.setOption("idleSeconds", v)
        }

        SettingChips {
            label: Localization.t("screenTime.retention")
            sublabel: Localization.t("screenTime.retention_sub")
            options: [
                { value: 30, label: "30d" },
                { value: 90, label: "90d" },
                { value: 180, label: "180d" },
                { value: 365, label: "1y" },
                { value: 0, label: Localization.t("screenTime.forever") }
            ]
            currentValue: ScreenTimeService.cfg.retentionDays
            onSelected: v => ScreenTimeService.setOption("retentionDays", v)
        }
    }

    SectionCard {
        label: Localization.t("screenTime.excluded")
        Layout.fillWidth: true

        SettingRow {
            label: Localization.t("screenTime.excluded_apps")
            sublabel: page.excluded.length === 0 ? Localization.t("screenTime.excluded_none") : Localization.t("screenTime.excluded_sub")
            stack: page.excluded.length > 0

            Flow {
                width: Math.min(560, page.width - 140)
                spacing: 6
                visible: page.excluded.length > 0

                Repeater {
                    model: page.excluded

                    InputChip {
                        id: chip
                        required property string modelData
                        label: ScreenTimeService.appName(chip.modelData)
                        onRemoved: ScreenTimeService.include(chip.modelData)
                    }
                }
            }
        }
    }

    SectionCard {
        label: Localization.t("screenTime.data")
        Layout.fillWidth: true

        SettingRow {
            label: Localization.t("screenTime.storage")
            sublabel: page.storageText

            StatusTag {
                text: ScreenTimeService.storageError === "" ? Localization.t("screenTime.encrypted") : Localization.t("screenTime.attention")
                tone: ScreenTimeService.storageError === "" ? "ok" : "warn"
            }
        }

        SettingRow {
            label: Localization.t("screenTime.export")
            sublabel: page.notice !== "" ? page.notice : Localization.t("screenTime.export_sub")

            ActionButton {
                icon: "download-for-offline"
                label: Localization.t("screenTime.export")
                onClicked: {
                    page.notice = "";
                    ScreenTimeService.exportData();
                }
            }
        }

        SettingRow {
            label: Localization.t("screenTime.delete_all")
            sublabel: Localization.t("screenTime.delete_all_sub")

            ActionButton {
                danger: true
                icon: "delete-forever"
                label: page.deleteArmed ? Localization.t("systemApp.confirm") : Localization.t("screenTime.delete")
                onClicked: {
                    if (!page.deleteArmed) {
                        page.deleteArmed = true;
                        disarm.restart();
                        return;
                    }
                    page.deleteArmed = false;
                    ScreenTimeService.deleteAll();
                }
            }
        }
    }
}
