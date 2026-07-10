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
import qs.windows.components

PageBase {
    title: "Sound & Notifications"
    subtitle: "Audio output and interruption settings"

    Component.onCompleted: AudioService.startMicMeter()
    Component.onDestruction: AudioService.stopMicMeter()

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
                    leftMargin: 10
                    rightMargin: 16
                }
                spacing: 12

                Rectangle {
                    id: outMuteBtn
                    width: 38
                    height: 38
                    radius: AudioService.muted ? width / 2 : 12
                    color: AudioService.muted ? Colors.md3.error_container : Colors.md3.surface_container_high
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on radius {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: AudioService.muted ? "󰖁" : "󰕾"
                        font.pixelSize: 16
                        font.family: Config.fontMonospace
                        color: AudioService.muted ? Colors.md3.on_error_container : Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        id: outMuteArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AudioService.toggleMute()
                    }
                }

                TrackSlider {
                    id: outSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 1.5
                    stepSize: 0.01
                    value: AudioService.volume
                    onMoved: AudioService.setVolume(value)
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
        label: "Input"
        Layout.fillWidth: true

        Rectangle {
            height: 6
            width: 1
            color: "transparent"
        }

        Repeater {
            id: inputRepeater
            model: AudioService.nodes.filter(n => n.audio && !n.isStream && !n.isSink)

            delegate: Item {
                required property var modelData
                required property int index

                readonly property bool active: AudioService.isDefaultSource(modelData)

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
                            text: "󰍬"
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
                        onClicked: AudioService.setDefaultSource(modelData)
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
                    leftMargin: 10
                    rightMargin: 16
                }
                spacing: 12

                Rectangle {
                    id: inMuteBtn
                    width: 38
                    height: 38
                    radius: AudioService.sourceMuted ? width / 2 : 12
                    color: AudioService.sourceMuted ? Colors.md3.error_container : Colors.md3.surface_container_high
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on radius {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: AudioService.sourceMuted ? "󰍭" : "󰍬"
                        font.pixelSize: 16
                        font.family: Config.fontMonospace
                        color: AudioService.sourceMuted ? Colors.md3.on_error_container : Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        id: inMuteArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AudioService.toggleSourceMute()
                    }
                }

                TrackSlider {
                    id: inSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 1.5
                    stepSize: 0.01
                    value: AudioService.sourceVolume
                    onMoved: AudioService.setSourceVolume(value)
                }

                Text {
                    text: Math.round(AudioService.sourceVolume * 100) + "%"
                    font.family: Config.fontMonospace
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        Item {
            implicitWidth: parent?.width ?? 0
            implicitHeight: 10

            Item {
                id: micTrack
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                    rightMargin: 12
                }
                height: 6

                property real gap: 4
                property real level: AudioService.micLevel
                property real effectiveGap: (level <= 0 || level >= 1) ? 0 : gap
                property real fillW: Math.max(0, width * level - effectiveGap)
                property color fillColor: {
                    if (AudioService.sourceMuted)
                        return Colors.md3.outline;
                    if (AudioService.micLevel > 0.85)
                        return Colors.md3.error;
                    if (AudioService.micLevel > 0.6)
                        return Colors.md3.tertiary;
                    return Colors.md3.primary;
                }

                Behavior on fillW {
                    NumberAnimation {
                        duration: 10
                    }
                }
                Behavior on fillColor {
                    ColorAnimation {
                        duration: 5
                    }
                }

                Rectangle {
                    id: micBarLeft
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    width: micTrack.fillW
                    height: micTrack.height
                    radius: height / 2
                    color: micTrack.fillColor
                }

                Rectangle {
                    anchors {
                        left: micBarLeft.right
                        leftMargin: micTrack.effectiveGap
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: micTrack.height
                    radius: height / 2
                    color: Colors.md3.surface_variant
                }
            }
        }

        Rectangle {
            height: 12
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
                readonly property bool streamMuted: modelData.audio?.muted ?? false

                implicitWidth: parent?.width ?? 0
                implicitHeight: 56

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 16
                    }
                    spacing: 12

                    Rectangle {
                        id: appMuteBtn
                        width: 32
                        height: 32
                        radius: 10
                        Layout.alignment: Qt.AlignVCenter
                        color: streamMuted ? Colors.md3.error_container : Colors.md3.surface_container_high
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: streamMuted ? "󰸈" : "󰕾"
                            font.pixelSize: 16
                            font.family: Config.fontMonospace
                            color: streamMuted ? Colors.md3.on_error_container : Colors.md3.on_surface_variant
                        }

                        MouseArea {
                            id: appMuteArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.audio)
                                    modelData.audio.muted = !modelData.audio.muted;
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

                    TrackSlider {
                        id: streamSlider
                        Layout.fillWidth: true
                        Layout.minimumWidth: 80
                        from: 0
                        to: 1.5
                        stepSize: 0.01
                        fillColor: Colors.md3.secondary

                        value: modelData.audio?.volume ?? 0
                        onMoved: {
                            if (modelData.audio)
                                modelData.audio.volume = value;
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

        SettingSwitch {
            isLast: true
            label: "Show on all monitors"
            sublabel: "Mirror popups across every screen"
            iconBg: Colors.md3.secondary_container
            checked: Config.notifications.showAllMonitors ?? false
            onToggled: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        showAllMonitors: v
                    })
                })
        }
        SettingSelect {
            label: "Popup timeout"
            sublabel: "How long popups stay visible"
            iconBg: Colors.md3.secondary_container
            options: [
                {
                    label: "3 seconds",
                    value: 3
                },
                {
                    label: "5 seconds",
                    value: 5
                },
                {
                    label: "8 seconds",
                    value: 8
                },
                {
                    label: "Never",
                    value: 0
                }
            ]
            currentValue: Config.notifications.popupTimeout ?? 5
            onSelected: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        popupTimeout: v
                    })
                })
        }
        SettingChips {
            label: "Position"
            options: [
                {
                    label: "Follow Bar",
                    value: 0
                },
                {
                    label: "Always Top",
                    value: 1
                },
                {
                    label: "Always Bottom",
                    value: 2
                }
            ]
            currentValue: Config.notifications.popupPosition ?? 0
            onSelected: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        popupPosition: v
                    })
                })
        }
    }
}
