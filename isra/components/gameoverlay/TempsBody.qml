pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.icons
import qs.services
import qs.style

Item {
    id: root

    readonly property var sensors: [
        {
            label: Localization.t("sysMonitor.cpu"),
            icon: "memory",
            color: Colors.md3.primary,
            value: SystemInfo.cpuTempDisplay,
            history: SystemInfo.cpuTempHistory
        },
        {
            label: Localization.t("sysMonitor.gpu"),
            icon: "videogame-asset",
            color: Colors.md3.secondary,
            value: SystemInfo.gpuTempDisplay,
            history: SystemInfo.gpuTempHistory
        }
    ].filter(s => s.value >= 0)

    implicitWidth: 320
    implicitHeight: column.implicitHeight

    Component.onCompleted: SystemInfo.registerLiveConsumer()
    Component.onDestruction: SystemInfo.unregisterLiveConsumer()

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            visible: root.sensors.length === 0
            text: Localization.t("gameOverlay.no_sensors")
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.outline
            renderType: Text.NativeRendering
        }

        Repeater {
            model: root.sensors

            delegate: ColumnLayout {
                id: tile
                required property var modelData

                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialIcon {
                        name: tile.modelData.icon
                        iconSize: 16
                        color: tile.modelData.color
                        transitionType: "none"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: tile.modelData.label
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Colors.md3.on_surface_variant
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: Math.round(tile.modelData.value) + SystemInfo.tempUnit
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        color: Colors.md3.on_surface
                        renderType: Text.NativeRendering
                    }
                }

                ClippingRectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 10
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(tile.modelData.color, 0.3)

                    Sparkline {
                        anchors.fill: parent
                        points: Config.useFahrenheit ? tile.modelData.history.map(c => SystemInfo.celsiusToFahrenheit(c)) : tile.modelData.history
                        scaleMax: SystemInfo.metricScale("temp")
                        lineColor: tile.modelData.color
                        sampleCount: SystemInfo.historyLength
                        interval: SystemInfo.pollInterval
                    }
                }
            }
        }
    }
}
