pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.settings.components

PageBase {
    title: "Bar"
    subtitle: "Layout, media and tray"

    SectionCard {
        label: "Layout"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Hugging bar"
            sublabel: "Attach bar to screen edge"
            checked: Config.huggingBar
            onToggled: v => Config.update({
                    huggingBar: v,
                    floatingBar: v ? false : Config.floatingBar
                })
        }

        SettingSwitch {
            label: "Floating bar"
            sublabel: "Detach from screen edge"
            checked: Config.floatingBar
            onToggled: v => Config.update({
                    floatingBar: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Transparent bar"
            sublabel: "Remove bar background"
            checked: Config.transparentBar
            onToggled: v => Config.update({
                    transparentBar: v
                })
        }
    }

    SectionCard {
        label: "Media player"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Spinning cover"
            sublabel: "Rotate album art while playing"
            checked: Config.spinningCover
            onToggled: v => Config.update({
                    spinningCover: v
                })
        }

        SettingSlider {
            isLast: true
            label: "Scroll speed"
            sublabel: "Media title carousel"
            from: 10
            to: 100
            stepSize: 5
            unit: ""
            value: Config.carouselSpeed
            onMoved: v => Config.update({
                    carouselSpeed: v
                })
        }
    }

    SectionCard {
        label: "OSD"
        Layout.fillWidth: true

        SettingChips {
            isLast: true
            label: "Position"
            options: [
                {
                    label: "Center",
                    value: 0
                },
                {
                    label: "Top",
                    value: 1
                },
                {
                    label: "Bottom",
                    value: 3
                },
                {
                    label: "Left",
                    value: 4
                },
                {
                    label: "Right",
                    value: 2
                }
            ]
            currentValue: Config.osdPosition
            onSelected: v => Config.update({
                    osdPosition: v
                })
        }
    }

    SectionCard {
        label: "Tray"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Icon tint"
            sublabel: "Colorize tray icons with primary color"
            checked: Config.tintTrayIcons
            onToggled: v => Config.update({
                    tintTrayIcons: v
                })
        }

        SettingRow {
            isLast: true
            label: "Blacklist"
            sublabel: "Hidden from tray"

            Flow {
                width: 220
                spacing: 6

                Repeater {
                    model: Config.trayBlacklist

                    ToolChip {
                        required property string modelData
                        label: modelData
                        active: true
                        onToggled: _ => {
                            const updated = Config.trayBlacklist.filter(x => x !== modelData);
                            Config.update({
                                trayBlacklist: updated
                            });
                        }
                    }
                }

                Rectangle {
                    implicitHeight: 32
                    implicitWidth: addLabel.implicitWidth + 24
                    radius: height / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Colors.md3.outline_variant

                    Text {
                        id: addLabel
                        anchors.centerIn: parent
                        text: "+ Add"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addDialog.open()
                    }
                }
            }
        }
    }

    Rectangle {
        id: addDialog
        visible: false
        Layout.fillWidth: true
        implicitHeight: addRow.implicitHeight + 24
        radius: 14
        color: Colors.md3.surface_container_high
        border.width: 1
        border.color: Colors.md3.outline_variant

        function open() {
            visible = true;
            addField.forceActiveFocus();
        }
        function close() {
            visible = false;
            addField.text = "";
        }

        RowLayout {
            id: addRow
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            TextField {
                id: addField
                Layout.fillWidth: true
                placeholderText: "App name…"
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.on_surface
                placeholderTextColor: Colors.md3.outline
                leftPadding: 12
                rightPadding: 12
                implicitHeight: 36

                background: Rectangle {
                    radius: 8
                    color: Colors.md3.surface_container
                    border.width: addField.activeFocus ? 1.5 : 1
                    border.color: addField.activeFocus ? Colors.md3.primary : Colors.md3.surface_variant
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                Keys.onReturnPressed: confirmBtn.clicked()
                Keys.onEscapePressed: addDialog.close()
            }

            Rectangle {
                id: confirmBtn
                implicitHeight: 36
                implicitWidth: confirmLbl.implicitWidth + 20
                radius: 8
                color: Colors.md3.primary
                signal clicked

                onClicked: {
                    const val = addField.text.trim();
                    if (val.length > 0 && !Config.trayBlacklist.includes(val))
                        Config.update({
                            trayBlacklist: [...Config.trayBlacklist, val]
                        });
                    addDialog.close();
                }

                Text {
                    id: confirmLbl
                    anchors.centerIn: parent
                    text: "Add"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Colors.md3.on_primary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: confirmBtn.clicked()
                }
            }

            Rectangle {
                implicitHeight: 36
                implicitWidth: 36
                radius: 8
                color: Colors.md3.surface_container

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 13
                    color: Colors.md3.outline
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: addDialog.close()
                }
            }
        }
    }
}
