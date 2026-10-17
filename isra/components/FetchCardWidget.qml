import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.fetchcard")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 3, h: 2 })
    maxSpan: ({ w: 10, h: 5 })
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
