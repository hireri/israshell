import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.music")
    sizeMode: "uniform"
    minSpan: ({ w: 1, h: 1 })
    maxSpan: ({ w: 6, h: 6 })

    settingsPanel: Component {
        MusicSettings {
            entryId: shell.entryId
        }
    }

    defaultSize: 180
    minSize: 48

    MusicVisual {
        anchors.fill: parent
        buttonScale: shell.entryData.buttonScale ?? 0.28
        shape: shell.entryData.shape || "circle"
        playingShape: shell.entryData.playingShape || "cookie9"
        interactive: !EditModeService.active
    }
}
