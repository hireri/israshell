import QtQuick
import Quickshell.Widgets
import qs.style
import qs.services

Item {
    id: root

    Component.onCompleted: SystemInfo.registerLiveConsumer()
    Component.onDestruction: SystemInfo.unregisterLiveConsumer()

    property string metric: "cpu"

    property bool showReadout: true

    readonly property var _meta: ({
        cpu: { label: Localization.t("sysMonitor.cpu"), color: Colors.md3.primary },
        ram: { label: Localization.t("sysMonitor.ram"), color: Colors.md3.tertiary },
        gpu: { label: Localization.t("sysMonitor.gpu"), color: Colors.md3.secondary },
        temp: { label: Localization.t("sysMonitor.temp"), color: Colors.md3.error },
        swap: { label: Localization.t("sysMonitor.swap"), color: Colors.md3.outline }
    })

    readonly property var meta: root._meta[root.metric] ?? root._meta.cpu

    readonly property bool _isTemp: root.metric === "temp"
    readonly property real _rawTemp: Math.max(SystemInfo.cpuTemp, SystemInfo.gpuTemp)

    readonly property bool available: {
        switch (root.metric) {
        case "gpu":
            return SystemInfo.gpuUsage >= 0;
        case "temp":
            return SystemInfo.cpuTemp >= 0 || SystemInfo.gpuTemp >= 0;
        default:
            return true;
        }
    }

    readonly property real fraction: {
        if (!root.available)
            return 0;
        if (root._isTemp)
            return Math.max(0, Math.min(1, root._rawTemp / 100));
        switch (root.metric) {
        case "ram":
            return Math.max(0, Math.min(1, SystemInfo.ramUsage / 100));
        case "gpu":
            return Math.max(0, Math.min(1, SystemInfo.gpuUsage / 100));
        case "swap":
            return Math.max(0, Math.min(1, SystemInfo.swapUsage / 100));
        default:
            return Math.max(0, Math.min(1, SystemInfo.cpuUsage / 100));
        }
    }

    readonly property string readout: {
        if (!root.available)
            return "—";
        if (root._isTemp) {
            const t = Math.max(SystemInfo.cpuTempDisplay, SystemInfo.gpuTempDisplay);
            return Math.round(t) + "°";
        }
        return Math.round(root.fraction * 100) + "%";
    }

    readonly property real _extent: Math.min(root.width, root.height)
    readonly property real _disc: root._extent * 0.88
    readonly property real _stroke: Math.max(2, root._disc * 0.085)

    property real _animProgress: 0
    Binding {
        target: root
        property: "_animProgress"
        value: root.fraction
    }
    Behavior on _animProgress {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }

    readonly property real _ringPad: root._disc * 0.1

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: root._disc
        height: root._disc
        radius: width / 2
        color: Colors.md3.surface_container_high
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)
    }

    ProgressRing {
        anchors.centerIn: parent
        width: root._disc - root._ringPad * 2
        height: width
        progress: root._animProgress
        strokeWidth: root._stroke
        activeColor: root.meta.color
        trackColor: Qt.alpha(root.meta.color, 0.25)
    }

    Column {
        anchors.centerIn: parent
        spacing: -root._disc * 0.02
        visible: root.showReadout

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.readout
            font.family: Config.fontFamily
            font.pixelSize: Math.max(8, root._disc * 0.21)
            font.weight: Font.DemiBold
            color: Colors.md3.on_surface
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.meta.label
            font.family: Config.fontFamily
            font.pixelSize: Math.max(6, root._disc * 0.105)
            font.weight: Font.Medium
            font.letterSpacing: root._extent * 0.006
            color: Colors.md3.on_surface_variant
        }
    }
}
