pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import qs.components
import qs.services
import qs.style
import qs.windows.components

Item {
    id: root

    readonly property string host: Config.gameOverlay.pingHost
    readonly property int length: 40

    property var samples: []
    readonly property var replies: root.samples.filter(v => v >= 0)
    readonly property real last: root.samples.length > 0 ? root.samples[root.samples.length - 1] : -1
    readonly property real avg: root.replies.length > 0 ? root.replies.reduce((a, b) => a + b, 0) / root.replies.length : 0
    readonly property real loss: root.samples.length > 0 ? 100 * (root.samples.length - root.replies.length) / root.samples.length : 0

    implicitWidth: 300
    implicitHeight: column.implicitHeight

    function push(v) {
        root.samples = root.samples.concat([v]).slice(-root.length);
    }

    function setHost(text) {
        const h = text.trim();
        if (/^[A-Za-z0-9][A-Za-z0-9.:_-]*$/.test(h) && h !== root.host) {
            root.samples = [];
            GameOverlayService.setOption("pingHost", h);
        }
    }

    Process {
        id: probe
        command: ["ping", "-n", "-c", "1", "-W", "1", root.host]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /time=([\d.]+)/.exec(text);
                root.push(m ? parseFloat(m[1]) : -1);
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!probe.running)
            probe.running = true
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.last < 0 ? (root.samples.length > 0 ? Localization.t("gameOverlay.ping_timeout") : "…") : Math.round(root.last) + " ms"
                font.family: Config.fontFamily
                font.pixelSize: 22
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                color: root.last < 0 ? Colors.md3.error : Colors.md3.on_surface
                renderType: Text.NativeRendering
            }

            Text {
                text: Localization.t("gameOverlay.ping_avg") + " " + Math.round(root.avg) + " ms · " + Localization.t("gameOverlay.ping_loss") + " " + Math.round(root.loss) + "%"
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Colors.md3.on_surface_variant
                renderType: Text.NativeRendering
            }
        }

        ClippingRectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: 10
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Colors.md3.primary, 0.3)

            Sparkline {
                anchors.fill: parent
                points: root.samples.map(v => Math.max(v, 0))
                scaleMax: Math.max(50, Math.max.apply(null, root.samples.concat([0])) * 1.2)
                lineColor: Colors.md3.primary
                sampleCount: root.length
            }
        }

        TextInputField {
            Layout.fillWidth: true
            text: root.host
            placeholder: Localization.t("gameOverlay.ping_host")
            onCommitted: v => root.setHost(v)
        }
    }
}
