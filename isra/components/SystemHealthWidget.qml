import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.healthcard")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 3, h: 2 })
    maxSpan: ({ w: 6, h: 3 })
    frameCornerRadius: 20

    settingsPanel: Component {
        SystemHealthSettings {
            entryId: shell.entryId
        }
    }

    SystemHealthVisual {
        anchors.fill: parent
        interactive: !EditModeService.active
        showAreas: shell.entryData.showAreas ?? true
        showDetail: shell.entryData.showDetail ?? true
        tinted: shell.entryData.tinted ?? false
        areaList: shell.entryData.areas ?? ["packages", "storage", "system"]
    }
}
