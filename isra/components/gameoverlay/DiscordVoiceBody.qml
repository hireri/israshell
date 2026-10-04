pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.icons
import qs.services
import qs.style

Item {
    id: root

    readonly property string status: DiscordVoiceService.status
    readonly property string channel: DiscordVoiceService.channel
    readonly property var users: DiscordVoiceService.users

    readonly property string message: root.status === "authorize" ? Localization.t("gameOverlay.discord_authorize") : root.status === "error" ? Localization.t("gameOverlay.discord_error") + (DiscordVoiceService.detail !== "" ? ": " + DiscordVoiceService.detail : "") : root.status === "ok" ? (root.users.length === 0 ? Localization.t("gameOverlay.discord_no_channel") : "") : Localization.t("gameOverlay.discord_waiting")

    implicitWidth: 260
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 8

        Rectangle {
            visible: root.channel !== ""
            Layout.preferredWidth: Math.min(channelRow.implicitWidth + 16, root.width)
            Layout.preferredHeight: 22
            radius: 6
            color: Qt.alpha("black", 0.6)

            Row {
                id: channelRow
                anchors.centerIn: parent
                spacing: 5

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "volume-up"
                    iconSize: 14
                    color: "#c4c9ce"
                    transitionType: "none"
                }

                Text {
                    id: channelLabel
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, root.width - 16 - 19)
                    text: root.channel
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "#c4c9ce"
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
            }
        }

        Rectangle {
            visible: root.message !== ""
            Layout.preferredWidth: msg.implicitWidth + 16
            Layout.preferredHeight: msg.implicitHeight + 8
            radius: 6
            color: Qt.alpha("black", 0.6)

            Text {
                id: msg
                anchors.centerIn: parent
                width: Math.min(implicitWidth, root.width - 16)
                text: root.message
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: "white"
                wrapMode: Text.WordWrap
                renderType: Text.NativeRendering
            }
        }

        Repeater {
            model: root.users

            delegate: RowLayout {
                id: row
                required property var modelData

                Layout.fillWidth: true
                spacing: 8
                opacity: row.modelData.speaking ? 1 : 0.7

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: "transparent"
                    border.width: 2
                    border.color: row.modelData.speaking ? "#3ba55d" : "transparent"

                    ClippingRectangle {
                        anchors {
                            fill: parent
                            margins: 3
                        }
                        radius: width / 2
                        color: "#2b2d31"

                        Image {
                            anchors.fill: parent
                            source: row.modelData.avatar ? "https://cdn.discordapp.com/avatars/" + row.modelData.id + "/" + row.modelData.avatar + ".png?size=64" : ""
                            sourceSize.width: 64
                            asynchronous: true
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: label.implicitWidth + 16
                    Layout.preferredHeight: 24
                    radius: 6
                    color: Qt.alpha("black", 0.6)

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: row.modelData.name
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: "white"
                        renderType: Text.NativeRendering
                    }
                }

                MaterialIcon {
                    visible: row.modelData.mute
                    name: "mic"
                    iconSize: 16
                    color: "#f23f43"
                    transitionType: "none"
                }

                MaterialIcon {
                    visible: row.modelData.deaf
                    name: "headphones"
                    iconSize: 16
                    color: "#f23f43"
                    transitionType: "none"
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
