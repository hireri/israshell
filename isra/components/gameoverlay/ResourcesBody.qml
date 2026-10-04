import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.icons
import qs.services
import qs.style

Item {
    id: root

    readonly property var shown: SystemInfo.metrics.filter(m => ["cpu", "gpu", "ram", "temp"].includes(m.id) && SystemInfo.metricAvailable(m.id))

    implicitWidth: 320
    implicitHeight: grid.implicitHeight

    Component.onCompleted: SystemInfo.registerLiveConsumer()
    Component.onDestruction: SystemInfo.unregisterLiveConsumer()

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: 2
        columnSpacing: 12
        rowSpacing: 14

        Repeater {
            model: root.shown

            delegate: ColumnLayout {
                id: tile
                required property var modelData

                readonly property color tint: (Config.sysMonitor?.colored ?? true) ? modelData.color : Colors.md3.primary

                Layout.fillWidth: true
                Layout.preferredWidth: 140
                Layout.alignment: Qt.AlignTop
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialIcon {
                        name: tile.modelData.icon
                        iconSize: 16
                        color: tile.tint
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
                        text: Math.round(SystemInfo.metricValue(tile.modelData.id)) + (tile.modelData.id === "temp" ? SystemInfo.tempUnit : "%")
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
                    border.color: Qt.alpha(tile.tint, 0.3)

                    Sparkline {
                        anchors.fill: parent
                        points: SystemInfo.metricHistory(tile.modelData.id)
                        scaleMax: SystemInfo.metricScale(tile.modelData.id)
                        lineColor: tile.tint
                        sampleCount: SystemInfo.historyLength
                        smoothScroll: Config.sysMonitor?.smooth ?? false
                        interval: SystemInfo.pollInterval
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: SystemInfo.metricDetail(tile.modelData.id)
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    color: Qt.alpha(Colors.md3.on_surface, 0.65)
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
