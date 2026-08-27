pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property string text: ""
    property bool isError: false
    property real maxWidth: 600

    implicitWidth: isError ? errorCard.implicitWidth : markdown.width
    implicitHeight: isError ? errorCard.implicitHeight : markdown.height

    MarkdownView {
        id: markdown
        visible: !root.isError
        text: root.text
        maxWidth: root.maxWidth
        textColor: Colors.md3.on_surface
        fontSize: 15

        layer.enabled: markdown.visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.5
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 2
            shadowColor: Qt.alpha(Colors.md3.background, 0.95)
        }
    }

    Rectangle {
        id: errorCard
        visible: root.isError

        readonly property real textLimit: root.maxWidth - 28

        implicitWidth: Math.min(Math.max(errorText.width, retryBtn.visible ? retryBtn.width : 0) + 28, root.maxWidth)
        implicitHeight: errorText.height + (retryBtn.visible ? retryBtn.height + 10 : 0) + 24

        radius: 14
        color: Qt.alpha(Colors.md3.error_container, Config.blurOpacity)
        border.width: 1
        border.color: Qt.alpha(Colors.md3.error, 0.4)

        Text {
            id: errorText
            x: 14
            y: 12
            width: Math.min(implicitWidth, errorCard.textLimit)
            text: root.text
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Colors.md3.on_error_container
            font.pixelSize: 14
            font.family: Config.fontFamily
            lineHeight: 1.3
        }

        Rectangle {
            id: retryBtn
            visible: AiAssistantService.canRetry
            x: 14
            y: errorText.y + errorText.height + 10
            width: retryRow.implicitWidth + 20
            height: 26
            radius: height / 2
            color: retryMa.containsMouse ? Colors.md3.error : "transparent"
            border.width: 1
            border.color: Qt.alpha(Colors.md3.error, 0.5)

            readonly property color contentColor: retryMa.containsMouse ? Colors.md3.on_error : Colors.md3.on_error_container

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Row {
                id: retryRow
                anchors.centerIn: parent
                spacing: 5

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "restart"
                    iconSize: 13
                    transitionType: "none"
                    color: retryBtn.contentColor
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Localization.t("aiAssistant.retry")
                    color: retryBtn.contentColor
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                }
            }

            MouseArea {
                id: retryMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AiAssistantService.retry()
            }
        }
    }
}
