import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import qs.style

Scope {
    id: root
    property int fontSize: 24

    property bool isVertical: Config.osdPosition === 2 || Config.osdPosition === 4

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
            root.showOsd();
        }
        function onMutedChanged() {
            root.showOsd();
        }
    }

    property bool shouldShowOsd: false

    function showOsd() {
        root.shouldShowOsd = true;
        hideTimer.restart();
    }

    property bool isMuted: Pipewire.defaultAudioSink?.audio.muted ?? false
    property real rawVolume: Pipewire.defaultAudioSink?.audio.volume ?? 0

    property string volumeIcon: {
        if (root.isOverLimit)
            return "󱄡";
        if (root.isMuted || root.rawVolume === 0)
            return "󰖁";
        if (root.rawVolume < 0.33)
            return "󰕿";
        if (root.rawVolume < 0.66)
            return "󰖀";
        return "󰕾";
    }

    property real volumePercent: root.rawVolume * 100
    property bool isOverLimit: volumePercent > 100
    property real trackFill: Math.min(volumePercent / 150, 1.0)

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            anchors.top: Config.osdPosition === 1
            anchors.right: Config.osdPosition === 2
            anchors.bottom: Config.osdPosition === 3
            anchors.left: Config.osdPosition === 4

            margins.top: Config.osdPosition === 1 ? 24 : 0
            margins.right: Config.osdPosition === 2 ? 24 : 0
            margins.bottom: Config.osdPosition === 3 ? 24 : 0
            margins.left: Config.osdPosition === 4 ? 24 : 0

            exclusiveZone: 0

            implicitWidth: root.isVertical ? 48 : 280
            implicitHeight: root.isVertical ? 280 : 48
            color: "transparent"

            Rectangle {
                id: osdRect
                anchors.fill: parent
                radius: root.isVertical ? width / 2 : height / 2
                color: Colors.md3.surface_container
                border.width: 1
                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)
                clip: true

                property real slideOffset: {
                    switch (Config.osdPosition) {
                    case 1:
                        return -(parent.height + 24);
                    case 2:
                        return parent.width + 24;
                    case 3:
                        return parent.height + 24;
                    case 4:
                        return -(parent.width + 24);
                    }
                    return 0;
                }

                transform: Translate {
                    x: (Config.osdPosition === 2 || Config.osdPosition === 4) ? osdRect.slideOffset : 0
                    y: (Config.osdPosition === 1 || Config.osdPosition === 3) ? osdRect.slideOffset : 0
                }

                Component.onCompleted: slideAnim.start()

                NumberAnimation {
                    id: slideAnim
                    target: osdRect
                    property: "slideOffset"
                    to: 0
                    duration: 220
                    easing.type: Easing.OutExpo
                }

                ColumnLayout {
                    visible: root.isVertical
                    anchors {
                        fill: parent
                        topMargin: 16
                        bottomMargin: 10
                    }
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 20
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(root.volumePercent)
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.isMuted ? Colors.md3.on_surface_variant : (root.isOverLimit ? Colors.md3.error : Colors.md3.on_surface)
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.preferredWidth: 8

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: Colors.md3.surface_variant
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: parent.height * root.trackFill
                            radius: 4
                            color: root.isMuted ? Colors.md3.outline : (root.isOverLimit ? Colors.md3.error : Colors.md3.primary)
                            Behavior on height {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            y: parent.height * (1 - 100 / 150) - height / 2
                            height: 2
                            color: root.isOverLimit ? Colors.md3.error : Qt.alpha(Colors.md3.outline_variant, 0.6)
                        }
                    }

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            anchors.centerIn: parent
                            text: root.volumeIcon
                            font.family: Config.fontFamily
                            font.pixelSize: root.fontSize
                            color: Colors.md3.on_surface_variant
                        }
                    }
                }

                RowLayout {
                    visible: !root.isVertical
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 10
                    }
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: root.volumeIcon
                            font.family: Config.fontFamily
                            font.pixelSize: root.fontSize
                            color: Colors.md3.on_surface_variant
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: Colors.md3.surface_variant
                        }

                        Rectangle {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                            }
                            width: parent.width * root.trackFill
                            radius: 4
                            color: root.isMuted ? Colors.md3.outline : (root.isOverLimit ? Colors.md3.error : Colors.md3.primary)
                            Behavior on width {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        Rectangle {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                            }
                            x: parent.width * (100 / 150) - width / 2
                            width: 2
                            color: root.isOverLimit ? Colors.md3.error : Qt.alpha(Colors.md3.outline_variant, 0.6)
                        }
                    }

                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 20
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(root.volumePercent)
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.isMuted ? Colors.md3.on_surface_variant : (root.isOverLimit ? Colors.md3.error : Colors.md3.on_surface)
                        }
                    }
                }
            }
        }
    }
}
