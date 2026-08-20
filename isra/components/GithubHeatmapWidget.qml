import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.github_heatmap")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 6, h: 3 })
    maxSpan: ({ w: 12, h: 3 })
    frameCornerRadius: 20

    settingsPanel: Component {
        GithubHeatmapSettings {
            entryId: shell.entryId
        }
    }

    GithubHeatmapVisual {
        anchors.fill: parent
        username: shell.entryData.username ?? ""
    }
}
