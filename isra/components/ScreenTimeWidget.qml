import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.screentimecard")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 3, h: 2 })
    maxSpan: ({ w: 10, h: 4 })
    frameCornerRadius: 20

    settingsPanel: Component {
        ScreenTimeSettings {
            entryId: shell.entryId
        }
    }

    ScreenTimeVisual {
        anchors.fill: parent
        interactive: !EditModeService.active
        showBar: shell.entryData.showBar ?? true
        showApps: shell.entryData.showApps ?? true
        showChart: shell.entryData.showChart ?? true
        maxApps: shell.entryData.maxApps ?? 5
    }
}
