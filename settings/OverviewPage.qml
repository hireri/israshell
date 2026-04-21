pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services
import qs.settings.components
import qs.icons

PageBase {
    title: "Overview"
    subtitle: "Wallpaper and appearance"

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Item {
            Layout.preferredWidth: parent.width * 0.58
            Layout.preferredHeight: Layout.preferredWidth * 9 / 16
            Layout.alignment: Qt.AlignTop

            ClippingRectangle {
                anchors.fill: parent
                radius: 18
                color: Colors.md3.surface_container_high

                Image {
                    anchors.fill: parent
                    source: WallpaperService.currentWall !== "" ? "file://" + WallpaperService.currentWall : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready
                    sourceSize: Qt.size(840, 472)
                }

                Text {
                    anchors.centerIn: parent
                    text: "No wallpaper"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Colors.md3.outline
                    visible: WallpaperService.currentWall === ""
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: parent.children[0].Layout.preferredHeight
            Layout.alignment: Qt.AlignTop
            radius: 18
            color: Colors.md3.surface_container

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 14
                }
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    color: Colors.md3.primary
                    Text {
                        anchors.centerIn: parent
                        text: "Shuffle from folder"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.md3.on_primary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.randomize()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 17
                        bottomRightRadius: 8
                        topRightRadius: 8
                        color: Colors.md3.secondary_container
                        Text {
                            anchors.centerIn: parent
                            text: "Konachan"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Colors.md3.on_secondary_container
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.randomizeKonachan()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 17
                        bottomLeftRadius: 8
                        topLeftRadius: 8
                        color: Colors.md3.secondary_container
                        Text {
                            anchors.centerIn: parent
                            text: "Wallhaven"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Colors.md3.on_secondary_container
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.randomizeWallhaven()
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    SchemeButton {
                        Layout.fillWidth: true
                        label: "Dark"
                        dotColor: Colors.md3.background
                        active: WallpaperService.isDark
                        onClicked: WallpaperService.isDark = true
                    }
                    SchemeButton {
                        Layout.fillWidth: true
                        label: "Light"
                        dotColor: Colors.md3.inverse_surface
                        active: !WallpaperService.isDark
                        onClicked: WallpaperService.isDark = false
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
                Text {
                    Layout.fillWidth: true
                    text: WallpaperService.currentWall !== "" ? WallpaperService.currentWall.replace(Quickshell.env("HOME"), "~") : "No wallpaper set"
                    font.family: Config.fontMonospace
                    font.pixelSize: 10
                    color: Colors.md3.outline
                    elide: Text.ElideMiddle
                }
            }
        }
    }

    SectionCard {
        label: "Appearance"
        Layout.fillWidth: true

        SettingChips {
            label: "Clock format"
            options: [
                {
                    label: "24h",
                    value: 0
                },
                {
                    label: "12h",
                    value: 1
                }
            ]
            currentValue: Config.hourFormat
            onSelected: v => Config.update({
                    hourFormat: v
                })
        }

        SettingSwitch {
            label: "Screen corners"
            sublabel: "Rounded corner overlay"
            checked: Config.screenCorners
            onToggled: v => Config.update({
                    screenCorners: v
                })
        }

        SettingSwitch {
            label: "Desktop clock"
            sublabel: "Clock widget on wallpaper"
            checked: Config.desktopClock
            onToggled: v => Config.update({
                    desktopClock: v
                })
        }

        SettingRow {
            id: editRow
            isLast: true
            label: "Edit config.json"
            sublabel: "Open in default editor"

            Text {
                text: "󰬪"
                font.pixelSize: 18
                color: editMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.outline
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            MouseArea {
                id: editMouse
                parent: editRow
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: Qt.openUrlExternally("file://" + Quickshell.env("HOME") + "/.config/quickshell/config.json")
            }
        }
    }
}
