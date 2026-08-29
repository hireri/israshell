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
    readonly property var metricList: [
        { id: "cpu",  label: Localization.t("sysMonitor.cpu"),  icon: "memory",          color: Colors.md3.primary },
        { id: "ram",  label: Localization.t("sysMonitor.ram"),  icon: "memory-alt",      color: Colors.md3.tertiary },
        { id: "gpu",  label: Localization.t("sysMonitor.gpu"),  icon: "videogame-asset", color: Colors.md3.secondary },
        { id: "temp", label: Localization.t("sysMonitor.temp"), icon: "thermostat",      color: Colors.md3.error },
        { id: "swap", label: Localization.t("sysMonitor.swap"), icon: "swap-horiz",      color: Colors.md3.outline }
    ]

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
    readonly property var activeMetrics: metricList.filter(m => enabledIds.includes(m.id))

    function metricValue(id) {
        switch (id) {
        case "cpu":  return SystemInfo.cpuUsage;
        case "ram":  return SystemInfo.ramUsage;
        case "gpu":  return Math.max(0, SystemInfo.gpuUsage);
        case "temp":
            return Math.max(SystemInfo.cpuTempDisplay, SystemInfo.gpuTempDisplay);
        case "swap": return SystemInfo.swapUsage;
        }
        return 0;
    }

    function metricAvailable(id) {
        switch (id) {
        case "gpu":  return SystemInfo.gpuUsage >= 0;
        case "temp": return SystemInfo.cpuTemp >= 0 || SystemInfo.gpuTemp >= 0;
        default:     return true;
        }
    }

    function metricDetail(id) {
        switch (id) {
        case "cpu":  
            let cpuName = SystemInfo.cpu.replace(/ \d+-Core| Processor| CPU/gi, "").trim();
            let cpuSpecs = [];
            if (SystemInfo.cpuFreq !== "—" && SystemInfo.cpuFreq !== "") cpuSpecs.push(SystemInfo.cpuFreq);
            if (SystemInfo.cpuPower !== "—" && SystemInfo.cpuPower !== "") cpuSpecs.push(SystemInfo.cpuPower);
            return cpuName + (cpuSpecs.length > 0 ? "\n" + cpuSpecs.join(" • ") : "");

        case "ram":  
            return SystemInfo.ramUsedLabel + " / " + SystemInfo.ramTotalLabel;

        case "gpu":  
            let gpuName = SystemInfo.gpu.replace(/AMD |NVIDIA |Intel /gi, "").trim();
            let gpuSpecs = [];
            if (SystemInfo.gpuFreq !== "—" && SystemInfo.gpuFreq !== "") gpuSpecs.push(SystemInfo.gpuFreq);
            if (SystemInfo.gpuPower !== "—" && SystemInfo.gpuPower !== "") gpuSpecs.push(SystemInfo.gpuPower);
            return gpuName + (gpuSpecs.length > 0 ? "\n" + gpuSpecs.join(" • ") : "");

        case "temp": 
            let tempParts = [];
            if (SystemInfo.cpuTemp >= 0) {
                tempParts.push("CPU " + Math.round(SystemInfo.cpuTempDisplay) + SystemInfo.tempUnit + (SystemInfo.cpuPower !== "—" ? " • " + SystemInfo.cpuPower : ""));
            }
            if (SystemInfo.gpuTemp >= 0) {
                tempParts.push("GPU " + Math.round(SystemInfo.gpuTempDisplay) + SystemInfo.tempUnit + (SystemInfo.gpuPower !== "—" ? " • " + SystemInfo.gpuPower : ""));
            }
            return tempParts.length > 0 ? tempParts.join("\n") : "—";

        case "swap":  
            return SystemInfo.swapUsedLabel + " / " + SystemInfo.swapTotalLabel;
        }
        return "";
    }

    function metricHistory(id) {
        switch (id) {
        case "cpu":  return SystemInfo.cpuHistory;
        case "ram":  return SystemInfo.ramHistory;
        case "gpu":  return SystemInfo.gpuHistory;
        case "temp": return SystemInfo.cpuTempHistoryDisplay;
        case "swap": return SystemInfo.swapHistory;
        }
        return [];
    }

    function metricScale(id) {
        if (id === "temp") {
            return Config.useFahrenheit ? 250 : 120;
        }
        return 100;
    }

    implicitWidth: pillsRow.implicitWidth
    implicitHeight: 32

    component MetricContent: Row {
        id: metricContent
        required property var owner
        required property var metricData
        spacing: 4
        height: owner.barStyle === 1 ? 24 : 20

        property real liveValue: owner.metricValue(metricData.id)
        property bool liveAvailable: owner.metricAvailable(metricData.id)
        property real liveScale: owner.metricScale(metricData.id)
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
        yOffset: 4

        Loader {
            active: tooltip._shown
            sourceComponent: tooltipRowComponent
        }

        Component {
            id: tooltipRowComponent

            Row {
            spacing: 20

            Repeater {
                model: root.metricList

                delegate: Column {
                    id: metricDelegate
                    required property var modelData
                    spacing: 5
                    width: 92

                    property real liveValue: root.metricValue(modelData.id)
                    property bool liveAvailable: root.metricAvailable(modelData.id)
                    property string liveDetail: root.metricDetail(modelData.id)
                    property var liveHistory: root.metricHistory(modelData.id)
                    property real liveScale: root.metricScale(modelData.id)
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

                        Shape {
                            id: sparkline
                            anchors.fill: parent
                            property real sampleSpacing: width / Math.max(1, SystemInfo.historyLength - 1)
                            property var points: metricDelegate.liveHistory
                            property real scaleMax: metricDelegate.liveScale
                            property color lineColor: metricDelegate.liveAvailable ? metricDelegate.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)
                            property color gridColor: Qt.alpha(lineColor, 0.15)

                            readonly property bool smoothEnabled: Config.sysMonitor?.smooth ?? false
                            property real smoothOffset: 0

                            property var _prevPoints: []
                            property var extendedPoints: []

                            NumberAnimation {
                                id: smoothAnim
                                target: sparkline
                                property: "smoothOffset"
                                from: sparkline.sampleSpacing
                                to: 0
                                duration: SystemInfo.pollInterval
                                easing.type: Easing.Linear
                            }

                            Connections {
                                target: SystemInfo
                                function onCycleStarted() {
                                    if (sparkline.smoothEnabled) {
                                        smoothAnim.restart();
                                    }
                                }
                            }

                            onPointsChanged: {
                                var pts = points || [];
                                if (smoothEnabled && pts.length > 1 && _prevPoints.length > 0) {
                                    extendedPoints = [_prevPoints[0]].concat(pts);
                                } else {
                                    extendedPoints = pts;
                                }
                                _prevPoints = pts;
                            }

                            onSmoothEnabledChanged: extendedPoints = points || []

                            readonly property real _pad: 2
                            readonly property var _linePoints: {
                                const pts = sparkline.extendedPoints || [];
                                if (pts.length < 2 || sparkline.width <= 0 || sparkline.height <= 0)
                                    return [];
                                const rightIdx = pts.length - 1;
                                const offset = sparkline.smoothEnabled ? sparkline.smoothOffset : 0;
                                const usableH = sparkline.height - sparkline._pad * 2;
                                const arr = [];
                                for (let i = 0; i < pts.length; i++) {
                                    const x = sparkline.width - (rightIdx - i) * sparkline.sampleSpacing + offset;
                                    const clamped = Math.max(0, Math.min(sparkline.scaleMax, pts[i]));
                                    const y = sparkline._pad + usableH - (clamped / sparkline.scaleMax) * usableH;
                                    arr.push(Qt.point(x, y));
                                }
                                return arr;
                            }

                            readonly property var _fillPoints: {
                                const lp = sparkline._linePoints;
                                if (lp.length < 2) return [];
                                const last = lp[lp.length - 1];
                                const first = lp[0];
                                return lp.concat([Qt.point(last.x, sparkline.height), Qt.point(first.x, sparkline.height)]);
                            }

                            readonly property var _gridPaths: {
                                const w = sparkline.width, h = sparkline.height;
                                if (w <= 0 || h <= 0) return [];
                                const rows = 4, cols = 6;
                                const rowHeight = h / rows, colWidth = w / cols;
                                const lines = [];
                                for (let g = 1; g < rows; g++) {
                                    const gy = Math.round(rowHeight * g) + 0.5;
                                    lines.push([Qt.point(0, gy), Qt.point(w, gy)]);
                                }
                                for (let c = 1; c < cols; c++) {
                                    const gx = Math.round(colWidth * c) + 0.5;
                                    lines.push([Qt.point(gx, 0), Qt.point(gx, h)]);
                                }
                                return lines;
                            }

                            ShapePath {
                                strokeColor: sparkline.gridColor
                                strokeWidth: 1
                                fillColor: "transparent"
                                PathMultiline {
                                    paths: sparkline._gridPaths
                                }
                            }

                            ShapePath {
                                strokeColor: "transparent"
                                fillColor: Qt.alpha(sparkline.lineColor, 0.18)
                                PathPolyline {
                                    path: sparkline._fillPoints
                                }
                            }

                            ShapePath {
                                strokeColor: sparkline.lineColor
                                strokeWidth: 1.5
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin
                                fillColor: "transparent"
                                PathPolyline {
                                    path: sparkline._linePoints
                                }
                            }
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
        onEntered: {
            var yPos = Config.bar.position === 1 ? 0 : height;
            tooltip.targetPos = root.mapToGlobal(width / 2, yPos);
            tooltip.open = true;
        }
        onExited: tooltip.open = false
    }
}