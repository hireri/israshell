import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import qs.style

Scope {
    id: root
    property int fontSize: 24

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
    property real normalBarPercent: Math.min(volumePercent, 100)
    property real errorBarPercent: isOverLimit ? Math.min((volumePercent - 100) / 50 * 100, 100) : 0

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height / 5
            exclusiveZone: 0

            implicitWidth: 400
            implicitHeight: 56
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Colors.md3.surface_container
                border.width: 1
                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 20
                        rightMargin: 24
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 16

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: volumeIconText
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

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: Colors.md3.surface_variant
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * (root.normalBarPercent / 100)
                            radius: 4
                            color: root.isMuted ? Colors.md3.outline : Colors.md3.primary
                            clip: true

                            Behavior on width {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            x: parent.width * (100 / 150)
                            width: parent.width * (root.errorBarPercent / 100)
                            radius: 4
                            color: root.isMuted ? Colors.md3.on_surface_variant : Colors.md3.error
                            visible: root.errorBarPercent > 0
                            clip: true

                            Behavior on width {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: parent.height
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            text: Math.round(root.volumePercent) + "%"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: root.isMuted ? Colors.md3.on_surface_variant : (root.isOverLimit ? Colors.md3.error : Colors.md3.on_surface)
                        }
                    }
                }
            }
        }
    }
}
