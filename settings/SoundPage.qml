pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.style
import qs.icons
import qs.services
import qs.settings.components

PageBase {
    title: "Sound & Notifications"
    subtitle: "Audio output and interruption settings"

    SectionCard {
        label: "Output"
        Layout.fillWidth: true

        Rectangle {
            height: 6
            width: 1
            color: "transparent"
        }

        Repeater {
            id: outputRepeater
            model: AudioService.nodes.filter(n => n.audio && !n.isStream && n.isSink)

            delegate: Item {
                required property var modelData
                required property int index

                readonly property bool active: AudioService.isDefaultSink(modelData)

                implicitWidth: parent?.width ?? 0
                implicitHeight: 52

                Rectangle {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                        topMargin: 4
                        bottomMargin: 4
                    }
                    radius: 14
                    color: active ? Colors.md3.primary_container : Colors.md3.surface_container_high
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 14
                        }
                        spacing: 12

                        Text {
                            text: "󰕾"
                            font.pixelSize: 16
                            font.family: Config.fontMonospace
                            color: active ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                        }

                        Text {
                            text: AudioService.deviceName(modelData)
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: active ? Font.Medium : Font.Normal
                            color: active ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "󰄬"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Colors.md3.on_primary_container
                            visible: active
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: active ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !active
                        onClicked: AudioService.setDefaultSink(modelData)
                    }
                }
            }
        }

        Item {
            implicitWidth: parent?.width ?? 0
            implicitHeight: 48

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 12

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: AudioService.muted ? Colors.md3.error_container : Colors.md3.surface_container_high

                    Text {
                        anchors.centerIn: parent
                        text: AudioService.muted ? "󰖁" : "󰕾"
                        font.pixelSize: 15
                        font.family: Config.fontMonospace
                        color: AudioService.muted ? Colors.md3.on_error_container : Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AudioService.toggleMute()
                    }
                }

                Slider {
                    id: outSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 1.5
                    stepSize: 0.01
                    value: AudioService.volume
                    onMoved: AudioService.setVolume(value)

                    background: Rectangle {
                        x: outSlider.leftPadding
                        y: outSlider.topPadding + outSlider.availableHeight / 2 - height / 2
                        width: outSlider.availableWidth
                        height: 3
                        radius: 2
                        color: Colors.md3.surface_variant
                        Rectangle {
                            width: outSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 2
                            color: Colors.md3.primary
                        }
                    }
                    handle: Rectangle {
                        x: outSlider.leftPadding + outSlider.visualPosition * outSlider.availableWidth - width / 2
                        y: outSlider.topPadding + outSlider.availableHeight / 2 - height / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: Colors.md3.primary
                        border.width: 2
                        border.color: Colors.md3.surface
                    }
                }

                Text {
                    text: Math.round(AudioService.volume * 100) + "%"
                    font.family: Config.fontMonospace
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        Rectangle {
            height: 4
            width: 1
            color: "transparent"
        }
    }

    SectionCard {
        label: "Apps"
        Layout.fillWidth: true

        Repeater {
            id: streamRepeater
            model: AudioService.nodes.filter(n => n.audio && n.isStream && n.isSink)

            delegate: Item {
                required property var modelData
                required property int index

                PwObjectTracker {
                    objects: [modelData]
                }

                readonly property string appName: AudioService.appNodeDisplayName(modelData)
                readonly property string mediaName: modelData.properties["media.name"] ?? ""

                readonly property string iconCandidate: AudioService.streamIconName(modelData)
                implicitWidth: parent?.width ?? 0
                implicitHeight: 56

                function resolveIcon(source) {
                    if (!source || source === "")
                        return "";
                    if (source.startsWith("/") || source.includes("://"))
                        return source;
                    return Quickshell.iconPath(source);
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }
                    spacing: 12

                    Item {
                        width: 28
                        height: 28
                        Layout.alignment: Qt.AlignVCenter

                        IconImage {
                            id: appIcon
                            anchors.fill: parent
                            source: resolveIcon(iconCandidate)
                            visible: source !== "" && status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Colors.md3.surface_container_high
                            visible: !appIcon.visible

                            Text {
                                anchors.centerIn: parent
                                text: "󰝚"
                                font.pixelSize: 15
                                font.family: Config.fontMonospace
                                color: Colors.md3.on_surface_variant
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 96
                        Layout.maximumWidth: 96
                        spacing: 2

                        Text {
                            text: appName
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            color: Colors.md3.on_surface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: mediaName
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: Colors.md3.outline
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: mediaName.length > 0
                        }
                    }

                    Slider {
                        id: streamSlider
                        Layout.fillWidth: true
                        Layout.minimumWidth: 80
                        from: 0
                        to: 1.5
                        stepSize: 0.01

                        value: modelData.audio?.volume ?? 0
                        onMoved: {
                            if (modelData.audio)
                                modelData.audio.volume = value;
                        }

                        background: Rectangle {
                            x: streamSlider.leftPadding
                            y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                            width: streamSlider.availableWidth
                            height: 3
                            radius: 2
                            color: Colors.md3.surface_variant
                            Rectangle {
                                width: streamSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: Colors.md3.secondary
                            }
                        }
                        handle: Rectangle {
                            x: streamSlider.leftPadding + streamSlider.visualPosition * streamSlider.availableWidth - width / 2
                            y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: Colors.md3.secondary
                            border.width: 2
                            border.color: Colors.md3.surface
                        }
                    }

                    Text {
                        text: Math.round((modelData.audio?.volume ?? 0) * 100) + "%"
                        font.family: Config.fontMonospace
                        font.pixelSize: 11
                        color: Colors.md3.outline
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Rectangle {
                    visible: index < streamRepeater.count - 1
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        leftMargin: 18
                        right: parent.right
                        rightMargin: 18
                    }
                    height: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.5
                }
            }
        }
    }

    SectionCard {
        label: "Notifications"
        Layout.fillWidth: true

        SettingSelect {
            label: "Popup timeout"
            sublabel: "How long popups stay visible"
            iconBg: Colors.md3.secondary_container
            options: [
                {
                    label: "3 seconds",
                    value: 3000
                },
                {
                    label: "5 seconds",
                    value: 5000
                },
                {
                    label: "8 seconds",
                    value: 8000
                },
                {
                    label: "Never",
                    value: 0
                }
            ]
            currentValue: Config.notificationTimeout ?? 5000
            onSelected: v => Config.update({
                    notificationTimeout: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Show on all monitors"
            sublabel: "Mirror popups across every screen"
            iconBg: Colors.md3.secondary_container
            checked: Config.notificationsAllMonitors ?? false
            onToggled: v => Config.update({
                    notificationsAllMonitors: v
                })
        }
    }
}
