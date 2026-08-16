import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.statring")
    sizeMode: "uniform"
    minSpan: ({ w: 1, h: 1 })
    maxSpan: ({ w: 4, h: 4 })

    defaultSize: 120
    minSize: 56

    readonly property string metric: shell.entryData.metric ?? "cpu"

    settingsPanel: Component {
        StatRingSettings {
            entryId: shell.entryId
        }
    }

    StatRingVisual {
        anchors.fill: parent
        metric: shell.metric
    }
}
