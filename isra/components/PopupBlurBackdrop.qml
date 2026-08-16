import QtQuick
import Qt5Compat.GraphicalEffects
import qs.services
import qs.style

Item {
    id: root

    required property var hostScreen
    property bool active: false

    anchors.fill: parent
    visible: false

    Loader {
        id: loader
        anchors.fill: parent
        active: root.active

        sourceComponent: Item {
            id: content
            anchors.fill: parent
            readonly property alias blurredItem: blurred

            Image {
                id: srcImg
                anchors.fill: parent
                source: (WallpaperService.currentWallPreview || WallpaperService.currentWall)
                    ? ("file://" + (WallpaperService.currentWallPreview || WallpaperService.currentWall))
                    : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
                asynchronous: true
                sourceSize.width: root.hostScreen ? Math.max(1, Math.round(root.hostScreen.width * root.hostScreen.devicePixelRatio / 4)) : 480
                sourceSize.height: root.hostScreen ? Math.max(1, Math.round(root.hostScreen.height * root.hostScreen.devicePixelRatio / 4)) : 270
            }

            FastBlur {
                id: blurred
                anchors.fill: parent
                source: srcImg
                radius: 64
                visible: false
            }
        }
    }

    readonly property Item texture: loader.item ? loader.item.blurredItem : null
}
