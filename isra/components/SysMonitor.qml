pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property var panelWindow
    readonly property var metricList: [
        { id: "cpu",  label: "CPU",  icon: "memory",          color: Colors.md3.primary },
        { id: "ram",  label: "RAM",  icon: "memory-alt",      color: Colors.md3.tertiary },
        { id: "gpu",  label: "GPU",  icon: "videogame-asset", color: Colors.md3.secondary },
        { id: "temp", label: "Temp", icon: "thermostat",      color: Colors.md3.error },
        { id: "swap", label: "Swap", icon: "swap-horiz",      color: Colors.md3.outline }
    ]

    readonly property int barStyle: Config.sysMonitor?.style ?? 0
    readonly property bool showPercent: barStyle === 0 ? true : (Config.sysMonitor?.showPercent ?? true)
    readonly property bool unifiedPill: Config.sysMonitor?.unifiedPill ?? false
    readonly property bool colored: Config.sysMonitor?.colored ?? true

    function pillColor() {
        if (Config.bar.transparentPills) {
            return Config.bar.transparency ? Qt.alpha(Colors.md3.secondary_container, 0) : Colors.md3.surface_container;
        } else {
            return Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high;
        }
    }

    readonly property var enabledIds: Config.sysMonitor?.metrics ?? ["cpu", "ram"]
    readonly property var activeMetrics: metricList.filter(m => enabledIds.includes(m.id))

    function metricValue(id) {
        switch (id) {
        case "cpu":  return SystemInfo.cpuUsage;
        case "ram":  return SystemInfo.ramUsage;
        case "gpu":  return Math.max(0, SystemInfo.gpuUsage);
        case "temp": return SystemInfo.cpuTemp;
        case "swap": return SystemInfo.swapUsage;
        }
        return 0;
    }

    function metricAvailable(id) {
        switch (id) {
        case "gpu":  return SystemInfo.gpuUsage >= 0;
        case "temp": return SystemInfo.cpuTemp >= 0;
        default:     return true;
        }
    }

    function metricDetail(id) {
        switch (id) {
        case "cpu":  
            let cpuName = SystemInfo.cpu.replace(/ \d+-Core| Processor| CPU/gi, "").trim();
            let cpuTempStr = SystemInfo.cpuTemp >= 0 ? Math.round(SystemInfo.cpuTemp) + "°C" : "";
            if (SystemInfo.cpuPower !== "—" && SystemInfo.cpuPower !== "") {
                cpuTempStr += " • " + SystemInfo.cpuPower;
            }
            return cpuName + (cpuTempStr ? "\n" + cpuTempStr : "");

        case "ram":  
            return SystemInfo.ramUsedLabel + " / " + SystemInfo.ramTotalLabel;

        case "gpu":  
            let gpuName = SystemInfo.gpu.replace(/AMD |NVIDIA |Intel /gi, "").trim();
            let gpuTempStr = SystemInfo.gpuTemp >= 0 ? Math.round(SystemInfo.gpuTemp) + "°C" : "";
            if (SystemInfo.gpuPower !== "—" && SystemInfo.gpuPower !== "") {
                gpuTempStr += " • " + SystemInfo.gpuPower;
            }
            return gpuName + (gpuTempStr ? "\n" + gpuTempStr : "");

        case "temp": 
            let tempParts = [];
            if (SystemInfo.cpuTemp >= 0) {
                tempParts.push("CPU " + Math.round(SystemInfo.cpuTemp) + "°C" + (SystemInfo.cpuPower !== "—" ? " • " + SystemInfo.cpuPower : ""));
            }
            if (SystemInfo.gpuTemp >= 0) {
                tempParts.push("GPU " + Math.round(SystemInfo.gpuTemp) + "°C" + (SystemInfo.gpuPower !== "—" ? " • " + SystemInfo.gpuPower : ""));
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
        case "temp": return SystemInfo.cpuTempHistory;
        case "swap": return SystemInfo.swapHistory;
        }
        return [];
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
        property color resolvedColor: owner.colored ? metricData.color : Colors.md3.primary

        Item {
            id: pieWrap
            visible: metricContent.owner.barStyle === 1
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                id: pieCanvas
                anchors.fill: parent
                property real value: metricContent.liveValue
                property bool available: metricContent.liveAvailable
                property color pieColor: available ? metricContent.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)

                onValueChanged: requestPaint()
                onAvailableChanged: requestPaint()
                onPieColorChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    if (width <= 0 || height <= 0)
                        return;

                    var cx = width / 2;
                    var cy = height / 2;
                    var r = (Math.min(width, height) / 2) - 0.5;

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    ctx.fillStyle = Qt.alpha(pieColor, 0.5);
                    ctx.fill();

                    var frac = Math.max(0, Math.min(100, value)) / 100;
                    if (frac > 0) {
                        var start = -Math.PI / 2;
                        var end = start + frac * Math.PI * 2;
                        ctx.beginPath();
                        ctx.moveTo(cx, cy);
                        ctx.arc(cx, cy, r, start, end);
                        ctx.closePath();
                        ctx.fillStyle = pieColor;
                        ctx.fill();
                    }
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
                width: parent.width * Math.max(0, Math.min(100, metricContent.liveValue)) / 100
                height: parent.height
                radius: parent.radius
                color: metricContent.liveAvailable ? metricContent.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)
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
        yOffset: 8

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

                        Canvas {
                            id: sparkline
                            anchors.fill: parent
                            property real sampleSpacing: width / Math.max(1, SystemInfo.historyLength - 1)
                            property var points: metricDelegate.liveHistory
                            property color lineColor: metricDelegate.liveAvailable ? metricDelegate.resolvedColor : Qt.alpha(Colors.md3.on_surface, 0.35)
                            property color gridColor: Qt.alpha(lineColor, 0.15)
                            renderStrategy: Canvas.Immediate
                            
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
                                    requestPaint();
                                }
                                _prevPoints = pts;
                            }

                            onSmoothOffsetChanged: {
                                if (smoothEnabled) requestPaint();
                            }
                            
                            onSmoothEnabledChanged: {
                                extendedPoints = points || [];
                                requestPaint();
                            }

                            onLineColorChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();

                                var w = width;
                                var h = height;

                                var pad = 2;
                                var usableH = h - pad * 2;
                                var spacing = sampleSpacing;

                                var rows = 4;
                                var cols = 6;
                                var rowHeight = h / rows;
                                var colWidth = w / cols;

                                ctx.strokeStyle = gridColor;
                                ctx.lineWidth = 1;
                                ctx.beginPath();
                                for (var g = 1; g < rows; g++) {
                                    var gy = Math.round(rowHeight * g) + 0.5;
                                    ctx.moveTo(0, gy);
                                    ctx.lineTo(w, gy);
                                }
                                for (var c = 1; c < cols; c++) {
                                    var gx = Math.round(colWidth * c) + 0.5;
                                    ctx.moveTo(gx, 0);
                                    ctx.lineTo(gx, h);
                                }
                                ctx.stroke();

                                var pts = extendedPoints || []; 
                                if (pts.length < 2)
                                    return;

                                var rightIdx = pts.length - 1;
                                var offset = smoothEnabled ? smoothOffset : 0; 

                                function xFor(i) {
                                    return w - (rightIdx - i) * spacing + offset;
                                }

                                function yFor(v) {
                                    var clamped = Math.max(0, Math.min(100, v));
                                    return pad + usableH - (clamped / 100) * usableH;
                                }

                                ctx.beginPath();
                                ctx.moveTo(xFor(0), yFor(pts[0]));
                                for (var i = 1; i < pts.length; i++)
                                    ctx.lineTo(xFor(i), yFor(pts[i]));
                                ctx.lineTo(xFor(rightIdx), h);
                                ctx.lineTo(xFor(0), h);
                                ctx.closePath();
                                ctx.fillStyle = Qt.alpha(lineColor, 0.18);
                                ctx.fill();

                                ctx.beginPath();
                                ctx.moveTo(xFor(0), yFor(pts[0]));
                                for (var j = 1; j < pts.length; j++)
                                    ctx.lineTo(xFor(j), yFor(pts[j]));
                                ctx.strokeStyle = lineColor;
                                ctx.lineWidth = 1.5;
                                ctx.lineJoin = "round";
                                ctx.lineCap = "round";
                                ctx.stroke();
                            }
                        }
                    }

                    Text {
                        text: metricDelegate.liveAvailable ? Math.round(metricDelegate.liveValue) + "%" : "—"
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
        onEntered: {
            var yPos = Config.bar.position === 1 ? 0 : height;
            tooltip.targetPos = root.mapToGlobal(width / 2, yPos);
            tooltip.open = true;
        }
        onExited: tooltip.open = false
    }
}