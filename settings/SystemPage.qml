import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.style
import qs.services
import qs.settings.components

PageBase {
    title: "System"
    subtitle: "About and script paths"

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 40
        radius: 20
        color: Colors.md3.primary_container

        ColumnLayout {
            id: cardCol
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 20
                rightMargin: 20
            }
            spacing: 14

            RowLayout {
                spacing: 14

                Rectangle {
                    width: 52
                    height: 52
                    radius: 16
                    color: Qt.alpha(Colors.md3.on_primary_container, 0.12)
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        source: Quickshell.iconPath(SystemInfo.logo)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    Text {
                        text: SystemInfo.hostname
                        font.family: Config.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.SemiBold
                        font.letterSpacing: -0.3
                        color: Colors.md3.on_primary_container
                    }

                    Text {
                        text: SystemInfo.username + " · " + SystemInfo.distroName
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Colors.md3.on_primary_container
                        opacity: 0.7
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    implicitHeight: 26
                    implicitWidth: shellLbl.implicitWidth + 18
                    radius: 13
                    color: Colors.md3.primary

                    Text {
                        id: shellLbl
                        anchors.centerIn: parent
                        text: "israshell v0.5.1"
                        font.family: Config.fontMonospace
                        font.pixelSize: 11
                        color: Colors.md3.on_primary
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitHeight: 26
                    implicitWidth: ghLbl.implicitWidth + 18
                    radius: 13
                    color: Colors.md3.primary

                    Text {
                        id: ghLbl
                        anchors.centerIn: parent
                        text: "GitHub ↗"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.on_primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://github.com/hireri/israshell")
                    }
                }
            }
        }
    }

    SectionCard {
        label: "Script paths"
        Layout.fillWidth: true

        SettingInput {
            label: "Screenshot"
            sublabel: "Capture script"
            iconBg: Colors.md3.secondary_container
            value: Config.screencap.screenshotPath
            fieldWidth: 220
            onCommitted: v => Config.update({
                    screencap: Object.assign({}, Config.screencap, {
                        screenshotPath: v
                    })
                })
        }

        SettingInput {
            label: "Screen record"
            sublabel: "Recording script"
            iconBg: Colors.md3.secondary_container
            value: Config.screencap.recordPath
            fieldWidth: 220
            onCommitted: v => Config.update({
                    screencap: Object.assign({}, Config.screencap, {
                        recordPath: v
                    })
                })
        }

        SettingInput {
            label: "CTS"
            sublabel: "Click-to-search"
            iconBg: Colors.md3.secondary_container
            value: Config.screencap.ctsPath ?? ""
            fieldWidth: 220
            onCommitted: v => Config.update({
                    screencap: Object.assign({}, Config.screencap, {
                        ctsPath: v
                    })
                })
        }

        SettingInput {
            label: "OCR"
            sublabel: "Text recognition"
            iconBg: Colors.md3.secondary_container
            value: Config.screencap.ocrPath ?? ""
            fieldWidth: 220
            onCommitted: v => Config.update({
                    screencap: Object.assign({}, Config.screencap, {
                        ocrPath: v
                    })
                })
        }

        SettingInput {
            isLast: true
            label: "Songrec"
            sublabel: "Song recognition"
            iconBg: Colors.md3.secondary_container
            value: Config.screencap.songrecPath ?? ""
            fieldWidth: 220
            onCommitted: v => Config.update({
                    screencap: Object.assign({}, Config.screencap, {
                        songrecPath: v
                    })
                })
        }
    }
}
