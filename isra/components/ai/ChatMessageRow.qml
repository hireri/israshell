pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    required property var entry
    required property string username
    required property string modelDisplayName
    required property string modelShapeName

    property bool canRegenerate: false

    readonly property bool isUser: entry.role === "user"
    readonly property bool isError: entry.isError === true
    readonly property string messageText: entry.text ?? ""
    readonly property real avatarSize: 30
    readonly property real maxContentWidth: width * 0.86
    readonly property real contentMaxWidth: maxContentWidth - avatarSize - 10
    readonly property alias bubbleItem: bubble

    signal bubbleShown(item: var)
    signal bubbleHidden(item: var)

    height: rowLayout.height
    opacity: 1

    HoverHandler {
        id: rowHover
    }

    function _playEntrance(): void {
        if (root.entry._skipEntranceAnim === true || root.entry._entered === true)
            return;
        root.entry._entered = true;
        root.opacity = 0;
        rowLayout.y = 14;
        entranceAnim.restart();
    }

    Component.onCompleted: {
        root._playEntrance();
        if (root.isUser)
            root.bubbleShown(root.bubbleItem);
    }

    Component.onDestruction: {
        if (root.isUser)
            root.bubbleHidden(root.bubbleItem);
    }

    onVisibleChanged: {
        if (root.visible)
            root._playEntrance();
    }

    ParallelAnimation {
        id: entranceAnim
        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: rowLayout
            property: "y"
            to: 0
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: rowLayout
        width: parent.width
        height: Math.max(root.avatarSize, nameText.height + 6 + textCol.height)

        Rectangle {
            id: avatarShape
            width: root.avatarSize
            height: root.avatarSize
            radius: width / 2
            anchors.top: parent.top
            anchors.left: root.isUser ? undefined : parent.left
            anchors.right: root.isUser ? parent.right : undefined
            color: Colors.md3.primary_container
            visible: !root.isUser || userAvatarImg.status !== Image.Ready

            MaterialShape {
                anchors.centerIn: parent
                visible: !root.isUser
                shapeSize: parent.width * 0.58
                name: root.modelShapeName
                color: Colors.md3.on_primary_container
            }
        }

        ClippingRectangle {
            anchors.top: parent.top
            anchors.left: root.isUser ? undefined : parent.left
            anchors.right: root.isUser ? parent.right : undefined
            width: root.avatarSize
            height: root.avatarSize
            radius: width / 2
            clip: true
            color: "transparent"
            visible: root.isUser && userAvatarImg.status === Image.Ready

            Image {
                id: userAvatarImg
                anchors.fill: parent
                source: "file://" + Quickshell.env("HOME") + "/.face"
                sourceSize: Qt.size(64, 64)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Text {
            id: nameText
            anchors.top: parent.top
            anchors.left: root.isUser ? undefined : parent.left
            anchors.leftMargin: root.isUser ? 0 : root.avatarSize + 10
            anchors.right: root.isUser ? parent.right : undefined
            anchors.rightMargin: root.isUser ? root.avatarSize + 10 : 0
            text: root.isUser ? root.username : root.modelDisplayName
            horizontalAlignment: root.isUser ? Text.AlignRight : Text.AlignLeft
            color: Colors.md3.on_surface_variant
            font.pixelSize: 12
            font.weight: Font.Medium
            font.family: Config.fontFamily
        }

        MorphButton {
            id: copyBtn
            visible: !root.isError && root.messageText !== ""
            anchors.left: root.isUser ? undefined : nameText.right
            anchors.leftMargin: root.isUser ? 0 : 8
            anchors.right: root.isUser ? nameText.left : undefined
            anchors.rightMargin: root.isUser ? 8 : 0
            anchors.verticalCenter: nameText.verticalCenter
            size: 22
            iconSize: 13
            property bool copied: false
            icon: copyBtn.copied ? "check" : "copy"
            container: copyBtn.copied ? Colors.md3.primary_container : Colors.md3.secondary_container
            content: copyBtn.copied ? Colors.md3.on_primary_container : Colors.md3.on_secondary_container
            opacity: (rowHover.hovered || copyBtn.copied) ? 1 : 0
            enabled: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Timer {
                id: copiedReset
                interval: 1600
                onTriggered: copyBtn.copied = false
            }

            onClicked: {
                AiAssistantService.copyText(root.messageText);
                copyBtn.copied = true;
                copiedReset.restart();
            }
        }

        MorphButton {
            id: regenBtn
            visible: root.canRegenerate && !root.isError
            anchors.left: copyBtn.right
            anchors.leftMargin: 6
            anchors.verticalCenter: nameText.verticalCenter
            size: 22
            iconSize: 13
            icon: "restart"
            opacity: rowHover.hovered ? 1 : 0
            enabled: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            onClicked: AiAssistantService.regenerate()
        }

        Item {
            id: textCol
            anchors.top: nameText.bottom
            anchors.topMargin: 6
            anchors.left: root.isUser ? undefined : parent.left
            anchors.leftMargin: root.isUser ? 0 : root.avatarSize + 10
            anchors.right: root.isUser ? parent.right : undefined
            anchors.rightMargin: root.isUser ? root.avatarSize + 10 : 0
            width: root.isUser ? bubble.implicitWidth : reply.implicitWidth
            height: root.isUser ? bubble.implicitHeight : reply.implicitHeight

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            UserBubble {
                id: bubble
                visible: root.isUser
                anchors.right: parent.right
                entry: root.entry
                isError: root.isError
                maxWidth: root.contentMaxWidth
            }

            AssistantMessage {
                id: reply
                visible: !root.isUser
                anchors.left: parent.left
                text: root.messageText
                isError: root.isError
                maxWidth: root.contentMaxWidth
            }
        }
    }
}
