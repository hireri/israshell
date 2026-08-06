pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Qt.labs.platform as Labs
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    function fileIconFor(name: string): string {
        const ext = (name.split(".").pop() ?? "").toLowerCase();
        if (["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "avif", "tiff", "ico"].includes(ext))
            return "image";
        if (["mp4", "mkv", "webm", "mov", "avi", "m4v"].includes(ext))
            return "video";
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac"].includes(ext))
            return "queue-music";
        if (["sh", "py", "js", "ts", "qml", "c", "cpp", "h", "rs", "go", "json", "yaml", "yml", "toml", "html", "css"].includes(ext))
            return "terminal";
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].includes(ext))
            return "folder-zip";
        if (["pdf", "txt", "md", "doc", "docx", "odt", "rtf"].includes(ext))
            return "description";
        return "question-mark";
    }

    component ChatMessageRow: Item {
        id: msgRow

        required property var entry
        required property string username
        required property string modelDisplayName
        required property string modelShapeName

        readonly property bool isUser: entry.role === "user"
        readonly property bool isError: entry.isError === true
        readonly property real avatarSize: 30
        readonly property real maxContentWidth: width * 0.86

        height: rowLayout.height
        opacity: 1

        function _playEntrance(): void {
            if (msgRow.entry._skipEntranceAnim === true || msgRow.entry._entered === true)
                return;
            msgRow.entry._entered = true;
            msgRow.opacity = 0;
            rowLayout.y = 14;
            entranceAnim.restart();
        }

        Component.onCompleted: msgRow._playEntrance()

        onVisibleChanged: {
            if (msgRow.visible)
                msgRow._playEntrance();
        }

        ParallelAnimation {
            id: entranceAnim
            NumberAnimation {
                target: msgRow
                property: "opacity"
                to: 1
                duration: 280
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: rowLayout
                property: "y"
                to: 0
                duration: 360
                easing.type: Easing.OutQuint
            }
        }

        Item {
            id: rowLayout
            width: parent.width
            height: Math.max(avatarShape.height, nameText.height + 6 + textCol.height)

            Rectangle {
                id: avatarShape
                width: msgRow.avatarSize
                height: msgRow.avatarSize
                radius: width / 2
                anchors.top: parent.top
                anchors.left: msgRow.isUser ? undefined : parent.left
                anchors.right: msgRow.isUser ? parent.right : undefined
                color: Colors.md3.primary_container
                visible: !msgRow.isUser || userAvatarImg.status !== Image.Ready

                MaterialShape {
                    anchors.centerIn: parent
                    visible: !msgRow.isUser
                    shapeSize: parent.width * 0.58
                    name: msgRow.modelShapeName
                    color: Colors.md3.on_primary_container
                }
            }

            ClippingRectangle {
                anchors.top: parent.top
                anchors.left: msgRow.isUser ? undefined : parent.left
                anchors.right: msgRow.isUser ? parent.right : undefined
                width: msgRow.avatarSize
                height: msgRow.avatarSize
                radius: width / 2
                clip: true
                color: "transparent"
                visible: msgRow.isUser && userAvatarImg.status === Image.Ready

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
                anchors.left: msgRow.isUser ? undefined : parent.left
                anchors.leftMargin: msgRow.isUser ? 0 : msgRow.avatarSize + 10
                anchors.right: msgRow.isUser ? parent.right : undefined
                anchors.rightMargin: msgRow.isUser ? msgRow.avatarSize + 10 : 0
                text: msgRow.isUser ? msgRow.username : msgRow.modelDisplayName
                horizontalAlignment: msgRow.isUser ? Text.AlignRight : Text.AlignLeft
                color: Colors.md3.on_surface_variant
                font.pixelSize: 12
                font.weight: Font.Medium
                font.family: Config.fontFamily
            }

            Item {
                id: textCol
                anchors.top: nameText.bottom
                anchors.topMargin: 6
                anchors.left: msgRow.isUser ? undefined : parent.left
                anchors.leftMargin: msgRow.isUser ? 0 : msgRow.avatarSize + 10
                anchors.right: msgRow.isUser ? parent.right : undefined
                anchors.rightMargin: msgRow.isUser ? msgRow.avatarSize + 10 : 0
                width: bubbleOrText.width
                height: bubbleOrText.height

                Rectangle {
                    id: bubble
                    visible: msgRow.isUser
                    anchors.right: parent.right
                    radius: 16
                    color: Qt.alpha(msgRow.isError ? Colors.md3.error_container : Colors.md3.surface_container_high, Config.blurOpacity)
                    border.width: 1
                    border.color: Colors.md3.outline_variant
                    implicitWidth: Math.max(bubbleText.visible ? bubbleText.width : 0, bubbleAttachRow.visible ? bubbleAttachRow.width : 0) + 24
                    implicitHeight: bubbleText.visible ? (bubbleText.y + bubbleText.height + 8) : (bubbleAttachRow.visible ? bubbleAttachRow.y + bubbleAttachRow.height + 8 : 16)

                    Row {
                        id: bubbleAttachRow
                        visible: (msgRow.entry.attachments ?? []).length > 0
                        x: 12
                        y: 8
                        spacing: 6

                        Repeater {
                            model: msgRow.entry.attachments ?? []

                            Item {
                                id: attachChip
                                required property var modelData
                                readonly property bool isImage: modelData.kind === "image"
                                width: isImage ? 90 : Math.min(fileChipText.implicitWidth + 34, 140)
                                height: isImage ? 90 : 26

                                ClippingRectangle {
                                    visible: attachChip.isImage
                                    anchors.fill: parent
                                    radius: 10
                                    clip: true
                                    color: Colors.md3.surface_container_highest

                                    Image {
                                        anchors.fill: parent
                                        source: attachChip.isImage ? ("data:" + attachChip.modelData.mimeType + ";base64," + attachChip.modelData.base64) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }

                                Rectangle {
                                    visible: !attachChip.isImage
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: Colors.md3.surface_container_highest
                                    border.width: 1
                                    border.color: Colors.md3.outline_variant

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: root.fileIconFor(attachChip.modelData.name)
                                            iconSize: 12
                                            color: Colors.md3.on_surface_variant
                                        }

                                        Text {
                                            id: fileChipText
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: Math.min(implicitWidth, 96)
                                            elide: Text.ElideMiddle
                                            text: attachChip.modelData.name
                                            color: Colors.md3.on_surface_variant
                                            font.pixelSize: 11
                                            font.family: Config.fontFamily
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        id: bubbleText
                        x: 12
                        y: bubbleAttachRow.visible ? bubbleAttachRow.y + bubbleAttachRow.height + 8 : 8
                        visible: text !== ""
                        width: Math.min(implicitWidth, msgRow.maxContentWidth - msgRow.avatarSize - 10)
                        wrapMode: Text.Wrap
                        text: msgRow.entry.text
                        color: msgRow.isError ? Colors.md3.on_error_container : Colors.md3.on_surface
                        font.pixelSize: 15
                        font.family: Config.fontFamily
                        lineHeight: 1.2
                    }
                }

                Text {
                    id: plainText
                    visible: false
                    anchors.left: parent.left

                    function _toHtml(md) {
                        let s = md.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                        s = s.replace(/`([^`]+)`/g, "<code>$1</code>");
                        s = s.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>");
                        s = s.replace(/__([^_]+)__/g, "<b>$1</b>");
                        s = s.replace(/\*([^*]+)\*/g, "<i>$1</i>");
                        s = s.replace(/_([^_]+)_/g, "<i>$1</i>");
                        s = s.replace(/^### (.*)$/gm, "<h3>$1</h3>");
                        s = s.replace(/^## (.*)$/gm, "<h2>$1</h2>");
                        s = s.replace(/^# (.*)$/gm, "<h1>$1</h1>");
                        s = s.replace(/^[-*] (.*)$/gm, "• $1<br>");
                        s = s.replace(/\n/g, "<br>");
                        return s;
                    }

                    width: Math.min(implicitWidth, msgRow.maxContentWidth - msgRow.avatarSize - 10)
                    text: msgRow.isError ? msgRow.entry.text : _toHtml(msgRow.entry.text)
                    textFormat: msgRow.isError ? Text.PlainText : Text.StyledText
                    color: msgRow.isError ? Colors.md3.error : Colors.md3.on_surface
                    font.pixelSize: 15
                    font.family: Config.fontFamily
                    wrapMode: Text.Wrap
                    lineHeight: 1.2
                }

                DropShadow {
                    anchors.fill: plainText
                    visible: !msgRow.isUser
                    source: plainText
                    radius: 10
                    samples: 21
                    horizontalOffset: 0
                    verticalOffset: 1
                    color: Qt.alpha(Colors.md3.background, 0.75)
                }

                Item {
                    id: bubbleOrText
                    width: msgRow.isUser ? bubble.implicitWidth : plainText.width
                    height: msgRow.isUser ? bubble.implicitHeight : plainText.height
                }
            }
        }
    }

    Labs.FileDialog {
        id: imagePicker
        title: Localization.t("aiAssistant.choose_attachment")
        fileMode: Labs.FileDialog.OpenFiles
        nameFilters: [Localization.t("aiAssistant.image_files") + " (*.png *.jpg *.jpeg *.webp *.gif *.bmp)", Localization.t("aiAssistant.all_files") + " (*)"]
        onAccepted: {
            for (const url of imagePicker.files)
                AiAssistantService.attachFileFromUrl(url);
            AiAssistantService.open();
        }
        onRejected: AiAssistantService.open()
    }

    Loader {
        id: uiLoader
        active: AiAssistantService.visible
        sourceComponent: sessionComp
    }

    Component {
        id: sessionComp

        Item {
            id: sessionRoot

            readonly property var focusedScreen: {
                const name = CompositorService.focusedMonitor?.name;
                return Quickshell.screens.find(s => s.name === name) ?? null;
            }

            readonly property string username: {
                const raw = Quickshell.env("USER") || "there";
                return raw.charAt(0).toUpperCase() + raw.slice(1);
            }

            property int greetingIndex: 0

            function _timeOfDayBucket() {
                const h = new Date().getHours();
                if (h >= 5 && h < 12)
                    return "morning";
                if (h >= 12 && h < 17)
                    return "afternoon";
                if (h >= 17 && h < 22)
                    return "evening";
                return "night";
            }

            readonly property var greetingKeys: {
                const bucket = _timeOfDayBucket();
                return ["aiAssistant.welcome_" + bucket + "_1", "aiAssistant.welcome_" + bucket + "_2"];
            }

            function getGreeting(index, name) {
                if (index < 0 || index >= greetingKeys.length)
                    index = 0;
                const key = greetingKeys[index];
                const translated = Localization.t(key);
                const template = translated;
                return template.replace("%1", name);
            }

            readonly property string modelName: Config.aiAssistant.provider

            readonly property var _shapeNames: ["circle", "square", "slanted", "arch", "fan", "arrow", "semiCircle", "oval", "pill", "triangle", "diamond", "clamShell", "pentagon", "gem", "sunny", "verySunny", "cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "ghostish", "clover4", "clover8", "burst", "softBurst", "boom", "softBoom", "flower", "puffy", "puffyDiamond", "pixelCircle", "pixelTriangle", "bun", "heart"]

            function _hashString(s) {
                let h = 0;
                for (let i = 0; i < s.length; i++)
                    h = (h * 31 + s.charCodeAt(i)) | 0;
                return Math.abs(h);
            }

            readonly property string modelShapeName: _shapeNames[_hashString(modelName) % _shapeNames.length]

            Component.onCompleted: {
                greetingIndex = Math.floor(Math.random() * greetingKeys.length);
            }

            Instantiator {
                model: Quickshell.screens

                AiAssistantBackdrop {}
            }

            Instantiator {
                model: Quickshell.screens

                PanelWindow {
                    id: overlay
                    required property var modelData
                    screen: modelData
                    color: "transparent"
                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "quickshell:aiassistant"

                    readonly property bool isFocused: sessionRoot.focusedScreen === modelData
                    WlrLayershell.keyboardFocus: isFocused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                    readonly property bool blurEnabled: Config.blurAllowed()
                    BackgroundEffect.blurRegion: blurEnabled ? aiBlurRegion : null

                    readonly property bool isFresh: AiAssistantService.history.length === 0 && !AiAssistantService.hasError && AiAssistantService.streamedAnswer === ""

                    Region {
                        id: aiBlurRegion
                        Region {
                            item: floatingPill
                        }
                        Region {
                            item: askScreenBtn
                        }
                    }

                    onIsFocusedChanged: {
                        if (isFocused)
                            Qt.callLater(() => inputField.forceActiveFocus());
                    }

                    Shortcut {
                        enabled: overlay.isFocused
                        sequence: "Escape"
                        onActivated: AiAssistantService.close()
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: AiAssistantService.close()
                    }

                    Item {
                        id: heroContainer
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: floatingPill.top
                            bottomMargin: 24 + floatingPill.attachmentGap
                        }
                        width: floatingPill.width
                        height: heroText.implicitHeight

                        readonly property bool shouldShow: overlay.isFresh && overlay.isFocused && floatingPill.revealed

                        opacity: shouldShow ? 1.0 : 0.0
                        scale: shouldShow ? 1.0 : 0.85
                        transformOrigin: Item.Bottom

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 320
                                easing.type: Easing.OutQuint
                            }
                        }
                        Behavior on anchors.bottomMargin {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutQuint
                            }
                        }

                        Text {
                            id: heroText
                            anchors.centerIn: parent
                            width: parent.width
                            text: sessionRoot.getGreeting(sessionRoot.greetingIndex, sessionRoot.username)
                            color: Colors.md3.on_surface
                            font.pixelSize: 28
                            font.family: Config.fontFamily
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        DropShadow {
                            anchors.fill: heroText
                            source: heroText
                            radius: 10
                            samples: 21
                            horizontalOffset: 0
                            verticalOffset: 1
                            color: Qt.alpha(Colors.md3.background, 0.75)
                        }
                    }

                    Flickable {
                        id: chatFlick
                        anchors {
                            top: parent.top
                            topMargin: 64
                            left: parent.left
                            right: parent.right
                            bottom: floatingPill.top
                            bottomMargin: 16
                        }
                        clip: true
                        visible: !overlay.isFresh && overlay.isFocused && floatingPill.revealed
                        opacity: visible ? 1.0 : 0.0
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: chatColumn.height + 40

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutCubic
                            }
                        }

                        property real _prevContentHeight: 0

                        onContentHeightChanged: {
                            const wasAtBottom = contentY + height >= _prevContentHeight - 24;
                            _prevContentHeight = contentHeight;
                            if (wasAtBottom)
                                Qt.callLater(() => {
                                    chatFlick.contentY = Math.max(0, chatFlick.contentHeight - chatFlick.height);
                                });
                        }

                        MouseArea {
                            x: 0
                            y: 0
                            width: chatFlick.width
                            height: Math.max(chatFlick.contentHeight, chatFlick.height)
                            onClicked: AiAssistantService.close()
                        }

                        Column {
                            id: chatColumn
                            x: Math.max(24, (chatFlick.width - width) / 2)
                            y: 20
                            width: Math.min(chatFlick.width - 48, 940)
                            spacing: 22

                            Repeater {
                                model: AiAssistantService.history.length
                                delegate: ChatMessageRow {
                                    required property int index
                                    width: chatColumn.width
                                    entry: AiAssistantService.history[index]
                                    username: sessionRoot.username
                                    modelDisplayName: sessionRoot.modelName
                                    modelShapeName: sessionRoot.modelShapeName
                                }
                            }

                            ChatMessageRow {
                                width: chatColumn.width
                                visible: AiAssistantService.isStreaming && !AiAssistantService.awaitingFirstToken && AiAssistantService.streamedAnswer !== ""
                                entry: ({
                                    role: "model",
                                    text: AiAssistantService.streamedAnswer
                                })
                                username: sessionRoot.username
                                modelDisplayName: sessionRoot.modelName
                                modelShapeName: sessionRoot.modelShapeName
                            }

                            ChatMessageRow {
                                width: chatColumn.width
                                visible: AiAssistantService.hasError
                                entry: ({
                                    role: "model",
                                    text: AiAssistantService.errorText,
                                    isError: true
                                })
                                username: sessionRoot.username
                                modelDisplayName: sessionRoot.modelName
                                modelShapeName: sessionRoot.modelShapeName
                            }
                        }
                    }

                    Item {
                        id: floatingPill
                        readonly property bool thinking: AiAssistantService.isStreaming && AiAssistantService.awaitingFirstToken && !AiAssistantService.hasError
                        readonly property bool supportsVision: Config.aiAssistant.providers[Config.aiAssistant.provider]?.supportsVision === true
                        readonly property int freshWidth: 480
                        readonly property int expandedWidth: 360
                        readonly property int thinkingWidth: 220
                        readonly property bool isRecognizedCommand: ["/clear"].includes(inputField.text.trim().toLowerCase())
                        property int hintIndex: 0

                        function _sendOrInterrupt() {
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
                                floatingPill.hintIndex = Math.floor(Math.random() * floatingPill._hintPhrases.length);
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
                                    if (overlay.isFocused)
                                        Qt.callLater(() => inputField.forceActiveFocus());
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
                                script: floatingPill.hintIndex = (floatingPill.hintIndex + 1) % floatingPill._hintPhrases.length
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

                        property bool revealed: false

                        Component.onCompleted: {
                            if (thinking) {
                                typingLayer.opacity = 0;
                                thinkingRow.opacity = 1;
                                floatingPill.hintIndex = Math.floor(Math.random() * floatingPill._hintPhrases.length);
                                thinkingHintCycleTimer.restart();
                            }
                            Qt.callLater(() => floatingPill.revealed = true);
                        }

                        readonly property real attachmentGap: attachmentPreview.visible ? (attachmentPreview.height + 20) : 0

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: (overlay.isFocused && revealed)
                            ? (overlay.isFresh ? Math.round((overlay.height - height) / 2) - Math.round(attachmentGap / 2) : 32)
                            : -80
                        width: thinking ? thinkingWidth : (overlay.isFresh ? freshWidth : expandedWidth)
                        height: 56
                        opacity: (overlay.isFocused && revealed) ? 1.0 : 0.0

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
                                            name: root.fileIconFor(chip.modelData.name)
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
                                visible: !floatingPill.thinking && AiAssistantService.pendingAttachments.length < AiAssistantService.maxAttachments
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
                                    onClicked: {
                                        imagePicker.open();
                                        AiAssistantService.close();
                                    }
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
                                enabled: !floatingPill.thinking

                                TextInput {
                                    id: inputField
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    focus: true
                                    text: AiAssistantService.draftText
                                    color: floatingPill.isRecognizedCommand ? "transparent" : Colors.md3.on_surface
                                    font.pixelSize: 14
                                    font.family: Config.fontFamily
                                    clip: true

                                    onTextChanged: AiAssistantService.draftText = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: Localization.t("aiAssistant.placeholder").arg(sessionRoot.modelName)
                                        color: Colors.md3.on_surface_variant
                                        font: parent.font
                                        visible: inputField.text === ""
                                        opacity: 0.45
                                    }

                                    Rectangle {
                                        id: commandChip
                                        visible: floatingPill.isRecognizedCommand
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
                                            floatingPill._sendOrInterrupt();
                                            return;
                                        }
                                        if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) && floatingPill.isRecognizedCommand) {
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
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                size: 20
                                running: floatingPill.thinking
                            }

                            Text {
                                id: hintText
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: -6
                                text: floatingPill._hintPhrases[floatingPill.hintIndex]
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
                                onClicked: floatingPill._sendOrInterrupt()
                            }
                        }
                    }

                    Item {
                        id: askScreenBtn
                        readonly property bool shouldShow: overlay.isFresh && overlay.isFocused && floatingPill.revealed && !AiAssistantService.hasScreenAttachment && AiAssistantService.currentProviderSupportsVision()
                        anchors.top: floatingPill.bottom
                        anchors.topMargin: 12
                        anchors.left: floatingPill.left
                        width: askScreenRow.implicitWidth + 26
                        height: 34
                        opacity: shouldShow ? 1.0 : 0.0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: askScreenMa.containsMouse ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity) : Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
                            border.width: 1
                            border.color: Colors.md3.outline_variant

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }

                        Row {
                            id: askScreenRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "present-to-all"
                                iconSize: 15
                                color: Colors.md3.on_surface_variant
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Localization.t("aiAssistant.ask_about_screen")
                                color: Colors.md3.on_surface_variant
                                font.pixelSize: 13
                                font.family: Config.fontFamily
                            }
                        }

                        MouseArea {
                            id: askScreenMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AiAssistantService.attachScreenshot(overlay.modelData.name)
                        }
                    }
                }
            }
        }
    }
}