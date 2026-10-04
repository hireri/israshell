pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.services
import qs.style
import qs.windows.components

Item {
    id: root

    implicitWidth: 340
    implicitHeight: Math.min(column.implicitHeight, 460)

    component Heading: Text {
        topPadding: 4
        bottomPadding: 2
        font.family: Config.fontFamily
        font.pixelSize: 10
        font.weight: Font.Medium
        font.letterSpacing: 0.7
        color: Colors.md3.primary
    }

    Flickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 0

            Heading {
                text: Localization.t("soundPage.output")
            }

            AudioDeviceList {
                Layout.fillWidth: true
                sink: true
                inset: 0
            }

            VolumeRow {
                Layout.fillWidth: true
                leftInset: 0
                rightInset: 0
                muted: AudioService.muted
                volume: AudioService.volume
                onMuteToggled: AudioService.toggleMute()
                onVolumeMoved: v => AudioService.setVolume(v)
            }

            Heading {
                text: Localization.t("soundPage.input")
            }

            AudioDeviceList {
                Layout.fillWidth: true
                sink: false
                inset: 0
            }

            VolumeRow {
                Layout.fillWidth: true
                leftInset: 0
                rightInset: 0
                glyph: "󰍬"
                mutedGlyph: "󰍭"
                muted: AudioService.sourceMuted
                volume: AudioService.sourceVolume
                onMuteToggled: AudioService.toggleSourceMute()
                onVolumeMoved: v => AudioService.setSourceVolume(v)
            }

            Heading {
                visible: streams.count > 0
                text: Localization.t("soundPage.apps")
            }

            Repeater {
                id: streams
                model: AudioService.nodes.filter(n => n.audio && n.isStream && n.isSink && n.name !== "quickshell")

                delegate: VolumeRow {
                    id: stream
                    required property var modelData

                    Layout.fillWidth: true
                    leftInset: 0
                    rightInset: 0
                    rowHeight: 56
                    buttonSize: 32
                    mutedGlyph: "󰸈"
                    accent: Colors.md3.secondary
                    label: AudioService.appNodeDisplayName(modelData)
                    sublabel: modelData.properties["media.name"] ?? ""
                    muted: modelData.audio?.muted ?? false
                    volume: modelData.audio?.volume ?? 0
                    onMuteToggled: {
                        if (modelData.audio)
                            modelData.audio.muted = !modelData.audio.muted;
                    }
                    onVolumeMoved: v => {
                        if (modelData.audio)
                            modelData.audio.volume = v;
                    }

                    PwObjectTracker {
                        objects: [stream.modelData]
                    }
                }
            }
        }
    }
}
