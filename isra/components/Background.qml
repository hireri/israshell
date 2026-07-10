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

    property bool blurLoaderActive: false

    onShouldBlurChanged: {
        if (shouldBlur) {
            blurLoaderActive = true;
        } else {
            unloadDelay.restart();
        }
    }

    Timer {
        id: unloadDelay
        interval: 420
        onTriggered: root.blurLoaderActive = false
    }

    Component.onCompleted: {
        if (shouldBlur) blurLoaderActive = true;
    }

    Loader {
        id: blurLoader
        anchors.fill: parent
        active: root.blurLoaderActive

        onLoaded: {
            item.targetActive = root.shouldBlur;
        }

        sourceComponent: Item {
            id: blurRoot
            anchors.fill: parent

            property bool targetActive: false

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
                radius: blurRoot.targetActive ? 64 : 0

                Behavior on radius {
                    NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colors.md3.surface_container, 0.65)
                opacity: blurRoot.targetActive ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                }
            }

            Connections {
                target: root
                function onShouldBlurChanged() {
                    blurRoot.targetActive = root.shouldBlur;
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: Config.desktopClock
        sourceComponent: ClockWidget { modelData: root.modelData }
    }

    Item {
        anchors.fill: parent

        readonly property int gradientHeight: 120
        readonly property bool gradientOn: Config.transparentBar === 2 && !root.shouldBlur

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.gradientHeight

            opacity: (parent.gradientOn && Config.barPosition === 0) ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.alpha(Colors.md3.background, 0.6) }
                GradientStop { position: 1.0; color: Qt.alpha(Colors.md3.background, 0) }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.gradientHeight

            opacity: (parent.gradientOn && Config.barPosition === 1) ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.alpha(Colors.md3.background, 0) }
                GradientStop { position: 1.0; color: Qt.alpha(Colors.md3.background, 0.5) }
            }
        }
    }
}
