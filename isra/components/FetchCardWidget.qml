import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.fetchcard")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 4, h: 3 })
    maxSpan: ({ w: 12, h: 8 })
    frameCornerRadius: 20

    settingsPanel: Component {
        FetchCardSettings {
            entryId: shell.entryId
        }
    }

    FetchCardVisual {
        anchors.fill: parent
        showLogo: shell.entryData.showLogo ?? true
        showSwatches: shell.entryData.showSwatches ?? true
    }
}
