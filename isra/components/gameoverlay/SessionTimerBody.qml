import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.style

Item {
    id: root

    property real now: Date.now()

    implicitWidth: 240
    implicitHeight: column.implicitHeight

    function format(ms) {
        const s = Math.max(0, Math.floor(ms / 1000));
        const pad = n => (n < 10 ? "0" : "") + n;
        const h = Math.floor(s / 3600);
        return (h > 0 ? h + ":" : "") + pad(Math.floor(s / 60) % 60) + ":" + pad(s % 60);
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.format(GameOverlayService.timerElapsed(root.now))
            font.family: Config.fontFamily
            font.pixelSize: 36
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
            color: Colors.md3.on_surface
            renderType: Text.NativeRendering
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Localization.t("gameOverlay.local_time") + " " + Qt.formatTime(new Date(root.now), Config.hourFormat === 0 ? "HH:mm" : "h:mm ap")
            font.family: Config.fontFamily
            font.pixelSize: 11
            color: Colors.md3.outline
            renderType: Text.NativeRendering
        }

        ChipRow {
            Layout.alignment: Qt.AlignHCenter
            large: true
            options: [
                {
                    value: "toggle",
                    label: GameOverlayService.timerRunning ? Localization.t("gameOverlay.timer_pause") : Localization.t("gameOverlay.timer_start")
                },
                {
                    value: "reset",
                    label: Localization.t("gameOverlay.timer_reset")
                }
            ]
            currentValue: GameOverlayService.timerRunning ? "toggle" : ""
            onSelected: v => v === "toggle" ? GameOverlayService.timerToggle() : GameOverlayService.timerReset()
        }
    }
}
