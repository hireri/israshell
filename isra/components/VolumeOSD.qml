import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import qs.icons
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

    property bool isMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false
    
    property real rawVolume: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0
    property real volumePercent: root.rawVolume * 100
    property bool isOverLimit: volumePercent > 100

    property real animatedVolume: root.rawVolume
    Behavior on animatedVolume {
        enabled: root.shouldShowOsd
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    property real animatedVolumePercent: root.animatedVolume * 100
    property real fillFraction: Math.min(animatedVolumePercent / 100, 1)
    property real errorFraction: Math.max(Math.min((animatedVolumePercent - 100) / 50, 1), 0)

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            anchors.top: Config.osdPosition === 0 || Config.osdPosition === 1
            anchors.right: Config.osdPosition === 2
            anchors.bottom: Config.osdPosition === 3
            anchors.left: Config.osdPosition === 4

            margins.top: {
                if (Config.osdPosition === 0) {
                    return screen.height * 0.57;
                }
                return Config.osdPosition === 1 ? 24 : 0;
            }
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

                    OsdTrackBar {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.preferredWidth: 8

                        vertical: true
                        fillFraction: root.fillFraction
                        errorFraction: root.errorFraction
                        fillColor: root.isMuted ? Colors.md3.outline : Colors.md3.primary
                        trackColor: Colors.md3.surface_variant
                        errorColor: Colors.md3.error
                    }

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignHCenter

                        VolumeIcon {
                            anchors.centerIn: parent
                            muted: root.isMuted
                            volume: Math.round(root.volumePercent)
                            color: Colors.md3.on_surface_variant
                            iconSize: root.fontSize
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

                        VolumeIcon {
                            anchors.centerIn: parent
                            muted: root.isMuted
                            volume: Math.round(root.volumePercent)
                            color: Colors.md3.on_surface_variant
                            iconSize: root.fontSize
                        }
                    }

                    OsdTrackBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        Layout.alignment: Qt.AlignVCenter

                        vertical: false
                        fillFraction: root.fillFraction
                        errorFraction: root.errorFraction
                        fillColor: root.isMuted ? Colors.md3.outline : Colors.md3.primary
                        trackColor: Colors.md3.surface_variant
                        errorColor: Colors.md3.error
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

    component OsdTrackBar: Item {
        id: bar

        property bool vertical: false
        property real fillFraction: 0
        property real errorFraction: 0

        property color fillColor: Colors.md3.primary
        property color trackColor: Colors.md3.surface_variant
        property color errorColor: Colors.md3.error

        property real gap: 4

        readonly property real thickness: vertical ? width : height
        readonly property real total: vertical ? height : width

        readonly property real errorLen: errorFraction * total
        readonly property real errorGap: errorLen > 0.5 ? gap : 0
        readonly property real fillLen: Math.max(fillFraction * total - errorLen, 0)
        readonly property real fillGap: fillLen > 0.5 ? gap : 0
        readonly property real trackLen: Math.max(total - errorLen - errorGap - fillLen - fillGap, 0)

        Rectangle {
            visible: bar.errorLen > 0.5
            color: bar.errorColor
            radius: bar.thickness / 2

            x: 0
            y: bar.vertical ? bar.total - bar.errorLen : 0
            width: bar.vertical ? bar.thickness : bar.errorLen
            height: bar.vertical ? bar.errorLen : bar.thickness
        }

        Rectangle {
            visible: bar.fillLen > 0.5
            color: bar.fillColor
            radius: bar.thickness / 2

            x: bar.vertical ? 0 : bar.errorLen + bar.errorGap
            y: bar.vertical ? bar.total - bar.errorLen - bar.errorGap - bar.fillLen : 0
            width: bar.vertical ? bar.thickness : bar.fillLen
            height: bar.vertical ? bar.fillLen : bar.thickness
        }

        Rectangle {
            visible: bar.trackLen > 0.5
            color: bar.trackColor
            radius: bar.thickness / 2

            x: bar.vertical ? 0 : bar.errorLen + bar.errorGap + bar.fillLen + bar.fillGap
            y: 0
            width: bar.vertical ? bar.thickness : bar.trackLen
            height: bar.vertical ? bar.trackLen : bar.thickness
        }
    }
}