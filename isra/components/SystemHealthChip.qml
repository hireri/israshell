pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    property var panelWindow: QsWindow.window

    readonly property var ranks: ({ info: 1, warn: 2, bad: 3 })
    readonly property string level: Config.health.barChipLevel ?? "info"
    readonly property var shown: HealthService.highlights.filter(h => root.level === "always" || root.ranks[h.sev] >= (root.ranks[root.level] ?? 1))
    readonly property var lead: root.shown.length > 0 ? root.shown[0] : null
    readonly property bool wanted: HealthService.enabled && HealthService.probed && (root.lead !== null || root.level === "always")
    readonly property color tone: root.lead === null ? Colors.md3.primary : root.lead.sev === "bad" ? Colors.md3.error : root.lead.sev === "warn" ? Colors.md3.tertiary : Colors.md3.primary
    readonly property string tip: root.shown.length === 0 ? Localization.t("systemApp.sub_all_clear") : root.shown.map(h => h.text).join("\n")

    readonly property bool wantsSpace: root.wanted
    visible: root.wantsSpace
    implicitWidth: pill.width
    implicitHeight: 32

    BarTooltip {
        id: tooltip
        panelWindow: root.panelWindow
        gap: 4
        showDelay: 0
    }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        height: 32
        width: row.implicitWidth + 20
        radius: height / 2
        color: Config.bar.transparentPills ? Qt.alpha(Colors.md3.secondary_container, 0) : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 5

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.lead ? root.lead.icon : "check"
                iconSize: 18
                color: root.tone
            }

            Text {
                visible: root.lead !== null
                anchors.verticalCenter: parent.verticalCenter
                text: root.lead ? root.lead.short : ""
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.features: { "tnum": 1 }
                renderType: Text.NativeRendering
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (PanelService.current)
                    PanelService.current.close();
                tooltip.hide();
                Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "system", "open", root.lead ? root.lead.page : "overview"]);
            }
            onEntered: tooltip.show(pill, root.tip)
            onExited: tooltip.hide()
        }
    }
}
