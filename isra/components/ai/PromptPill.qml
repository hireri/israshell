pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.components
import qs.style
import qs.services
import qs.icons
import "fileicons.js" as FileIcons

Item {
    id: root

    property bool isFresh: true
    property bool isFocused: false

    readonly property bool thinking: AiAssistantService.isStreaming && AiAssistantService.awaitingFirstToken && !AiAssistantService.hasError
    readonly property bool supportsVision: Config.aiAssistant.providers[Config.aiAssistant.provider]?.supportsVision === true
    readonly property real attachmentGap: attachmentPreview.visible ? (attachmentPreview.height + 20) : 0
    readonly property bool isRecognizedCommand: ["/clear"].includes(inputField.text.trim().toLowerCase())

    property bool revealed: false
    property int hintIndex: 0

    readonly property int freshWidth: 480
    readonly property int expandedWidth: 360
    readonly property int thinkingWidth: 220

    signal attachRequested

    function focusInput(): void {
        inputField.forceActiveFocus();
    }

    function _sendOrInterrupt(): void {
        const text = inputField.text.trim();
        if (text === "" && AiAssistantService.pendingAttachments.length === 0) {
            if (AiAssistantService.isStreaming)
                AiAssistantService.stop();
            return;
        }
        if (text.toLowerCase() === "/clear") {
            inputField.text = "";
            AiAssistantService.clearHistory();
            return;
        }
        inputField.text = "";
        if (AiAssistantService.isStreaming)
            AiAssistantService.stop();
        AiAssistantService.submit(text);
    }

    onThinkingChanged: {
        if (thinking) {
            exitThinkingAnim.stop();
            enterThinkingAnim.restart();
            root.hintIndex = Math.floor(Math.random() * root._hintPhrases.length);
            thinkingHintCycleTimer.restart();
        } else {
            enterThinkingAnim.stop();
            exitThinkingAnim.restart();
            thinkingHintCycleTimer.stop();
        }
    }

    SequentialAnimation {
        id: enterThinkingAnim
        NumberAnimation {
            target: typingLayer
            property: "opacity"
            to: 0
            duration: 150
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: thinkingRow
            property: "opacity"
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: exitThinkingAnim
        NumberAnimation {
            target: thinkingRow
            property: "opacity"
            to: 0
            duration: 150
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: typingLayer
            property: "opacity"
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: {
                if (root.isFocused)
                    Qt.callLater(() => root.focusInput());
            }
        }
    }

    Timer {
        id: thinkingHintCycleTimer
        interval: 4300
        repeat: true
        onTriggered: hintCycleAnim.restart()
    }

    SequentialAnimation {
        id: hintCycleAnim
        NumberAnimation {
            target: hintText
            property: "opacity"
            to: 0
            duration: 150
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: root.hintIndex = (root.hintIndex + 1) % root._hintPhrases.length
        }
        NumberAnimation {
            target: hintText
            property: "opacity"
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    readonly property var _hintPhrases: [Localization.t("aiAssistant.thinking_hint_1"), Localization.t("aiAssistant.thinking_hint_2"), Localization.t("aiAssistant.thinking_hint_3"), Localization.t("aiAssistant.thinking_hint_4"), Localization.t("aiAssistant.thinking_hint_5"), Localization.t("aiAssistant.thinking_hint_6")]

    Component.onCompleted: {
        if (thinking) {
            typingLayer.opacity = 0;
            thinkingRow.opacity = 1;
            root.hintIndex = Math.floor(Math.random() * root._hintPhrases.length);
            thinkingHintCycleTimer.restart();
        }
        Qt.callLater(() => root.revealed = true);
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: (root.isFocused && revealed) ? (root.isFresh ? Math.round((parent.height - height) / 2) - Math.round(attachmentGap / 2) : 32) : -80
    width: thinking ? thinkingWidth : (root.isFresh ? freshWidth : expandedWidth)
    height: 56
    opacity: (root.isFocused && revealed) ? 1.0 : 0.0

    Behavior on width {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutQuint
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutQuint
        }
    }
    Behavior on anchors.bottomMargin {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutQuint
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        border.width: 1
        border.color: Colors.md3.outline_variant
    }

    Row {
        id: attachmentPreview
        visible: AiAssistantService.pendingAttachments.length > 0
        anchors.bottom: parent.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 14
        spacing: 8
        opacity: visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: AiAssistantService.pendingAttachments

            Item {
                id: chip
                required property var modelData
                required property int index
                readonly property bool isImage: modelData.kind === "image"

                width: 52
                height: 52
                scale: 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutQuint
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 14
                    clip: true
                    color: Colors.md3.surface_container_high
                    border.width: 1
                    border.color: Colors.md3.outline_variant

                    Image {
                        visible: chip.isImage
                        anchors.fill: parent
                        source: chip.isImage ? ("data:" + chip.modelData.mimeType + ";base64," + chip.modelData.base64) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    MaterialIcon {
                        visible: !chip.isImage
                        anchors.centerIn: parent
                        name: FileIcons.forName(chip.modelData.name)
                        iconSize: 20
                        color: Colors.md3.on_surface_variant
                    }

                    Text {
                        visible: !chip.isImage
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: chip.modelData.name
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 9
                        font.family: Config.fontFamily
                    }
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -4
                    anchors.rightMargin: -4
                    color: Colors.md3.surface_container_highest
                    border.width: 1
                    border.color: Colors.md3.outline_variant

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "close"
                        iconSize: 11
                        color: Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AiAssistantService.removeAttachment(chip.index)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.MiddleButton
                    onClicked: AiAssistantService.removeAttachment(chip.index)
                }
            }
        }
    }

    Item {
        id: leftContent
        anchors {
            left: parent.left
            leftMargin: 10
            right: actionBtn.left
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        height: parent.height

        Rectangle {
            id: attachBtn
            visible: !root.thinking && AiAssistantService.pendingAttachments.length < AiAssistantService.maxAttachments
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 18
            color: attachMa.containsMouse ? Colors.md3.surface_container_highest : "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                name: "add"
                iconSize: 22
                color: Colors.md3.on_surface_variant
            }

            MouseArea {
                id: attachMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.attachRequested()
            }
        }

        Item {
            id: typingLayer
            anchors.left: attachBtn.visible ? attachBtn.right : parent.left
            anchors.leftMargin: attachBtn.visible ? 4 : 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            opacity: 1
            enabled: !root.thinking

            TextInput {
                id: inputField
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                focus: true
                text: AiAssistantService.draftText
                color: root.isRecognizedCommand ? "transparent" : Colors.md3.on_surface
                font.pixelSize: 14
                font.family: Config.fontFamily
                clip: true

                onTextChanged: AiAssistantService.draftText = text

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: Localization.t("aiAssistant.placeholder").arg(Config.aiAssistant.provider)
                    color: Colors.md3.on_surface_variant
                    font: parent.font
                    visible: inputField.text === ""
                    opacity: 0.45
                }

                Rectangle {
                    id: commandChip
                    visible: root.isRecognizedCommand
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: 24
                    implicitWidth: chipText.implicitWidth + 16
                    radius: height / 2
                    color: Colors.md3.primary_container

                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: inputField.text.trim()
                        color: Colors.md3.on_primary_container
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        font.weight: Font.Medium
                    }
                }

                Keys.onEscapePressed: AiAssistantService.close()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        event.accepted = true;
                        root._sendOrInterrupt();
                        return;
                    }
                    if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) && root.isRecognizedCommand) {
                        event.accepted = true;
                        inputField.text = "";
                    }
                }
            }
        }
    }

    Item {
        id: thinkingRow
        anchors.fill: parent
        opacity: 0

        LoadingSpinner {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            running: root.thinking
        }

        Text {
            id: hintText
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -6
            text: root._hintPhrases[root.hintIndex]
            font.italic: true
            font.pixelSize: 13
            font.family: Config.fontFamily
            color: Colors.md3.on_surface_variant
        }
    }

    Rectangle {
        id: actionBtn
        readonly property bool showStop: AiAssistantService.isStreaming && inputField.text.trim() === ""
        readonly property bool hasText: inputField.text.trim() !== ""
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        width: 36
        height: 36
        radius: 18
        color: {
            if (showStop)
                return actionMa.containsMouse ? Colors.md3.primary : Colors.md3.primary_container;
            if (hasText)
                return Colors.md3.primary;
            return actionMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high;
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            name: actionBtn.showStop ? "stop" : "arrow-upward"
            filled: true
            iconSize: 18
            transitionType: "none"
            color: {
                if (actionBtn.showStop)
                    return actionMa.containsMouse ? Colors.md3.on_primary : Colors.md3.on_primary_container;
                if (actionBtn.hasText)
                    return Colors.md3.on_primary;
                return Colors.md3.on_surface;
            }
        }

        MouseArea {
            id: actionMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root._sendOrInterrupt()
        }
    }
}
