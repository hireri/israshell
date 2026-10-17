pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.windows
import qs.windows.components
import "format.js" as Fmt

PageBase {
    id: page

    title: Localization.t("systemApp.storage")
    subtitle: Localization.t("systemApp.storage_sub")

    property bool trashArmed: false

    readonly property var mounts: (HealthService.result("storage.mounts")?.mounts ?? []).slice().sort((a, b) => b.pct - a.pct)
    readonly property var fullest: page.mounts[0] ?? null
    readonly property var rootMount: page.mounts.find(m => m.mount === "/") ?? page.fullest
    readonly property string worst: HealthService.groupWorst.storage ?? ""
    readonly property string tone: page.worst === "bad" ? "bad" : page.worst === "warn" ? "warn" : page.worst === "" ? "neutral" : "ok"
    readonly property var reclaim: ["storage.trash", "pkg.cache", "storage.logs"].filter(id => HealthService.isApplicable(id) && HealthService.isEnabled(id))
    readonly property real reclaimable: (HealthService.result("storage.trash")?.bytes ?? 0) + (HealthService.result("pkg.cache")?.bytes ?? 0)
    readonly property var reclaimIcon: ({ "storage.trash": "delete", "pkg.cache": "inventory-2", "storage.logs": "history" })

    Component.onCompleted: HealthService.registerView()
    Component.onDestruction: HealthService.unregisterView()

    Timer {
        id: disarm
        interval: 4000
        onTriggered: page.trashArmed = false
    }

    HealthOffTile {
        Layout.fillWidth: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16
        visible: HealthService.enabled

        Hero {
            Layout.fillWidth: true
            tone: page.tone
            shape: "clover4"
            icon: "folder"
            title: !page.fullest || !page.rootMount ? Localization.t("systemApp.headline_checking") : page.fullest.pct >= 85 ? Localization.t("systemApp.storage_full").replace("%1", page.fullest.mount).replace("%2", page.fullest.pct) : Localization.t("systemApp.storage_free_on").replace("%1", Fmt.bytes(page.rootMount.total - page.rootMount.used)).replace("%2", page.rootMount.mount)
            sublabel: !page.fullest || !page.rootMount ? "" : page.reclaimable > 0 ? Localization.t("systemApp.storage_reclaim_sub").replace("%1", Fmt.bytes(page.reclaimable)) : Localization.t("systemApp.storage_clean_sub")

            Repeater {
                model: ["storage.smart", "storage.inodes"]

                Pill {
                    id: chip
                    required property string modelData

                    CheckInfo {
                        id: info
                        checkId: chip.modelData
                    }

                    visible: info.live && info.res !== null
                    implicitHeight: 24
                    tone: info.tone
                    dot: false
                    text: info.label + " · " + Localization.t("systemApp.sev_" + (info.sev || "checking"))
                }
            }

            actions: [
                ActionButton {
                    icon: "restart"
                    label: Localization.t("systemApp.refresh")
                    enabled: !HealthService.running
                    onClicked: HealthService.refresh()
                }
            ]
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: page.mounts.length > 0

            SectionLabel {
                text: Localization.t("systemApp.storage_volumes")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: page.mounts

                    ListRow {
                        id: vol
                        required property var modelData
                        required property int index
                        readonly property color accent: vol.modelData.pct >= 95 ? Colors.md3.error : vol.modelData.pct >= 85 ? Colors.md3.tertiary : Colors.md3.primary

                        Layout.fillWidth: true
                        topRadius: vol.index === 0 ? 18 : 6
                        bottomRadius: vol.index === page.mounts.length - 1 ? 18 : 6
                        title: vol.modelData.mount
                        sublabel: Fmt.bytes(vol.modelData.used) + " " + Localization.t("systemApp.of").replace("%1", Fmt.bytes(vol.modelData.total)) + " · " + vol.modelData.fstype

                        leading: [
                            ShapeIcon {
                                size: 34
                                shape: vol.modelData.pct >= 95 ? "burst" : vol.modelData.pct >= 85 ? "softBurst" : "clover4"
                                icon: "dns"
                                fill: vol.modelData.pct >= 95 ? Colors.md3.error : vol.modelData.pct >= 85 ? Colors.md3.tertiary : Colors.md3.primary_container
                                ink: vol.modelData.pct >= 95 ? Colors.md3.on_error : vol.modelData.pct >= 85 ? Colors.md3.on_tertiary : Colors.md3.on_primary_container
                            }
                        ]

                        UsageBar {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 120
                            implicitHeight: 8
                            width: 120
                            value: vol.modelData.pct / 100
                            fillColor: vol.accent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 84
                            horizontalAlignment: Text.AlignRight
                            text: Localization.t("systemApp.free_of_total").replace("%1", Fmt.bytes(vol.modelData.total - vol.modelData.used))
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Colors.md3.on_surface_variant
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: page.reclaim.length > 0

            SectionLabel {
                text: Localization.t("systemApp.storage_reclaimable")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: page.reclaim

                    CheckRow2 {
                        id: rec
                        required property string modelData
                        required property int index
                        readonly property int bytes: HealthService.result(rec.modelData)?.bytes ?? 0

                        Layout.fillWidth: true
                        checkId: rec.modelData
                        topRadius: rec.index === 0 ? 18 : 6
                        bottomRadius: rec.index === page.reclaim.length - 1 ? 18 : 6

                        leading: [
                            ShapeIcon {
                                size: 34
                                shape: "cookie6"
                                icon: page.reclaimIcon[rec.modelData]
                            }
                        ]

                        ActionButton {
                            visible: rec.modelData === "storage.trash" && rec.bytes > 0
                            danger: page.trashArmed
                            icon: "delete-forever"
                            label: page.trashArmed ? Localization.t("systemApp.confirm") : Localization.t("systemApp.empty")
                            onClicked: {
                                if (!page.trashArmed) {
                                    page.trashArmed = true;
                                    disarm.restart();
                                    return;
                                }
                                page.trashArmed = false;
                                HealthService.runAction("emptyTrash", "");
                            }
                        }

                        ActionButton {
                            visible: rec.modelData === "pkg.cache" && rec.bytes > 0
                            icon: "arrow-forward"
                            label: Localization.t("systemApp.open")
                            onClicked: SystemPages.openPage("packages")
                        }

                        ActionButton {
                            visible: rec.modelData === "storage.logs" && rec.bytes > 0
                            icon: "open-with"
                            label: Localization.t("systemApp.review")
                            onClicked: HealthService.runAction("reviewLogs", "")
                        }
                    }
                }
            }
        }

        DiskMap {
            Layout.fillWidth: true
        }
    }
}
