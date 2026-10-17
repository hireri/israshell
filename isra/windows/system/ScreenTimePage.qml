pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services
import qs.windows
import qs.windows.components
import qs.components
import "format.js" as Fmt

PageBase {
    id: page

    title: Localization.t("systemApp.screentime")
    subtitle: Localization.t("systemApp.screentime_sub")

    property string sortBy: "time"
    property bool allApps: false
    readonly property var view: ScreenTimeService.view
    readonly property var cats: ["work", "web", "fun", "other"]
    readonly property real avg: ScreenTimeService.averageSecs
    readonly property bool isDay: ScreenTimeService.range === "day"
    readonly property string rangeTitle: page.isDay ? Localization.t("screenTime.today") : ScreenTimeService.range === "week" ? Localization.t("screenTime.last_7") : Localization.t("screenTime.last_30")
    readonly property bool dimOff: !ScreenTimeService.cfg.appFocus
    readonly property bool inactive: !ScreenTimeService.tracking || page.dimOff
    readonly property var apps: page.sortBy === "notifications" ? page.view.apps.filter(a => a.notifications > 0).sort((a, b) => b.notifications - a.notifications) : page.view.apps
    readonly property real peak: page.apps.length > 0 ? Math.max(1, page.sortBy === "notifications" ? page.apps[0].notifications : page.apps[0].seconds) : 1
    readonly property var shownApps: page.allApps ? page.apps : page.apps.slice(0, 8)
    readonly property var wsItems: ScreenTimeService.cfg.workspaces ? Object.keys(page.view.workspaces).sort((a, b) => page.view.workspaces[b] - page.view.workspaces[a]).map(k => ({ label: Localization.t("screenTime.workspace").replace("%1", k), secs: page.view.workspaces[k] })) : []
    readonly property var mediaItems: ScreenTimeService.cfg.media ? Object.keys(page.view.media).sort((a, b) => page.view.media[b] - page.view.media[a]).map(k => ({ label: k === "_" ? Localization.t("screenTime.unattributed") : k, secs: page.view.media[k] })) : []

    property real shownTotal: page.view.hasData ? page.view.total : 0

    Behavior on shownTotal {
        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: ScreenTimeService.registerView()
    Component.onDestruction: ScreenTimeService.unregisterView()

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16

        Hero {
            Layout.fillWidth: true
            visible: page.inactive
            tone: "warn"
            shape: "clover4"
            icon: "play-pause"
            title: !ScreenTimeService.enabled ? Localization.t("screenTime.tracking_off") : ScreenTimeService.paused ? Localization.t("screenTime.tracking_paused") : Localization.t("screenTime.dimension_off")
            sublabel: Localization.t("screenTime.tracking_hint")

            actions: [
                ActionButton {
                    primary: true
                    label: ScreenTimeService.enabled && ScreenTimeService.paused ? Localization.t("screenTime.resume") : Localization.t("systemApp.turn_on")
                    onClicked: {
                        if (!ScreenTimeService.enabled)
                            ScreenTimeService.setOption("enabled", true);
                        else if (ScreenTimeService.paused)
                            ScreenTimeService.resume();
                        else
                            ScreenTimeService.setOption("appFocus", true);
                    }
                }
            ]
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ChipRow {
                options: [
                    { value: "day", label: Localization.t("screenTime.today") },
                    { value: "week", label: Localization.t("screenTime.week") },
                    { value: "month", label: Localization.t("screenTime.month") }
                ]
                currentValue: ScreenTimeService.range
                onSelected: v => ScreenTimeService.setRange(v)
            }

            Text {
                visible: ScreenTimeService.viewLoading
                text: Localization.t("screenTime.loading")
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.outline
            }

            Item {
                Layout.fillWidth: true
            }

            ActionButton {
                visible: ScreenTimeService.enabled && !page.inactive
                icon: "play-pause"
                label: Localization.t("screenTime.pause")
                onClicked: ScreenTimeService.toggle()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: summary.implicitHeight + 48
            radius: 28
            color: Config.dim(Colors.md3.surface_container)

            RowLayout {
                id: summary
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 24
                }
                spacing: 28

                CategoryDonut {
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 200
                    Layout.alignment: Qt.AlignVCenter
                    categories: page.view.categories

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: page.view.hasData ? Fmt.duration(page.shownTotal) : "—"
                            font.family: Config.fontFamily
                            font.pixelSize: 34
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: page.rangeTitle
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Colors.md3.on_surface_variant
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Pill {
                            visible: page.view.hasData && page.avg > 0
                            dot: false
                            tone: !page.isDay ? "neutral" : page.view.total > page.avg ? "warn" : "ok"
                            text: !page.isDay ? Localization.t("screenTime.average").replace("%1", Fmt.duration(page.avg)) : Localization.t(page.view.total > page.avg ? "screenTime.above_average" : "screenTime.below_average").replace("%1", Fmt.duration(Math.abs(page.view.total - page.avg)))
                        }

                        Text {
                            visible: page.view.hasData && page.isDay && page.view.first > 0
                            text: Localization.t("screenTime.active_between").replace("%1", Fmt.clock(page.view.first)).replace("%2", Fmt.clock(page.view.last))
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Colors.md3.outline
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !page.view.hasData
                            text: ScreenTimeService.tracking ? Localization.t("screenTime.no_data_hint") : Localization.t("screenTime.no_data")
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            color: Colors.md3.on_surface_variant
                            wrapMode: Text.WordWrap
                        }

                        Item {
                            Layout.fillWidth: true
                            visible: page.view.hasData
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8
                        uniformCellWidths: true

                        Repeater {
                            model: page.cats

                            Rectangle {
                                id: tile
                                required property string modelData
                                readonly property real secs: page.view.categories[tile.modelData] ?? 0
                                readonly property real share: page.view.total > 0 ? tile.secs / page.view.total : 0

                                Layout.fillWidth: true
                                Layout.preferredHeight: 64
                                radius: 18
                                color: Config.dim(Colors.md3.surface_container_highest)
                                opacity: tile.secs > 0 ? 1 : 0.55

                                RowLayout {
                                    anchors {
                                        fill: parent
                                        leftMargin: 14
                                        rightMargin: 14
                                    }

                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 1

                                        RowLayout {
                                            spacing: 6

                                            Rectangle {
                                                width: 10
                                                height: 10
                                                radius: 5
                                                color: ScreenTimeService.categoryColor(tile.modelData)
                                            }

                                            Text {
                                                text: Localization.t("screenTime.cat_" + tile.modelData)
                                                font.family: Config.fontFamily
                                                font.pixelSize: 12
                                                color: Colors.md3.on_surface_variant
                                            }
                                        }

                                        Text {
                                            text: Fmt.duration(tile.secs)
                                            font.family: Config.fontFamily
                                            font.pixelSize: 17
                                            font.weight: Font.Medium
                                            color: Colors.md3.on_surface
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Math.round(tile.share * 100) + "%"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 12
                                        color: Colors.md3.outline
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: page.view.hasData
            spacing: 10
            uniformCellSizes: true

            StatCard {
                Layout.fillWidth: true
                visible: ScreenTimeService.cfg.unlocks
                shape: "cookie9"
                icon: "lock"
                fill: Colors.md3.primary_container
                ink: Colors.md3.on_primary_container
                value: String(page.view.unlocks)
                label: Localization.t("screenTime.unlocks")
            }

            StatCard {
                Layout.fillWidth: true
                visible: ScreenTimeService.cfg.notifications
                shape: "clover4"
                icon: "notifications"
                fill: Colors.md3.secondary_container
                ink: Colors.md3.on_secondary_container
                value: String(page.view.notifications)
                label: Localization.t("systemApp.notifications")
            }

            StatCard {
                Layout.fillWidth: true
                shape: "softBurst"
                icon: "analog-clock"
                fill: Colors.md3.tertiary_container
                ink: Colors.md3.on_tertiary_container
                value: Fmt.duration(page.view.longest)
                label: Localization.t("screenTime.longest")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: page.view.hasData && (!page.isDay || ScreenTimeService.cfg.hourly)
            implicitHeight: chartCol.implicitHeight + 36
            radius: 24
            color: Config.dim(Colors.md3.surface_container)

            ColumnLayout {
                id: chartCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 18
                }
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: page.isDay ? Localization.t("screenTime.by_hour") : Localization.t("screenTime.by_day")
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface
                    }

                    Text {
                        visible: !page.isDay && page.avg > 0
                        text: Localization.t("screenTime.average").replace("%1", Fmt.duration(page.avg))
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Colors.md3.outline
                    }
                }

                UsageChart {
                    Layout.fillWidth: true
                    srcDays: ScreenTimeService.viewDays
                    srcHourly: page.view.hourly
                    srcRange: ScreenTimeService.range
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: page.view.hasData && page.view.apps.length > 0
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SectionLabel {
                    Layout.fillWidth: true
                    text: Localization.t("screenTime.most_used").toUpperCase() + " · " + page.apps.length
                }

                ChipRow {
                    options: [
                        { value: "time", label: Localization.t("screenTime.sort_time") },
                        { value: "notifications", label: Localization.t("systemApp.notifications") }
                    ]
                    currentValue: page.sortBy
                    onSelected: v => page.sortBy = v
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: page.shownApps

                    ListRow {
                        id: app
                        required property var modelData
                        required property int index
                        readonly property string iconName: ScreenTimeService.appIcon(app.modelData.id)
                        readonly property string iconPath: app.iconName !== "" ? Quickshell.iconPath(app.iconName, true) : ""
                        readonly property string name: ScreenTimeService.appName(app.modelData.id)

                        Layout.fillWidth: true
                        topRadius: app.index === 0 ? 18 : 6
                        bottomRadius: app.index === page.shownApps.length - 1 ? 18 : 6
                        title: app.name
                        sublabel: Localization.t("screenTime.app_sub").replace("%1", app.modelData.sessions).replace("%2", app.modelData.notifications)

                        leading: [
                            Item {
                                implicitWidth: 40
                                implicitHeight: 40

                                IconImage {
                                    anchors.fill: parent
                                    visible: app.iconPath !== ""
                                    source: app.iconPath
                                    asynchronous: true
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: app.iconPath === ""
                                    radius: 20
                                    color: Colors.md3.secondary_container

                                    Text {
                                        anchors.centerIn: parent
                                        text: app.name.charAt(0).toUpperCase()
                                        font.family: Config.fontFamily
                                        font.pixelSize: 16
                                        font.weight: Font.Medium
                                        color: Colors.md3.on_secondary_container
                                    }
                                }
                            }
                        ]

                        UsageBar {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 110
                            implicitHeight: 6
                            value: (page.sortBy === "notifications" ? app.modelData.notifications : app.modelData.seconds) / page.peak
                            fillColor: ScreenTimeService.categoryColor(app.modelData.category)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 62
                            horizontalAlignment: Text.AlignRight
                            text: page.sortBy === "notifications" ? String(app.modelData.notifications) : Fmt.duration(app.modelData.seconds)
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 64
                            height: 26

                            Pill {
                                anchors.fill: parent
                                visible: app.modelData.id !== "_"
                                dot: false
                                clickable: true
                                tooltip: Localization.t("screenTime.change_category")
                                text: Localization.t("screenTime.cat_" + app.modelData.category)
                                onClicked: ScreenTimeService.setCategory(app.modelData.id, page.cats[(page.cats.indexOf(app.modelData.category) + 1) % page.cats.length])
                            }
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            height: 34

                            ActionButton {
                                anchors.centerIn: parent
                                visible: app.modelData.id !== "_"
                                icon: "visibility-off"
                                tooltip: Localization.t("screenTime.exclude")
                                onClicked: ScreenTimeService.exclude(app.modelData.id)
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                visible: page.apps.length > 8 || ScreenTimeService.cfg.excluded.length > 0
                spacing: 10

                ActionButton {
                    visible: page.apps.length > 8
                    label: page.allApps ? Localization.t("systemApp.show_less") : Localization.t("systemApp.show_all").replace("%1", page.apps.length)
                    onClicked: page.allApps = !page.allApps
                }

                Text {
                    visible: ScreenTimeService.cfg.excluded.length > 0
                    text: Localization.t("screenTime.excluded_count").replace("%1", ScreenTimeService.cfg.excluded.length)
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Colors.md3.outline
                }

                ActionButton {
                    visible: ScreenTimeService.cfg.excluded.length > 0
                    label: Localization.t("screenTime.manage_hidden")
                    onClicked: SystemPages.openPage("settings")
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: page.view.hasData && (page.wsItems.length > 0 || page.mediaItems.length > 0)
            spacing: 10
            uniformCellSizes: true

            BreakdownCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                visible: page.wsItems.length > 0
                title: Localization.t("screenTime.workspaces")
                items: page.wsItems
                accent: Colors.md3.primary
            }

            BreakdownCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                visible: page.mediaItems.length > 0
                title: Localization.t("screenTime.media")
                items: page.mediaItems
                accent: Colors.md3.tertiary
            }
        }
    }
}
