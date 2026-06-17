import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.style

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    exclusionMode: ExclusionMode.Ignore
    
    color: "transparent"
    focusable: (Config.clock.manualPos ?? false) && !LockscreenService.locked

    WlrLayershell.namespace: "quickshell:background"
    WlrLayershell.layer: WlrLayer.Bottom
    anchors { top: true; bottom: true; left: true; right: true }

    readonly property bool shouldBlur: LockscreenService.locked || LockscreenService.lockVisualActive

    Image {
        id: wallImg
        anchors.fill: parent
        source: WallpaperService.currentWall ? ("file://" + WallpaperService.currentWall) : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    FastBlur {
        anchors.fill: parent
        source: wallImg
        radius: 64
        opacity: root.shouldBlur ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
        }

        Rectangle {
            anchors.fill: parent
            color: "#80000000"
        }
    }

    Loader {
        anchors.fill: parent
        active: Config.desktopClock
        sourceComponent: ClockWidget { modelData: root.modelData }
    }
}
