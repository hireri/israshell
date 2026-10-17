pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.icons
import qs.components
import qs.windows
import qs.windows.components
import "format.js" as Fmt

PageBase {
    id: page

    title: Localization.t("systemApp.overview")
    subtitle: Localization.t("systemApp.overview_sub")

    property bool slow: false

    readonly property var areas: ["packages", "storage", "hardware", "services", "system"]
    readonly property var areaPage: ({ packages: "packages", storage: "storage", hardware: "system", services: "system", system: "system" })
    readonly property var areaShape: ({ packages: "cookie6", storage: "clover4", hardware: "sunny", services: "pill", system: "gem" })
    readonly property var areaIcon: ({ packages: "inventory-2", storage: "folder", hardware: "thermostat", services: "automation", system: "memory" })
    readonly property var attention: {
        const out = [];
        for (const g of page.areas)
            for (const c of HealthService.checks(g)) {
                const r = HealthService.results[c.id];
                if (r && HealthService.isApplicable(c.id) && HealthService.isEnabled(c.id) && HealthService.hidden[c.id] !== true && (r.severity === "warn" || r.severity === "bad"))
                    out.push({ id: c.id, area: g, bad: r.severity === "bad" });
            }
        return out;
    }

    readonly property bool checking: HealthService.enabled && (!HealthService.probed || (Object.keys(HealthService.groupWorst).length === 0 && HealthService.running))
    readonly property string phase: !HealthService.enabled ? "off" : page.checking ? "checking" : Object.keys(HealthService.groupWorst).length === 0 ? "ok" : HealthService.worst === "bad" ? "bad" : HealthService.attention > 0 ? "warn" : "ok"
    readonly property color heroBg: page.phase === "bad" ? Colors.md3.error_container : page.phase === "warn" ? Colors.md3.tertiary_container : page.phase === "ok" ? Colors.md3.primary_container : Config.dim(Colors.md3.surface_container_highest)
    readonly property color heroInk: page.phase === "bad" ? Colors.md3.on_error_container : page.phase === "warn" ? Colors.md3.on_tertiary_container : page.phase === "ok" ? Colors.md3.on_primary_container : Colors.md3.on_surface
    readonly property color heroFill: page.phase === "bad" ? Colors.md3.error : page.phase === "warn" ? Colors.md3.tertiary : Colors.md3.primary
    readonly property color heroFillInk: page.phase === "bad" ? Colors.md3.on_error : page.phase === "warn" ? Colors.md3.on_tertiary : Colors.md3.on_primary
    readonly property string headline: page.phase === "off" ? Localization.t("systemApp.headline_off") : page.phase === "checking" ? Localization.t("systemApp.headline_checking") : HealthService.attention === 0 ? Localization.t("systemApp.headline_ok") : HealthService.attention === 1 ? Localization.t("systemApp.headline_one") : Localization.t("systemApp.headline_many").replace("%1", HealthService.attention)

    readonly property int updates: (HealthService.result("updates.repo")?.count ?? 0) + (HealthService.result("updates.aur")?.count ?? 0) + (HealthService.result("updates.flatpak")?.count ?? 0)
    readonly property var mounts: HealthService.result("storage.mounts")?.mounts ?? []
    readonly property real storageWorst: page.mounts.reduce((a, m) => Math.max(a, m.pct ?? 0), 0)
    readonly property var storageRows: {
        const rest = page.mounts.filter(m => m !== page.rootMount && !/^\/(boot|efi)(\/|$)/.test(m.mount)).sort((a, b) => (b.pct ?? 0) - (a.pct ?? 0));
        return (page.rootMount ? [page.rootMount] : []).concat(rest).slice(0, 3);
    }
    readonly property var rootMount: page.mounts.find(m => m.mount === "/") ?? page.mounts[0] ?? null
    readonly property var mem: HealthService.result("sys.memory")
    readonly property real memUsed: page.mem && page.mem.memTotal > 0 ? (page.mem.memTotal - page.mem.memAvailable) / page.mem.memTotal : 0
    readonly property var sensors: (HealthService.result("hw.temps")?.sensors ?? []).slice().sort((a, b) => b.celsius - a.celsius)
    readonly property real hottest: page.sensors.length > 0 ? page.sensors[0].celsius : 0
    readonly property var services: HealthService.result("svc.list")?.services ?? []
    readonly property var failedUnits: HealthService.result("svc.list")?.failed ?? []
    readonly property int svcDown: page.failedUnits.length
    readonly property int svcRunning: page.services.filter(s => s.state === "run").length
    // One dot per service up to 24; beyond that each dot stands for a share of the total, keeping every
    // non-empty state visible (a failing unit never rounds away to nothing).
    readonly property var svcDots: {
        const n = page.services.length;
        if (n === 0)
            return [];
        const dots = Math.min(24, n);
        const share = count => count > 0 ? Math.max(1, Math.round(count * dots / n)) : 0;
        const nFail = Math.min(share(page.svcDown), dots);
        const nDown = Math.min(share(page.services.filter(s => s.state === "down").length), dots - nFail);
        const out = [];
        for (let i = 0; i < nFail; i++) out.push("failed");
        for (let i = 0; i < nDown; i++) out.push("down");
        for (let i = out.length; i < dots; i++) out.push("run");
        return out;
    }
    readonly property var hourTotals: {
        const h = ScreenTimeService.today.hourly ?? ({});
        const out = [];
        for (let i = 0; i < 24; i++)
            out.push(Object.keys(h).reduce((a, c) => a + ((h[c] ?? [])[i] ?? 0), 0));
        return out;
    }
    readonly property real hourMax: page.hourTotals.reduce((a, b) => Math.max(a, b), 1)

    Component.onCompleted: HealthService.registerView()
    Component.onDestruction: HealthService.unregisterView()

    Timer {
        interval: 5000
        running: HealthService.running
        onTriggered: page.slow = true
    }

    Connections {
        target: HealthService

        function onRunningChanged() {
            if (!HealthService.running)
                page.slow = false;
        }
    }

    Rectangle {
        id: hero
        Layout.fillWidth: true
        implicitHeight: Math.max(120, heroRow.implicitHeight + 48)
        radius: 22
        color: page.heroBg

        Behavior on color {
            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        RowLayout {
            id: heroRow
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 24
                rightMargin: 24
            }
            spacing: 18

            Item {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72

                LoadingSpinner {
                    anchors.centerIn: parent
                    size: 72
                    visible: page.phase === "checking"
                    color: page.heroInk
                }

                ShapeIcon {
                    anchors.centerIn: parent
                    visible: page.phase !== "checking"
                    size: 72
                    immediate: false
                    shape: page.phase === "bad" ? "burst" : page.phase === "warn" ? "softBurst" : page.phase === "ok" ? "cookie9" : "circle"
                    icon: page.phase === "bad" ? "sentiment-sick" : page.phase === "warn" ? "sentiment-worried" : page.phase === "ok" ? "sentiment-very-satisfied" : "sentiment-neutral"
                    fill: page.heroFill
                    ink: page.heroFillInk
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: page.headline
                    font.family: Config.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.Medium
                    color: page.heroInk
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: page.phase === "off" ? Localization.t("systemApp.health_off") : HealthService.running ? Localization.t("systemApp.sub_checking") : HealthService.lastRun > 0 ? Localization.t("systemApp.checked_ago").replace("%1", Fmt.ago(HealthService.lastRun)) : ""
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Qt.alpha(page.heroInk, 0.8)
                    elide: Text.ElideRight
                }
            }

            ActionButton {
                Layout.alignment: Qt.AlignVCenter
                visible: !HealthService.enabled
                primary: true
                label: Localization.t("systemApp.turn_on")
                onClicked: HealthService.setOption("enabled", true)
            }

            ActionButton {
                Layout.alignment: Qt.AlignVCenter
                visible: HealthService.enabled
                icon: "restart"
                label: Localization.t("systemApp.refresh")
                enabled: !HealthService.running
                onClicked: HealthService.refresh()
            }
        }

        WavyProgress {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 24
                rightMargin: 24
                bottomMargin: 8
            }
            height: 10
            visible: page.slow && HealthService.running
            value: HealthService.progress
            color: page.heroInk
            trackColor: Qt.alpha(page.heroInk, 0.2)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: HealthService.enabled && page.attention.length > 0

        Text {
            text: Localization.t("systemApp.needs_attention")
            font.family: Config.fontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
            font.letterSpacing: 0.7
            color: Colors.md3.primary
            leftPadding: 2
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: page.attention

                CheckRow2 {
                    id: row
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    checkId: row.modelData.id
                    topRadius: row.index === 0 ? 18 : 6
                    bottomRadius: row.index === page.attention.length - 1 ? 18 : 6
                    clickable: true
                    onClicked: SystemPages.openPage(page.areaPage[row.modelData.area])

                    leading: [
                        ShapeIcon {
                            size: 34
                            shape: page.areaShape[row.modelData.area]
                            icon: page.areaIcon[row.modelData.area]
                            fill: row.modelData.bad ? Colors.md3.error : Colors.md3.tertiary
                            ink: row.modelData.bad ? Colors.md3.on_error : Colors.md3.on_tertiary
                        }
                    ]

                    FixActions {
                        checkId: row.modelData.id
                        target: page.areaPage[row.modelData.area]
                    }

                    ActionButton {
                        icon: "check"
                        tooltip: Localization.t("systemApp.dismiss_tip")
                        onClicked: HealthService.dismiss(row.modelData.id)
                    }
                }
            }
        }
    }

    ActionButton {
        Layout.alignment: Qt.AlignLeft
        visible: HealthService.enabled && HealthService.hiddenCount > 0
        icon: "visibility"
        label: Localization.t("systemApp.n_dismissed").replace("%1", HealthService.hiddenCount) + " · " + Localization.t("systemApp.show_dismissed")
        onClicked: HealthService.restoreDismissed()
    }

    GridLayout {
        Layout.fillWidth: true
        visible: HealthService.enabled
        columns: width > 640 ? 3 : 2
        columnSpacing: 12
        rowSpacing: 12
        uniformCellWidths: true

        GlanceCard {
            id: updatesCard
            Layout.fillWidth: true
            Layout.preferredHeight: 148
            label: Localization.t("systemApp.packages")
            icon: "download-for-offline"
            shape: "cookie6"
            tone: page.updates > 0 ? "primary" : "neutral"
            sublabel: Localization.t("systemApp.stat_updates")
            onClicked: SystemPages.openPage("packages")

            Text {
                anchors.centerIn: parent
                text: String(page.updates)
                font.family: Config.fontFamily
                font.pixelSize: 44
                font.weight: Font.Medium
                color: updatesCard.ink
            }
        }

        GlanceCard {
            id: storageCard
            Layout.fillWidth: true
            Layout.preferredHeight: 148
            visible: page.mounts.length > 0
            label: Localization.t("systemApp.storage")
            icon: "folder"
            shape: "clover4"
            tone: page.storageWorst >= 95 ? "bad" : page.storageWorst >= 85 ? "warn" : "neutral"
            onClicked: SystemPages.openPage("storage")

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: page.storageRows

                    ColumnLayout {
                        id: vol
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: vol.modelData.mount
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: storageCard.ink
                                elide: Text.ElideMiddle
                            }

                            Text {
                                text: Localization.t("systemApp.free_of_total").replace("%1", Fmt.bytes(vol.modelData.total - vol.modelData.used))
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                color: Qt.alpha(storageCard.ink, 0.75)
                            }
                        }

                        WavyProgress {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 10
                            amplitude: 1.5
                            wavelength: 12
                            animated: false
                            value: (vol.modelData.pct ?? 0) / 100
                            color: (vol.modelData.pct ?? 0) >= 95 ? Colors.md3.error : (vol.modelData.pct ?? 0) >= 85 ? Colors.md3.tertiary : (storageCard.tonal ? storageCard.accent : Colors.md3.primary)
                            trackColor: Qt.alpha(storageCard.ink, 0.12)
                        }
                    }
                }
            }
        }

        GlanceCard {
            id: memCard
            Layout.fillWidth: true
            Layout.preferredHeight: 148
            visible: page.mem !== null && page.mem.memTotal > 0
            label: Localization.t("systemApp.ram")
            icon: "memory"
            shape: "gem"
            tone: page.memUsed >= 0.9 ? "warn" : "neutral"
            value: Fmt.bytes((page.mem?.memTotal ?? 0) - (page.mem?.memAvailable ?? 0))
            sublabel: Localization.t("systemApp.of").replace("%1", Fmt.bytes(page.mem?.memTotal ?? 0))
            onClicked: SystemPages.openPage("system")

            overlay: ProgressRing {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(memCard.height * 0.7, memCard.width * 0.5)
                height: width
                strokeWidth: 8
                progress: page.memUsed
                activeColor: memCard.tonal ? memCard.accent : Colors.md3.primary
                trackColor: Qt.alpha(memCard.ink, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: Fmt.pctText(page.memUsed)
                    font.family: Config.fontFamily
                    font.pixelSize: 26
                    font.weight: Font.Medium
                    color: memCard.ink
                }
            }
        }

        GlanceCard {
            id: tempCard
            Layout.fillWidth: true
            Layout.preferredHeight: 148
            visible: page.hottest > 0
            label: Localization.t("systemApp.stat_hottest")
            icon: "thermostat"
            shape: "sunny"
            tone: page.hottest >= 90 ? "bad" : page.hottest >= 80 ? "warn" : "neutral"
            onClicked: SystemPages.openPage("system")

            RowLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 12

                RingGauge {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    start: 135
                    sweep: 270
                    thickness: 7
                    value: page.hottest / 100
                    color: tempCard.tonal ? tempCard.accent : Colors.md3.primary
                    trackColor: Qt.alpha(tempCard.ink, 0.12)
                    text: Math.round(page.hottest) + "°"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: page.sensors.slice(0, 3)

                        RowLayout {
                            id: sensor
                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.preferredWidth: 6
                                Layout.preferredHeight: 6
                                radius: 3
                                color: sensor.modelData.celsius >= 90 ? Colors.md3.error : sensor.modelData.celsius >= 80 ? Colors.md3.tertiary : Qt.alpha(tempCard.ink, 0.35)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: sensor.modelData.label !== "" ? sensor.modelData.label : sensor.modelData.name
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                color: Qt.alpha(tempCard.ink, 0.8)
                                elide: Text.ElideRight
                            }

                            Text {
                                text: Math.round(sensor.modelData.celsius) + "°"
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: tempCard.ink
                            }
                        }
                    }
                }
            }
        }

        GlanceCard {
            id: svcCard
            Layout.fillWidth: true
            Layout.preferredHeight: 148
            visible: page.services.length > 0
            label: Localization.t("systemApp.services")
            icon: "automation"
            shape: "pill"
            tone: page.svcDown > 0 ? "bad" : "neutral"
            value: page.svcDown > 0 ? Localization.t("systemApp.n_failed").replace("%1", page.svcDown) : Localization.t("systemApp.n_running").replace("%1", page.svcRunning)
            onClicked: SystemPages.openPage("system")

            Flow {
                anchors.centerIn: parent
                width: Math.min(parent.width, 132)
                spacing: 5

                Repeater {
                    model: page.svcDots

                    Item {
                        id: dot
                        required property string modelData
                        width: 11
                        height: 11

                        Rectangle {
                            anchors.centerIn: parent
                            width: 11
                            height: 11
                            visible: dot.modelData !== "failed"
                            radius: dot.modelData === "run" ? 5.5 : 3
                            color: dot.modelData === "run" ? Colors.md3.primary : Qt.alpha(svcCard.ink, 0.25)

                            Behavior on radius {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        MaterialShape {
                            anchors.centerIn: parent
                            visible: dot.modelData === "failed"
                            name: "burst"
                            shapeSize: 14
                            color: Colors.md3.error
                        }
                    }
                }
            }
        }

        GlanceCard {
            id: timeCard
            Layout.fillWidth: true
            Layout.preferredHeight: 148
            label: Localization.t("systemApp.screentime")
            icon: "history"
            shape: "cookie12"
            value: ScreenTimeService.today.hasData ? Fmt.duration(ScreenTimeService.today.total) : "—"
            sublabel: Localization.t("screenTime.today")
            onClicked: SystemPages.openPage("screentime")

            Row {
                anchors.centerIn: parent
                width: parent.width
                height: 52
                spacing: 2

                Repeater {
                    model: page.hourTotals

                    Item {
                        id: bar
                        required property real modelData
                        width: (parent.width - 23 * 2) / 24
                        height: parent.height

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(3, parent.height * bar.modelData / page.hourMax)
                            radius: width / 2
                            color: bar.modelData > 0 ? Colors.md3.primary : Qt.alpha(timeCard.ink, 0.15)
                        }
                    }
                }
            }
        }
    }
}
