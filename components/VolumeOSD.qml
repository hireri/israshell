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

    property string volumeIcon: {
        let sink = Pipewire.defaultAudioSink;
        if (!sink || sink.audio.muted || sink.audio.volume === 0)
            return "󰖁";
        if (sink.audio.volume < 0.33)
            return "󰕿";
        if (sink.audio.volume < 0.66)
            return "󰖀";
        return "󰕾";
    }

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
                border.color: Colors.md3.outline_variant

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 20
                        rightMargin: 24
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 16

                    Text {
                        id: volumeIconText
                        text: root.volumeIcon
                        font.family: Config.fontFamily
                        font.pixelSize: root.fontSize
                        color: Colors.md3.primary
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on text {
                            NumberAnimation {
                                target: volumeIconText
                                property: "scale"
                                from: 0.8
                                to: 1.0
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Colors.md3.outline_variant

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
                            radius: parent.radius
                            color: Colors.md3.primary

                            Behavior on width {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    Text {
                        text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface
                        Layout.alignment: Qt.AlignVCenter
                        Layout.minimumWidth: 28
                    }
                }
            }
        }
    }
}
