pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.services
import qs.windows
import qs.windows.components
import qs.components
import "format.js" as Fmt

PageBase {
    id: page

    title: Localization.t("systemApp.system")
    subtitle: Localization.t("systemApp.system_sub")

    property bool allServices: false
    property string svcFilter: "all"
    property string svcPicked: ""

    readonly property bool colored: Config.sysMonitor?.colored ?? true
    readonly property var reboot: HealthService.result("sys.reboot")
    readonly property bool rebootNeeded: page.reboot?.needed === true
    readonly property var sync: HealthService.result("sys.timesync")
    readonly property var batteries: HealthService.result("hw.battery")?.batteries ?? []
    readonly property var services: HealthService.result("svc.list")?.services ?? []
    readonly property var chips: {
        const by = {};
        (HealthService.result("hw.temps")?.sensors ?? []).forEach(s => {
            (by[s.name] = by[s.name] ?? []).push(s);
        });
        return Object.keys(by).map(n => ({
            name: n,
            max: by[n].reduce((m, s) => Math.max(m, s.celsius), 0),
            sensors: by[n].slice().sort((a, b) => b.celsius - a.celsius)
        })).sort((a, b) => b.max - a.max);
    }
    readonly property var svcAll: {
        const rank = st => ({ failed: 0, down: 1, run: 2 })[st];
        return page.services.map(s => ({
            name: s.name,
            scope: s.scope ?? "system",
            state: s.state,
            tone: s.state === "failed" ? "bad" : s.state === "run" ? "ok" : "neutral",
            sub: s.state === "failed" ? Localization.t("systemApp.svc_failed") : s.state === "run" ? (s.seconds !== null ? Localization.t("systemApp.svc_up_for").replace("%1", Fmt.ago(0, s.seconds * 1000)) : Localization.t("systemApp.svc_running")) : s.normallyUp ? Localization.t("systemApp.svc_stopped") : Localization.t("systemApp.svc_off_boot"),
            manage: true
        })).sort((a, b) => (rank(a.state) - rank(b.state)) || a.name.localeCompare(b.name));
    }
    readonly property var svcShown: {
        const f = page.svcAll.filter(r => page.svcFilter === "all" || (page.svcFilter === "run") === (r.state === "run"));
        return page.allServices ? f : f.slice(0, 12);
    }
    readonly property int svcFiltered: page.svcAll.filter(r => page.svcFilter === "all" || (page.svcFilter === "run") === (r.state === "run")).length
    readonly property var svcSel: page.svcShown.find(r => r.name === page.svcPicked) ?? page.svcShown[0] ?? null
    readonly property int svcRunning: page.svcAll.filter(r => r.state === "run").length
    readonly property int svcStopped: page.svcAll.filter(r => r.state === "down").length
    readonly property int svcFailed: page.svcAll.filter(r => r.state === "failed").length
    readonly property string svcTone: page.svcSel?.tone === "bad" || page.svcSel?.tone === "ok" ? page.svcSel.tone : ""

    function svcSub(r: var): string {
        return r.sub + (r.scope === "user" ? " · " + Localization.t("systemApp.svc_user") : "");
    }

    function metricColor(id: string): color {
        return page.colored ? SystemInfo.metrics.find(m => m.id === id).color : Colors.md3.primary;
    }

    function metricInk(id: string): color {
        if (!page.colored)
            return Colors.md3.on_primary;
        return ({ cpu: Colors.md3.on_primary, ram: Colors.md3.on_tertiary, gpu: Colors.md3.on_secondary, temp: Colors.md3.on_error })[id];
    }

    function tempTone(c: real): string {
        return c >= 90 ? "bad" : c >= 80 ? "warn" : "neutral";
    }

    function loadTone(pct: real, warn: real, bad: real): string {
        return pct >= bad ? "bad" : pct >= warn ? "warn" : "neutral";
    }

    function dash(parts: var): string {
        return parts.filter(s => s && s !== "—").join(" · ");
    }

    Component.onCompleted: {
        HealthService.registerView();
        SystemInfo.registerLiveConsumer();
    }

    Component.onDestruction: {
        HealthService.unregisterView();
        SystemInfo.unregisterLiveConsumer();
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16

        Hero {
            Layout.fillWidth: true
            tone: page.rebootNeeded ? "warn" : "neutral"
            shape: "cookie9"
            image: Quickshell.iconPath(SystemInfo.logo, "distributor-logo-linux")
            title: SystemInfo.distroName
            sublabel: page.dash([SystemInfo.hostname, SystemInfo.kernel, Localization.t("systemApp.uptime").replace("%1", SystemInfo.uptime)])

            Pill {
                implicitHeight: 24
                dot: false
                text: SystemInfo.session
            }

            Pill {
                visible: page.sync !== null && page.sync.severity !== "unavailable"
                implicitHeight: 24
                tone: page.sync?.severity === "warn" ? "warn" : "ok"
                dot: false
                text: Localization.t("systemApp.check_sys_timesync") + " · " + (page.sync?.synced === false ? Localization.t("systemApp.not_synced") : Localization.t("systemApp.synced"))
            }

            Pill {
                visible: page.rebootNeeded
                implicitHeight: 24
                tone: "warn"
                dot: false
                text: Localization.t("systemApp.reboot_why").replace("%1", page.reboot?.running ?? "").replace("%2", page.reboot?.installed ?? "")
            }

            actions: [
                ActionButton {
                    visible: page.rebootNeeded
                    danger: true
                    icon: "restart"
                    label: Localization.t("systemApp.reboot")
                    onClicked: HealthService.runAction("reboot", "")
                }
            ]
        }

        SectionLabel {
            text: Localization.t("systemApp.performance")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width > 560 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 12
            uniformCellWidths: true

            MetricCard {
                Layout.fillWidth: true
                label: Localization.t("sysMonitor.cpu")
                icon: "memory"
                shape: "cookie9"
                tone: page.loadTone(SystemInfo.cpuUsage, 75, 90)
                accent: page.metricColor("cpu")
                accentInk: page.metricInk("cpu")
                value: Math.round(SystemInfo.cpuUsage) + "%"
                sublabel: page.dash([SystemInfo.cpu.replace(/ \d+-Core| Processor| CPU/gi, "").trim(), SystemInfo.cpuFreq, SystemInfo.cpuPower])
                history: SystemInfo.cpuHistory
            }

            MetricCard {
                Layout.fillWidth: true
                label: Localization.t("sysMonitor.ram")
                icon: "memory-alt"
                shape: "clover4"
                tone: page.loadTone(SystemInfo.ramUsage, 85, 95)
                accent: page.metricColor("ram")
                accentInk: page.metricInk("ram")
                value: Math.round(SystemInfo.ramUsage) + "%"
                sublabel: page.dash([SystemInfo.ramUsedLabel + " / " + SystemInfo.ramTotalLabel, SystemInfo.swapTotalLabel !== "—" && SystemInfo.swapTotalLabel !== "0 MB" ? Localization.t("sysMonitor.swap") + " " + SystemInfo.swapUsedLabel : ""])
                history: SystemInfo.ramHistory
            }

            MetricCard {
                Layout.fillWidth: true
                visible: SystemInfo.gpuUsage >= 0
                label: Localization.t("sysMonitor.gpu")
                icon: "videogame-asset"
                shape: "softBurst"
                tone: page.loadTone(SystemInfo.gpuUsage, 85, 95)
                accent: page.metricColor("gpu")
                accentInk: page.metricInk("gpu")
                value: Math.round(SystemInfo.gpuUsage) + "%"
                sublabel: page.dash([SystemInfo.gpu.replace(/AMD |NVIDIA |Intel /gi, "").trim(), SystemInfo.gpuFreq, SystemInfo.gpuPower])
                history: SystemInfo.gpuHistory
            }

            MetricCard {
                Layout.fillWidth: true
                Layout.columnSpan: SystemInfo.gpuUsage < 0 && parent.columns > 1 ? 2 : 1
                visible: SystemInfo.cpuTemp >= 0 || SystemInfo.gpuTemp >= 0
                label: Localization.t("sysMonitor.temp")
                icon: "thermostat"
                shape: "cookie6"
                tone: page.tempTone(Math.max(SystemInfo.cpuTemp, SystemInfo.gpuTemp))
                accent: page.metricColor("temp")
                accentInk: page.metricInk("temp")
                value: Math.round(Math.max(SystemInfo.cpuTempDisplay, SystemInfo.gpuTempDisplay)) + SystemInfo.tempUnit
                sublabel: page.dash([SystemInfo.cpuTemp >= 0 ? "CPU " + Math.round(SystemInfo.cpuTempDisplay) + "°" : "", SystemInfo.gpuTemp >= 0 ? "GPU " + Math.round(SystemInfo.gpuTempDisplay) + "°" : ""])
                history: SystemInfo.metricHistory("temp")
                scaleMax: SystemInfo.metricScale("temp")
            }
        }

        SectionLabel {
            visible: page.batteries.length > 0
            text: Localization.t("systemApp.battery")
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: page.batteries.length > 0
            spacing: 2

            Repeater {
                model: page.batteries

                ListRow {
                    id: bat
                    required property var modelData
                    required property int index
                    readonly property bool low: (bat.modelData.percent ?? 100) <= 15

                    Layout.fillWidth: true
                    topRadius: bat.index === 0 ? 18 : 6
                    bottomRadius: bat.index === page.batteries.length - 1 ? 18 : 6
                    title: bat.modelData.name
                    sublabel: page.dash([bat.modelData.status, bat.modelData.healthPct !== null ? Localization.t("systemApp.det_battery_health").replace("%1", bat.modelData.healthPct) : "", bat.modelData.cycles !== null ? Localization.t("systemApp.det_cycles").replace("%1", bat.modelData.cycles) : ""])

                    leading: [
                        ShapeIcon {
                            size: 34
                            shape: bat.low ? "burst" : "cookie6"
                            icon: "battery-android-full"
                            fill: bat.low ? Colors.md3.error : Colors.md3.primary_container
                            ink: bat.low ? Colors.md3.on_error : Colors.md3.on_primary_container
                        }
                    ]

                    Pill {
                        tone: bat.low ? "bad" : "ok"
                        dot: false
                        text: bat.modelData.percent !== null ? bat.modelData.percent + "%" : "—"
                    }
                }
            }
        }

        SectionLabel {
            visible: page.chips.length > 0
            text: Localization.t("systemApp.temperatures")
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: page.chips.length > 0
            spacing: 2

            Repeater {
                model: page.chips

                ListRow {
                    id: chip
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    topRadius: chip.index === 0 ? 18 : 6
                    bottomRadius: chip.index === page.chips.length - 1 ? 18 : 6
                    title: chip.modelData.name
                    sublabel: chip.modelData.sensors.slice(0, 4).map(s => (s.label !== "" ? s.label + " " : "") + Math.round(s.celsius) + "°").join(" · ")

                    leading: [
                        ShapeIcon {
                            size: 34
                            shape: "cookie6"
                            icon: "thermostat"
                        }
                    ]

                    Pill {
                        tone: page.tempTone(chip.modelData.max)
                        dot: false
                        text: Math.round(chip.modelData.max) + "°C"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: page.svcAll.length > 0
            spacing: 10

            SectionLabel {
                Layout.fillWidth: true
                text: Localization.t("systemApp.services").toUpperCase() + " · " + [page.svcFailed > 0 ? Localization.t("systemApp.n_failed").replace("%1", page.svcFailed) : "", Localization.t("systemApp.n_running").replace("%1", page.svcRunning), page.svcStopped > 0 ? Localization.t("systemApp.n_stopped").replace("%1", page.svcStopped) : ""].filter(x => x).join(" · ")
            }

            ChipRow {
                options: [
                    { value: "all", label: Localization.t("systemApp.svc_all") },
                    { value: "run", label: Localization.t("systemApp.svc_running") },
                    { value: "down", label: Localization.t("systemApp.svc_down") }
                ]
                currentValue: page.svcFilter
                onSelected: v => page.svcFilter = v
            }
        }

        Hero {
            Layout.fillWidth: true
            visible: page.svcSel !== null
            tone: page.svcSel?.tone === "bad" ? "bad" : page.svcSel?.tone === "ok" ? "ok" : "neutral"
            shape: page.svcSel?.tone === "bad" ? "burst" : page.svcSel?.tone === "ok" ? "cookie9" : "circle"
            icon: page.svcSel?.tone === "bad" ? "error" : page.svcSel?.tone === "ok" ? "check" : "close"
            title: page.svcSel?.name ?? ""
            sublabel: page.svcSel ? page.svcSub(page.svcSel) : ""

            actions: [
                ActionButton {
                    visible: page.svcSel?.manage === true
                    primary: true
                    tone: page.svcTone
                    icon: "restart"
                    label: Localization.t("systemApp.restart")
                    onClicked: HealthService.runAction("restartService", page.svcSel.name, page.svcSel.scope)
                },
                ActionButton {
                    visible: page.svcSel?.manage === true
                    tone: page.svcTone
                    label: page.svcSel?.state === "run" ? Localization.t("systemApp.svc_stop") : Localization.t("systemApp.svc_start")
                    onClicked: HealthService.runAction(page.svcSel.state === "run" ? "stopService" : "startService", page.svcSel.name, page.svcSel.scope)
                },
                ActionButton {
                    visible: page.svcSel?.manage === true
                    tone: page.svcTone
                    label: Localization.t("systemApp.svc_logs")
                    onClicked: HealthService.runAction("serviceLogs", page.svcSel.name, page.svcSel.scope)
                }
            ]
        }

        GridLayout {
            Layout.fillWidth: true
            visible: page.svcAll.length > 0
            columns: width > 760 ? 3 : width > 480 ? 2 : 1
            columnSpacing: 8
            rowSpacing: 8
            uniformCellWidths: true

            Repeater {
                model: page.svcShown

                ServiceTile {
                    id: tile
                    required property var modelData

                    Layout.fillWidth: true
                    name: tile.modelData.name
                    sublabel: page.svcSub(tile.modelData)
                    tone: tile.modelData.tone
                    selected: page.svcSel?.name === tile.modelData.name
                    onClicked: page.svcPicked = tile.modelData.name
                }
            }
        }

        ActionButton {
            Layout.alignment: Qt.AlignHCenter
            visible: page.svcFiltered > 12
            label: page.allServices ? Localization.t("systemApp.show_less") : Localization.t("systemApp.show_all").replace("%1", page.svcFiltered)
            onClicked: page.allServices = !page.allServices
        }
    }
}
