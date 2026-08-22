import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.pomodoro")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 4, h: 2 })
    maxSpan: ({ w: 9, h: 4 })
    frameCornerRadius: 20

    settingsPanel: Component {
        PomodoroSettings {
            entryId: shell.entryId
        }
    }

    PomodoroVisual {
        anchors.fill: parent
    }
}
