pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import QtQuick.Shapes.DesignHelpers
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    Component.onCompleted: SystemInfo.registerLiveConsumer()
    Component.onDestruction: SystemInfo.unregisterLiveConsumer()

    required property var panelWindow
    readonly property int barStyle: Config.sysMonitor?.style ?? 0
    readonly property bool showPercent: barStyle === 0 ? true : (Config.sysMonitor?.showPercent ?? true)
    readonly property bool unifiedPill: Config.sysMonitor?.unifiedPill ?? false
    readonly property bool colored: Config.sysMonitor?.colored ?? true

    function pillColor() {
        if (Config.bar.transparentPills) {
            return Qt.alpha(Colors.md3.secondary_container, 0);
        } else {
            return Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity);
        }
    }

    readonly property var enabledIds: Config.sysMonitor?.metrics ?? ["cpu", "ram"]
    readonly property var activeMetrics: SystemInfo.metrics.filter(m => enabledIds.includes(m.id))

    implicitWidth: pillsRow.implicitWidth
    implicitHeight: 32

    component MetricContent: Row {
        id: metricContent
        required property var owner
        required property var metricData
        spacing: 4
        height: owner.barStyle === 1 ? 24 : 20

        property real liveValue: SystemInfo.metricValue(metricData.id)
        property bool liveAvailable: SystemInfo.metricAvailable(metricData.id)
        property real liveScale: SystemInfo.metricScale(metricData.id)
        property color resolvedColor: owner.colored ? metricData.color : Colors.md3.primary

        Item {
            id: pieWrap
            visible: metricContent.owner.barStyle === 1
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: pieCanvas
                anchors.fill: parent
                property real value: metricContent.liveValue
                property real scaleMax: metricContent.liveScale
                property bool available: metricContent.liveAvailable
                property color pieColor: available ? metricContent.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)

                readonly property bool smoothEnabled: Config.sysMonitor?.smooth ?? false
                property real animatedValue: value

                Behavior on animatedValue {
                    enabled: pieCanvas.smoothEnabled
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                readonly property real _frac: Math.max(0, Math.min(1, pieCanvas.animatedValue / pieCanvas.scaleMax))

                EllipseShape {
                    anchors.fill: parent
                    fillColor: Qt.alpha(pieCanvas.pieColor, 0.5)
                    strokeWidth: -1
                }

                EllipseShape {
                    anchors.fill: parent
                    visible: pieCanvas._frac > 0
                    startAngle: 0
                    sweepAngle: pieCanvas._frac * 360
                    fillColor: pieCanvas.pieColor
                    strokeWidth: -1
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: metricContent.metricData.icon
                iconSize: 17
                color: metricContent.liveAvailable ? Colors.md3.surface_container_high : Colors.md3.on_surface
            }
        }

        MaterialIcon {
            visible: metricContent.owner.barStyle !== 1
            name: metricContent.metricData.icon
            iconSize: 18
            color: metricContent.liveAvailable ? metricContent.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            visible: metricContent.owner.barStyle === 2
            width: 30
            height: 6
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.alpha(metricContent.resolvedColor, 0.2)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(metricContent.liveScale, metricContent.liveValue)) / metricContent.liveScale
                height: parent.height
                radius: parent.radius
                color: metricContent.liveAvailable ? metricContent.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)

                Behavior on width {
                    enabled: Config.sysMonitor?.smooth ?? false
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            visible: metricContent.owner.showPercent
            text: metricContent.liveAvailable ? Math.round(metricContent.liveValue) : "—"
            color: Colors.md3.on_surface
            font.family: Config.fontFamily
            font.pixelSize: 14
            font.features: { "tnum": 1 }
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }
    }

    BarTooltip {
        id: tooltip
        panelWindow: root.panelWindow
        gap: 4
        showDelay: 0

        Loader {
            active: tooltip.shown
            sourceComponent: tooltipRowComponent
        }

        Component {
            id: tooltipRowComponent

            Row {
            spacing: 20

            Repeater {
                model: SystemInfo.metrics

                delegate: Column {
                    id: metricDelegate
                    required property var modelData
                    spacing: 5
                    width: 92

                    property real liveValue: SystemInfo.metricValue(modelData.id)
                    property bool liveAvailable: SystemInfo.metricAvailable(modelData.id)
                    property string liveDetail: SystemInfo.metricDetail(modelData.id)
                    property var liveHistory: SystemInfo.metricHistory(modelData.id)
                    property real liveScale: SystemInfo.metricScale(modelData.id)
                    property color resolvedColor: root.colored ? modelData.color : Colors.md3.primary

                    Row {
                        spacing: 5
                        MaterialIcon {
                            name: metricDelegate.modelData.icon
                            iconSize: 16
                            color: metricDelegate.liveAvailable ? metricDelegate.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: metricDelegate.modelData.label
                            color: Colors.md3.on_surface
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                            renderType: Text.NativeRendering
                        }
                    }

                    ClippingRectangle {
                        id: graphContainer
                        width: metricDelegate.width
                        height: 46
                        radius: 8
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha(metricDelegate.resolvedColor, 0.3)

                        Sparkline {
                            anchors.fill: parent
                            points: metricDelegate.liveHistory
                            scaleMax: metricDelegate.liveScale
                            lineColor: metricDelegate.liveAvailable ? metricDelegate.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)
                            sampleCount: SystemInfo.historyLength
                            smoothScroll: Config.sysMonitor?.smooth ?? false
                            interval: SystemInfo.pollInterval
                        }
                    }

                    Text {
                        text: metricDelegate.liveAvailable 
                                ? Math.round(metricDelegate.liveValue) + (metricDelegate.modelData.id === "temp" ? SystemInfo.tempUnit : "%") 
                                : "—"
                        color: Colors.md3.on_surface
                        font.family: Config.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: metricDelegate.width
                        text: metricDelegate.liveDetail || ""
                        color: Qt.alpha(Colors.md3.on_surface, 0.65)
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }
            }
            }
        }
    }

    Row {
        id: pillsRow
        anchors.verticalCenter: parent.verticalCenter
        height: 32
        spacing: root.unifiedPill ? 0 : 6

        Rectangle {
            visible: root.unifiedPill
            radius: height / 2
            height: 32
            
            readonly property real leftPadding: {
                if (root.barStyle === 1) {
                    return 4;
                }
                return 8;
            }
            readonly property real rightPadding: {
                if (!root.showPercent) {
                    return leftPadding;
                }
                if (root.barStyle === 1) {
                    return 8;
                }
                return 10;
            }
            
            width: unifiedRow.implicitWidth + leftPadding + rightPadding
            color: root.pillColor()

            Row {
                id: unifiedRow
                anchors.left: parent.left
                anchors.leftMargin: parent.leftPadding
                anchors.verticalCenter: parent.verticalCenter
                height: root.barStyle === 1 ? 24 : 20
                spacing: root.barStyle === 1 ? 8 : 12

                Repeater {
                    model: root.unifiedPill ? root.activeMetrics : []

                    delegate: MetricContent {
                        required property var modelData
                        owner: root
                        metricData: modelData
                    }
                }
            }
        }

        Repeater {
            model: root.unifiedPill ? [] : root.activeMetrics

            delegate: Rectangle {
                id: pillDelegate
                required property var modelData
                radius: height / 2
                height: 32
                
                readonly property real leftPadding: {
                    if (root.barStyle === 1) {
                        return 4;
                    }
                    return 8;
                }
                readonly property real rightPadding: {
                    if (!root.showPercent) {
                        return leftPadding;
                    }
                    if (root.barStyle === 1) {
                        return 8;
                    }
                    return 10;
                }
                
                width: pillContent.implicitWidth + leftPadding + rightPadding
                color: root.pillColor()

                MetricContent {
                    id: pillContent
                    anchors.left: parent.left
                    anchors.leftMargin: pillDelegate.leftPadding
                    anchors.verticalCenter: parent.verticalCenter
                    owner: root
                    metricData: pillDelegate.modelData
                }
            }
        }
    }

    MouseArea {
        anchors.fill: pillsRow
        hoverEnabled: true
        onClicked: {
            if (PanelService.current)
                PanelService.current.close();
        }
        onEntered: tooltip.show(pillsRow, "")
        onExited: tooltip.hide()
    }
}