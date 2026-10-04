import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.components.gameoverlay
import qs.icons
import qs.services
import qs.style

Scope {
    LazyLoader {
        active: GameOverlayService.previewing && !(GameOverlayService.isOpen("crosshair") && (GameOverlayService.visible || GameOverlayService.hasPinned))

        PanelWindow {
            id: preview

            readonly property var saved: GameOverlayService.widgetState("crosshair")

            screen: Quickshell.screens.find(s => s.name === GameOverlayService.gameMonitor) ?? Quickshell.screens.find(s => s.name === CompositorService.focusedMonitor.name) ?? Quickshell.screens[0]

            WlrLayershell.namespace: "quickshell:crosshairPreview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            CrosshairBody {
                x: Math.round((preview.saved.rcx !== undefined ? preview.saved.rcx * preview.width : (preview.saved.cx ?? preview.width / 2)) - width / 2)
                y: Math.round((preview.saved.rcy !== undefined ? preview.saved.rcy * preview.height : (preview.saved.cy ?? preview.height / 2)) - height / 2)
            }
        }
    }

    LazyLoader {
        active: GameOverlayService.visible || GameOverlayService.hasPinned || GameOverlayService.instantHidden

        PanelWindow {
            id: w

            readonly property bool open: GameOverlayService.visible
            readonly property string monitorName: GameOverlayService.gameMonitor || CompositorService.focusedMonitor.name

            screen: Quickshell.screens.find(s => s.name === w.monitorName) ?? Quickshell.screens[0]

            WlrLayershell.namespace: "quickshell:gameOverlay"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: w.open && !GameOverlayService.suspended ? WlrKeyboardFocus.Exclusive : (GameOverlayService.clickableItems.length > 0 ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            mask: w.open ? null : closedMask

            Component {
                id: regionComponent
                Region {}
            }

            Region {
                id: closedMask
                regions: GameOverlayService.clickableItems.map(item => regionComponent.createObject(closedMask, {
                        item: item
                    }))
            }

            property real progress

            NumberAnimation {
                id: enter
                target: w
                property: "progress"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }

            function releaseGrab() {
                if (!PanelService.current || PanelService.current === GameOverlayService)
                    CompositorService.releasePanelFocus();
            }

            function sync() {
                if (w.open) {
                    enter.restart();
                    grabTimer.restart();
                } else {
                    grabTimer.stop();
                    w.releaseGrab();
                }
            }

            Connections {
                target: GameOverlayService
                function onVisibleChanged() {
                    w.sync();
                }
                function onSuspendedChanged() {
                    if (GameOverlayService.suspended) {
                        grabTimer.stop();
                        CompositorService.releasePanelFocus();
                    }
                }
            }

            Component {
                id: crosshairBody
                CrosshairBody {}
            }
            Component {
                id: resourcesBody
                ResourcesBody {}
            }
            Component {
                id: mixerBody
                MixerBody {}
            }
            Component {
                id: captureBody
                CaptureBody {}
            }
            Component {
                id: notesBody
                NotesBody {}
            }
            Component {
                id: fpsBody
                FpsLimiterBody {}
            }

            Component {
                id: nowPlayingBody
                NowPlayingBody {}
            }
            Component {
                id: sessionTimerBody
                SessionTimerBody {}
            }
            Component {
                id: devicesBody
                DevicesBody {}
            }
            Component {
                id: temperaturesBody
                TempsBody {}
            }
            Component {
                id: discordBody
                DiscordVoiceBody {}
            }
            Component {
                id: pingBody
                PingBody {}
            }

            readonly property var bodies: ({
                    nowPlaying: nowPlayingBody,
                    sessionTimer: sessionTimerBody,
                    ping: pingBody,
                    discordVoice: discordBody,
                    devices: devicesBody,
                    temperatures: temperaturesBody,
                    crosshair: crosshairBody,
                    resources: resourcesBody,
                    volumeMixer: mixerBody,
                    recorder: captureBody,
                    notes: notesBody,
                    fpsLimiter: fpsBody
                })

            Timer {
                id: grabTimer
                interval: 100
                onTriggered: CompositorService.grabPanelFocus([w])
            }

            Component.onCompleted: {
                if (!GameOverlayService.gameMonitor)
                    GameOverlayService.gameMonitor = w.monitorName;
                if (w.open)
                    w.sync();
            }

            Component.onDestruction: w.releaseGrab()

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            contentItem {
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape)
                        GameOverlayService.close();
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: w.open && Config.gameOverlay.darkenScreen
                color: Qt.alpha(Colors.md3.scrim, 0.6)
                opacity: w.progress

                MouseArea {
                    anchors.fill: parent
                    onClicked: GameOverlayService.close()
                }
            }

            Item {
                id: stage
                anchors.fill: parent
                visible: !GameOverlayService.instantHidden
                opacity: w.open ? w.progress : 1
                scale: (w.open && Config.gameOverlay.zoomAnimation) ? 1.08 - 0.08 * w.progress : 1

                Repeater {
                    model: ScriptModel {
                        values: GameOverlayService.openWidgets
                        objectProp: "id"
                    }

                    delegate: OverlayWidget {
                        required property var modelData
                        meta: modelData
                        bodyComponent: w.bodies[modelData.id]
                    }
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        topMargin: 40
                        horizontalCenter: parent.horizontalCenter
                    }
                    z: 20
                    visible: w.open
                    height: 52
                    width: bar.implicitWidth + 16
                    radius: height / 2
                    color: Colors.md3.surface_container
                    border.width: 1
                    border.color: Colors.md3.outline_variant

                    MouseArea {
                        anchors.fill: parent
                    }

                    RowLayout {
                        id: bar
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialIcon {
                            Layout.leftMargin: 8
                            name: "videogame-asset"
                            iconSize: 20
                            filled: true
                            color: Colors.md3.primary
                            transitionType: "none"
                        }

                        Text {
                            Layout.maximumWidth: 240
                            Layout.rightMargin: 4
                            text: GameOverlayService.gameTitle || Localization.t("gameOverlay.title")
                            elide: Text.ElideRight
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Colors.md3.on_surface
                            renderType: Text.NativeRendering
                        }

                        Rectangle {
                            implicitWidth: 1
                            implicitHeight: 24
                            color: Colors.md3.outline_variant
                        }

                        Repeater {
                            model: GameOverlayService.catalog

                            delegate: OverlayButton {
                                required property var modelData
                                icon: modelData.icon
                                toggled: GameOverlayService.isOpen(modelData.id)
                                filled: toggled
                                iconTransition: "wipe-left"
                                tip: Localization.t(modelData.titleKey)
                                onClicked: GameOverlayService.toggleWidget(modelData.id)
                                onRightClicked: GameOverlayService.centerRequested(modelData.id)
                            }
                        }

                        Rectangle {
                            implicitWidth: 1
                            implicitHeight: 24
                            color: Colors.md3.outline_variant
                        }

                        Text {
                            Layout.leftMargin: 4
                            text: Qt.formatTime(clock.date, Config.hourFormat === 0 ? "HH:mm" : "h:mm ap")
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            color: Colors.md3.on_surface_variant
                            renderType: Text.NativeRendering
                        }

                        BatteryIcon {
                            visible: BatteryService.hasBattery
                        }

                        OverlayButton {
                            icon: "game-mode"
                            toggled: GameModeService.active
                            filled: toggled
                            iconTransition: "wipe-left"
                            tip: Localization.t("gameOverlay.game_mode")
                            onClicked: GameModeService.toggle()
                        }

                        OverlayButton {
                            icon: "close"
                            tip: Localization.t("gameOverlay.close")
                            onClicked: GameOverlayService.close()
                        }
                    }
                }
            }
        }
    }
}
