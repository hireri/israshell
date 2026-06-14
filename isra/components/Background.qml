import QtQuick
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.services
import qs.style

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: true
    focusable: (Config.clock.manualPos ?? false) && !LockscreenService.locked

    WlrLayershell.namespace: "quickshell:background"
    WlrLayershell.layer: WlrLayer.Bottom

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Loader {
        id: lockBgLoader
        anchors.fill: parent
        active: LockscreenService.locked

        sourceComponent: Item {
            anchors.fill: parent

            Image {
                id: lockWallpaperImg
                anchors.fill: parent
                source: WallpaperService.currentWall ? ("file://" + WallpaperService.currentWall) : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            FastBlur {
                anchors.fill: parent
                source: lockWallpaperImg
                radius: 64
                transparentBorder: false
            }

            Rectangle {
                anchors.fill: parent
                color: "#80000000"
            }
        }

        opacity: active ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    Loader {
        anchors.fill: parent
        active: Config.desktopClock
        
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        sourceComponent: ClockWidget {
            modelData: root.modelData
        }
    }
}
