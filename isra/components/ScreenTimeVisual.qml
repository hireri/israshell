pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.services
import "../windows/system/format.js" as Fmt

Item {
    id: root

    property bool interactive: true
    property bool showBar: true
    property bool showApps: true
    property bool showChart: true
    property int maxApps: 5

    readonly property var today: ScreenTimeService.today
    readonly property int pad: 14
    readonly property int rowH: 22
    readonly property int mode: root.width >= 430 ? 2 : (root.width >= 270 ? 1 : 0)
    readonly property real inner: root.width - root.pad * 2
    readonly property bool chartOn: root.mode >= 1 && root.showChart && root.today.hasData && ScreenTimeService.cfg.hourly
    readonly property bool appsSide: root.mode === 2 && root.showApps
    readonly property int stackFit: Math.max(0, Math.min(root.maxApps, Math.floor((root.height - root.pad * 2 - 51 - (root.showBar ? 18 : 0) + 4) / (root.rowH + 4))))
    readonly property int sideFit: Math.max(0, Math.min(root.maxApps, Math.floor((root.height - root.pad * 2 + 4) / (root.rowH + 4))))
    readonly property var cats: ["work", "web", "fun", "other"]
    readonly property string note: !ScreenTimeService.enabled ? Localization.t("screenTime.tracking_off") : ScreenTimeService.paused ? Localization.t("screenTime.tracking_paused") : !root.today.hasData ? Localization.t("systemApp.sub_no_data") : ""
    readonly property real catTotal: root.cats.reduce((a, c) => a + (root.today.categories[c] ?? 0), 0)
    readonly property var hours: {
        const out = [];
        for (let h = 0; h < 24; h++) {
            let t = 0;
            for (const c of root.cats)
                t += (root.today.hourly[c] ?? [])[h] ?? 0;
            out.push(t);
        }
        return out;
    }
    readonly property real hourMax: Math.max(900, root.hours.reduce((a, b) => Math.max(a, b), 0))

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Config.desktopWidgetsBlurActive ? Config.dim(Colors.md3.surface_container_high) : Colors.md3.surface_container_high
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: !Config.desktopWidgetsBlurActive
            shadowBlur: 0.5
            shadowColor: Qt.alpha("black", 0.2)
            shadowVerticalOffset: 4
        }
    }

    RowLayout {
        anchors {
            fill: parent
            margins: root.pad
        }
        spacing: 18

        Column {
            id: leftCol
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.mode === 2 ? 150 : (root.chartOn ? Math.round(root.inner * 0.52) : root.inner)
            Layout.fillWidth: root.mode === 0 || (!root.chartOn && !root.appsSide)
            spacing: 10

            Column {
                width: parent.width

                Text {
                    width: parent.width
                    text: root.today.hasData ? Fmt.duration(root.today.total) : "—"
                    font.family: Config.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                Text {
                    width: parent.width
                    text: root.note !== "" ? root.note : Localization.t("screenTime.today")
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Colors.md3.outline
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
            }

            Row {
                id: bar
                width: parent.width
                height: 8
                spacing: 2
                visible: root.showBar && root.today.hasData

                Repeater {
                    model: root.cats

                    Rectangle {
                        id: seg
                        required property string modelData
                        readonly property real secs: root.today.categories[seg.modelData] ?? 0
                        visible: seg.secs > 0
                        width: Math.max(4, (bar.width - 6) * seg.secs / Math.max(1, root.catTotal))
                        height: bar.height
                        radius: 4
                        color: ScreenTimeService.categoryColor(seg.modelData)
                    }
                }
            }

            ScreenTimeApps {
                width: parent.width
                visible: root.showApps && !root.appsSide && root.today.hasData
                apps: root.today.apps
                count: root.stackFit
                rowH: root.rowH
            }
        }

        ScreenTimeApps {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            visible: root.appsSide && root.today.hasData
            apps: root.today.apps
            count: root.sideFit
            rowH: root.rowH
        }

        Item {
            id: chart
            visible: root.chartOn
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1

            Row {
                id: bars
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: ticks.top
                    bottomMargin: 4
                }
                spacing: 2

                Repeater {
                    model: root.hours

                    Item {
                        id: hb
                        required property real modelData
                        width: (bars.width - 23 * 2) / 24
                        height: bars.height

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: hb.modelData > 0 ? Math.max(3, parent.height * Math.min(1, hb.modelData / root.hourMax)) : 0
                            radius: Math.min(2, width / 2)
                            color: Colors.md3.primary
                        }
                    }
                }
            }

            Item {
                id: ticks
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 12

                Repeater {
                    model: ["00", "06", "12", "18"]

                    Text {
                        id: tick
                        required property string modelData
                        required property int index
                        x: tick.index * (ticks.width / 4)
                        text: tick.modelData
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        color: Colors.md3.outline
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "system", "open", "screentime"])
    }
}
