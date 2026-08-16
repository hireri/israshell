import QtQuick
import qs.style
import qs.services
import qs.components.widgetsettings

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.weyes")
    sizeMode: "free"
    wallpaperRelative: true
    aspectLocked: false
    defaultWidth: 220
    defaultHeight: 120
    minWidth: 40
    minHeight: 25
    frameCornerRadius: 8

    settingsPanel: Component {
        WeyesSettings {
            entryId: shell.entryId
        }
    }

    readonly property bool _cursorAvailable: CompositorService.hasCapability("cursorPosition")

    property real smoothedCursorX: CursorService.x
    property real smoothedCursorY: CursorService.y

    readonly property int smoothingDuration: CursorService.intervalMs + 20

    Behavior on smoothedCursorX {
        NumberAnimation { duration: shell.smoothingDuration; easing.type: Easing.OutQuad }
    }
    Behavior on smoothedCursorY {
        NumberAnimation { duration: shell.smoothingDuration; easing.type: Easing.OutQuad }
    }

    Component.onCompleted: CursorService.acquire()
    Component.onDestruction: CursorService.release()

    WeyesEyes {
        anchors.fill: parent
        visible: shell._cursorAvailable
        tracking: shell._cursorAvailable

        targetX: shell.smoothedCursorX - (shell.hostScreen?.x ?? 0) - shell.localX
        targetY: shell.smoothedCursorY - (shell.hostScreen?.y ?? 0) - shell.localY
    }
}
