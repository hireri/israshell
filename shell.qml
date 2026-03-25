import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris

import "./Colors.qml"
import "./Config.qml"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window
        property var modelData
        screen: modelData

        anchors.top: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 42

        color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container, 0.8) : Colors.md3.surface_container

        Item {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                radius: 12
                width: leftContent.implicitWidth + 20
                height: 32

                Row {
                    id: leftContent
                    anchors.centerIn: parent
                    spacing: 8

                    IconImage {
                        implicitSize: 28
                        anchors.verticalCenter: parent.verticalCenter
                        source: {
                            const active = Hyprland.toplevels.values.find(t => t.activated);
                            return active && active.wayland ? "image://icon/" + active.wayland.appId : "";
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: {
                                const active = Hyprland.toplevels.values.find(t => t.activated);
                                return active && active.wayland ? active.wayland.appId : "";
                            }
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 10
                            font.family: Config.fontFamily
                        }

                        Text {
                            text: {
                                const active = Hyprland.toplevels.values.find(t => t.activated);
                                return active ? active.title : "";
                            }
                            color: Colors.md3.on_surface
                            font.pixelSize: 12
                            font.family: Config.fontFamily
                        }
                    }
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
                    radius: 12
                    width: 240
                    height: 32

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton | Qt.MiddleButton

                        onClicked: mouse => {
                            const player = Mpris.players.values[0];
                            if (!player)
                                return;
                            if (mouse.button === Qt.RightButton)
                                player.next();
                            if (mouse.button === Qt.MiddleButton) {
                                player.playbackState === MprisPlaybackState.Playing ? player.pause() : player.play();
                            }
                        }

                        onWheel: wheel => {
                            const player = Mpris.players.values[0];
                            if (!player)
                                return;
                            player.volume = Math.max(0, Math.min(1, player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            width: 24
                            height: 24
                            layer.enabled: true
                            layer.smooth: true
                            antialiasing: true

                            anchors.verticalCenter: parent.verticalCenter
                            property real targetRotation: 0

                            Timer {
                                interval: 16
                                running: {
                                    const player = Mpris.players.values[0];
                                    return Config.spinningCover && player && player.playbackState === MprisPlaybackState.Playing;
                                }
                                repeat: true
                                onTriggered: parent.targetRotation += 0.5
                            }

                            Behavior on rotation {
                                SmoothedAnimation {
                                    duration: 1000
                                    easing.type: Easing.OutQuad
                                }
                            }

                            rotation: targetRotation

                            ClippingWrapperRectangle {
                                anchors.fill: parent
                                radius: 30
                                child: Item {
                                    anchors.fill: parent

                                    Rectangle {
                                        anchors.fill: parent
                                        color: Colors.md3.surface_container_highest

                                        Text {
                                            anchors.centerIn: parent
                                            text: "♪"
                                            color: Colors.md3.on_surface_variant
                                            font.pixelSize: 14
                                            font.family: Config.fontFamily
                                        }
                                    }

                                    Image {
                                        anchors.fill: parent
                                        source: {
                                            const player = Mpris.players.values[0];
                                            return player ? player.trackArtUrl : "";
                                        }
                                        visible: {
                                            const player = Mpris.players.values[0];
                                            return player && player.trackArtUrl;
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            id: mediaTextContainer
                            width: 200
                            height: 20
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter

                            property bool shouldScroll: mediaText.implicitWidth > width
                            property real scrollPos: 0

                            NumberAnimation {
                                id: scrollAnim
                                target: mediaTextContainer
                                property: "scrollPos"
                                from: 0
                                to: mediaText.implicitWidth + 20
                                duration: (mediaText.implicitWidth + 20) * 1000 / Config.carouselSpeed
                                loops: Animation.Infinite
                            }

                            Text {
                                id: mediaText
                                anchors.verticalCenter: parent.verticalCenter
                                x: mediaTextContainer.shouldScroll ? -mediaTextContainer.scrollPos : (mediaTextContainer.width - implicitWidth) / 2
                                color: Colors.md3.on_surface
                                font.family: Config.fontFamily
                                font.pixelSize: 14
                                text: {
                                    const player = Mpris.players.values[0];
                                    if (!player)
                                        return "nothing playing   ᓚ₍ ^. .^₎";
                                    return player.trackTitle + " • " + player.trackArtist;
                                }

                                onTextChanged: {
                                    if (mediaTextContainer.shouldScroll) {
                                        scrollAnim.restart();
                                    } else {
                                        scrollAnim.stop();
                                        mediaTextContainer.scrollPos = 0;
                                    }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: mediaText.x + mediaText.implicitWidth + 20
                                visible: mediaTextContainer.shouldScroll
                                color: Colors.md3.on_surface
                                font.family: Config.fontFamily
                                font.pixelSize: 14
                                text: mediaText.text
                            }

                            Rectangle {
                                anchors.left: parent.left
                                width: 20
                                height: parent.height
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop {
                                        position: 0.0
                                        color: Colors.md3.surface_container_high
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: "transparent"
                                    }
                                }
                                visible: mediaTextContainer.shouldScroll
                            }

                            Rectangle {
                                anchors.right: parent.right
                                width: 20
                                height: parent.height
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop {
                                        position: 0.0
                                        color: "transparent"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: Colors.md3.surface_container_high
                                    }
                                }
                                visible: mediaTextContainer.shouldScroll
                            }
                        }
                    }
                }

                Rectangle {
                    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
                    radius: 12
                    width: workspacesContent.implicitWidth + 28
                    height: 32

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: Qt.PointingHandCursor

                        onWheel: wheel => {
                            const monitor = Hyprland.monitorFor(window.modelData);
                            if (!monitor)
                                return;

                            const currentWs = Hyprland.workspaces.values.find(w => w.active && w.monitor === monitor);
                            if (!currentWs)
                                return;

                            const currentId = currentWs.id;
                            const direction = wheel.angleDelta.y > 0 ? -1 : 1;

                            const otherMonitorWorkspaces = new Set(Hyprland.workspaces.values.filter(w => w.monitor && w.monitor !== monitor).map(w => w.id));

                            let target = currentId;
                            let attempts = 0;

                            do {
                                target += direction;
                                if (target > 10)
                                    target = 1;
                                if (target < 1)
                                    target = 10;
                                attempts++;
                                if (attempts > 10)
                                    return;
                            } while (otherMonitorWorkspaces.has(target) && target !== currentId)

                            if (target !== currentId && !otherMonitorWorkspaces.has(target)) {
                                Hyprland.dispatch("workspace " + target);
                            }
                        }
                    }

                    Row {
                        id: workspacesContent
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            model: 10
                            Item {
                                width: 12
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 5
                                    anchors.centerIn: parent

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 250
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    color: {
                                        const wsId = index + 1;
                                        const monitor = Hyprland.monitorFor(window.modelData);
                                        if (!monitor)
                                            return Colors.md3.outline_variant;

                                        const ws = Hyprland.workspaces.values.find(w => w.id === wsId);

                                        if (ws && ws.active && ws.monitor === monitor) {
                                            return Colors.md3.primary;
                                        }

                                        const exists = Hyprland.workspaces.values.some(w => w.id === wsId);
                                        return exists ? Colors.md3.outline : Colors.md3.outline_variant;
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
                    radius: 12
                    width: clockContent.implicitWidth + 20
                    height: 32

                    Text {
                        id: clockContent
                        padding: 12
                        anchors.centerIn: parent
                        color: Colors.md3.on_surface
                        font.family: Config.fontFamily
                        font.pixelSize: 14

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm") + " " + Qt.formatDate(new Date(), "ddd dd/MM")
                        }

                        Component.onCompleted: text = Qt.formatTime(new Date(), "hh:mm") + " " + Qt.formatDate(new Date(), "ddd dd/MM")
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    id: trayContainer
                    visible: (SystemTray.items?.count ?? 0) > 0

                    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
                    radius: 12
                    width: trayContent.implicitWidth + 20
                    height: 32

                    Row {
                        id: trayContent
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            id: trayRepeater
                            model: SystemTray.items

                            delegate: Item {
                                required property var modelData
                                width: 20
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon || ""
                                    sourceSize: Qt.size(20, 20)
                                    fillMode: Image.PreserveAspectFit
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton) {
                                            modelData.activate();
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            modelData.secondaryActivate();
                                        } else if (mouse.button === Qt.RightButton) {
                                            const pos = mapToItem(null, mouse.x, mouse.y);
                                            modelData.display(window, pos.x, pos.y);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
                    radius: 12
                    width: rightContent.implicitWidth + 20
                    height: 32

                    Text {
                        id: rightContent
                        anchors.centerIn: parent
                        text: "quick settings"
                        color: Colors.md3.on_surface
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
