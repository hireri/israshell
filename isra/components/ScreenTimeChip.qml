pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.style
import qs.icons
import qs.services
import "../windows/system/format.js" as Fmt

Item {
    id: root

    property var panelWindow: QsWindow.window

    readonly property var today: ScreenTimeService.today
    readonly property bool paused: ScreenTimeService.paused
    readonly property string tip: {
        const head = Localization.t("screenTime.today") + ": " + (root.today.hasData ? Fmt.duration(root.today.total) : Localization.t("systemApp.sub_no_data"));
        const apps = root.today.apps.slice(0, 3).map(a => ScreenTimeService.appName(a.id) + " " + Fmt.duration(a.seconds));
        return [root.paused ? Localization.t("screenTime.tracking_paused") : head].concat(root.paused ? [] : apps).join("\n");
    }

    readonly property bool wantsSpace: ScreenTimeService.enabled
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
                name: "history"
                iconSize: 18
                color: root.paused ? Qt.alpha(Colors.md3.on_surface, 0.35) : Colors.md3.primary
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.today.hasData ? Fmt.duration(root.today.total) : "—"
                color: root.paused ? Qt.alpha(Colors.md3.on_surface, 0.5) : Colors.md3.on_surface
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
                Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "system", "open", "screentime"]);
            }
            onEntered: tooltip.show(pill, root.tip)
            onExited: tooltip.hide()
        }
    }
}
