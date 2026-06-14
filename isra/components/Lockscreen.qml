import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

import qs.services
import qs.style

Item {
    WlSessionLock {
        id: sessionLock
        locked: LockscreenService.locked

        WlSessionLockSurface {
            id: lockSurface
            color: "transparent"

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
                color: Qt.alpha(Colors.md3.surface, 0.5)
            }

            ClockWidget {
                anchors.fill: parent
                modelData: lockSurface.screen
                forceVisible: true
            }

            LockSurface {
                anchors.fill: parent
            }
        }
    }
}