import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.sunmoon")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 4, h: 3 })
    maxSpan: ({ w: 10, h: 5 })
    frameCornerRadius: 20

    settingsPanel: Component {
        SunMoonSettings {
            entryId: shell.entryId
        }
    }

    SunMoonVisual {
        anchors.fill: parent
        mode: shell.entryData.mode ?? "both"
        showIllumination: shell.entryData.showIllumination ?? true
    }
}
