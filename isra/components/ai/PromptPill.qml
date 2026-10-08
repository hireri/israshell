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

    readonly property int baseHeight: 56
    readonly property real maxInputHeight: 150
    readonly property real inputHeight: Math.min(root.maxInputHeight, inputField.contentHeight)

    readonly property var commands: [
        {
            name: "clear",
            icon: "clear-all",
            description: Localization.t("aiAssistant.cmd_clear")
        },
        {
            name: "retry",
            icon: "restart",
            description: Localization.t("aiAssistant.cmd_retry")
        },
        {
            name: "copy",
            icon: "copy",
            description: Localization.t("aiAssistant.cmd_copy")
        },
        {
            name: "model",
            icon: "swap-horiz",
            hint: "[provider]",
            takesArg: true,
            description: Localization.t("aiAssistant.cmd_model")
        },
        {
            name: "screen",
            icon: "screenshot",
            description: Localization.t("aiAssistant.cmd_screen")
        },
        {
            name: "attach",
            icon: "add",
            description: Localization.t("aiAssistant.cmd_attach")
        }
    ]

    property bool menuDismissed: false
    property int menuIndex: 0
    property int _recall: -1
    property bool _recalling: false

    readonly property var _parsed: {
        const m = /^\/(\S*)(?:\s+([^\n]*))?$/.exec(inputField.text);
        return m ? {
            name: m[1].toLowerCase(),
            arg: m[2]
        } : null;
    }

    readonly property var menuItems: {
        const p = root._parsed;
        if (!p)
            return [];
        if (p.arg === undefined)
            return root.commands.filter(c => c.name.startsWith(p.name)).map(c => ({
                        id: c.name,
                        icon: c.icon,
                        label: "/" + c.name,
                        hint: c.hint ?? "",
                        description: c.description,
                        takesArg: c.takesArg === true
                    }));
        if (p.name === "model")
            return Object.keys(Config.aiAssistant.providers).filter(k => k.toLowerCase().includes(p.arg.trim().toLowerCase())).slice(0, 7).map(k => ({
                        id: "model",
                        arg: k,
                        icon: k === Config.aiAssistant.provider ? "check" : "memory",
                        label: k,
                        hint: k === Config.aiAssistant.provider ? "· " + Localization.t("aiAssistant.cmd_current") : "",
                        description: "",
                        takesArg: false
                    }));
        return [];
    }

    readonly property bool isRecognizedCommand: root._parsed !== null && root._parsed.arg === undefined && root.commands.some(c => c.name === root._parsed.name)
    readonly property bool _unknownCommand: root._parsed !== null && root._parsed.arg === undefined && root._parsed.name !== "" && root.menuItems.length === 0
    readonly property bool menuOpen: !root.thinking && !root.menuDismissed && (root.menuItems.length > 0 || root._unknownCommand)
    readonly property int menuCurrent: Math.max(0, Math.min(root.menuIndex, root.menuItems.length - 1))

    property bool revealed: false
    property int hintIndex: Math.floor(Math.random() * root._hintPhrases.length)

    readonly property int freshWidth: 480
    readonly property int expandedWidth: 360

    readonly property int actionBtnMargin: 10
    readonly property int actionBtnSize: 36
    readonly property int spinnerSize: 20
    readonly property int thinkingGap: 12

    readonly property int thinkingSideReserve: root.actionBtnMargin + root.actionBtnSize + root.thinkingGap

    readonly property int thinkingMinWidth: 160

    readonly property int thinkingResizeDuration: 320

    readonly property int thinkingWidth: Math.round(Math.max(root.thinkingMinWidth, Math.min(root.expandedWidth, hintMetrics.advanceWidth + 2 * root.thinkingSideReserve)))

    TextMetrics {
        id: hintMetrics
        text: root._hintPhrases[root.hintIndex] ?? ""
        font.italic: true
        font.pixelSize: 13
        font.family: Config.fontFamily
    }

    function _pickHintIndex(): void {
        root.hintIndex = Math.floor(Math.random() * root._hintPhrases.length);
    }

    signal attachRequested
    signal screenRequested

    function dismissMenu(): bool {
        if (!root.menuOpen)
            return false;
        root.menuDismissed = true;
        return true;
    }

    function _runCommand(id: string, arg: var): void {
        inputField.text = "";
        switch (id) {
        case "clear":
            AiAssistantService.clearHistory();
            break;
        case "retry":
            AiAssistantService.regenerate();
            break;
        case "copy":
            AiAssistantService.copyLastAnswer();
            break;
        case "model":
            if (arg)
                AiAssistantService.setProvider(arg);
            break;
        case "screen":
            root.screenRequested();
            break;
        case "attach":
            root.attachRequested();
            break;
        }
    }

    function _setInput(text: string): void {
        root._recalling = true;
        inputField.text = text;
        inputField.cursorPosition = text.length;
        root._recalling = false;
    }

    function _complete(i: int): void {
        const item = root.menuItems[i];
        if (!item)
            return;
        root._setInput(item.arg !== undefined ? "/model " + item.arg : "/" + item.id + (item.takesArg ? " " : ""));
    }

    function _activate(i: int): void {
        const item = root.menuItems[i];
        if (!item)
            return;
        if (item.takesArg)
            root._complete(i);
        else
            root._runCommand(item.id, item.arg);
    }

    function _recallPrompt(step: int): void {
        const h = AiAssistantService.sentPrompts;
        const next = root._recall + step;
        if (next < -1 || next >= h.length)
            return;
        root._recall = next;
        root._setInput(next < 0 ? "" : h[h.length - 1 - next]);
    }

    function focusInput(): void {
        inputField.forceActiveFocus();
    }

    function _sendOrInterrupt(): void {
        if (root.menuOpen) {
            if (root.menuItems.length > 0)
                root._activate(root.menuCurrent);
            return;
        }
        const text = inputField.text.trim();
        if (text === "" && AiAssistantService.pendingAttachments.length === 0) {
            if (AiAssistantService.isStreaming)
                AiAssistantService.stop();
            return;
        }
        const p = root._parsed;
        if (p && p.arg === undefined && root.isRecognizedCommand && !root.commands.find(c => c.name === p.name).takesArg) {
            root._runCommand(p.name, undefined);
            return;
        }
        root._recall = -1;
        inputField.text = "";
        if (AiAssistantService.isStreaming)
            AiAssistantService.stop();
        AiAssistantService.submit(text);
    }

    onThinkingChanged: {
        if (thinking) {
            exitThinkingAnim.stop();
            enterThinkingAnim.restart();
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
                root._pickHintIndex();
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
        PauseAnimation {
            duration: root.thinkingResizeDuration
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
            thinkingHintCycleTimer.restart();
        }
        Qt.callLater(() => root.revealed = true);
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: (root.isFocused && revealed) ? (root.isFresh ? Math.round((parent.height - root.baseHeight) / 2) - Math.round(attachmentGap / 2) : 32) : -80
    width: thinking ? thinkingWidth : (root.isFresh ? freshWidth : expandedWidth)
    height: thinking ? baseHeight : Math.max(baseHeight, inputHeight + 32)

    Behavior on height {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }
    opacity: (root.isFocused && revealed) ? 1.0 : 0.0

    Behavior on width {
        NumberAnimation {
            duration: root.thinkingResizeDuration
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
        radius: Math.min(height / 2, 28)
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

        MorphButton {
            id: attachBtn
            visible: !root.thinking && AiAssistantService.pendingAttachments.length < AiAssistantService.maxAttachments
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.actionBtnMargin
            size: root.actionBtnSize
            icon: "add"
            iconSize: 22
            container: "transparent"
            content: Colors.md3.on_surface_variant
            onClicked: root.attachRequested()
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

            Flickable {
                id: inputFlick
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: root.inputHeight
                contentWidth: width
                contentHeight: inputField.contentHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                function ensureCursorVisible(): void {
                    const r = inputField.cursorRectangle;
                    if (r.y < inputFlick.contentY)
                        inputFlick.contentY = r.y;
                    else if (r.y + r.height > inputFlick.contentY + inputFlick.height)
                        inputFlick.contentY = r.y + r.height - inputFlick.height;
                }

                TextEdit {
                    id: inputField
                    width: inputFlick.width
                    focus: true
                    text: AiAssistantService.draftText
                    textFormat: TextEdit.PlainText
                    wrapMode: TextEdit.Wrap
                    color: root.isRecognizedCommand ? Colors.md3.primary : Colors.md3.on_surface
                    font.pixelSize: 14
                    font.weight: root.isRecognizedCommand ? Font.Medium : Font.Normal
                    font.family: Config.fontFamily
                    selectionColor: Qt.alpha(Colors.md3.primary, 0.35)
                    selectedTextColor: Colors.md3.on_surface

                    onTextChanged: {
                        AiAssistantService.draftText = text;
                        root.menuDismissed = false;
                        root.menuIndex = 0;
                        if (!root._recalling)
                            root._recall = -1;
                    }
                    onCursorRectangleChanged: inputFlick.ensureCursorVisible()

                    Keys.onPressed: event => {
                        const key = event.key;
                        if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                            event.accepted = true;
                            if (event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier)) {
                                inputField.remove(inputField.selectionStart, inputField.selectionEnd);
                                inputField.insert(inputField.cursorPosition, "\n");
                            } else {
                                root._sendOrInterrupt();
                            }
                            return;
                        }
                        if (root.menuOpen && root.menuItems.length > 0) {
                            const n = root.menuItems.length;
                            if (key === Qt.Key_Up || key === Qt.Key_Down) {
                                root.menuIndex = (root.menuCurrent + (key === Qt.Key_Up ? n - 1 : 1)) % n;
                                event.accepted = true;
                            } else if (key === Qt.Key_Tab) {
                                root._complete(root.menuCurrent);
                                event.accepted = true;
                            }
                            return;
                        }
                        if (key === Qt.Key_Up && (inputField.text === "" || root._recall >= 0) && inputField.text.lastIndexOf("\n", inputField.cursorPosition - 1) === -1) {
                            root._recallPrompt(1);
                            event.accepted = true;
                        } else if (key === Qt.Key_Down && root._recall >= 0 && inputField.text.indexOf("\n", inputField.cursorPosition) === -1) {
                            root._recallPrompt(-1);
                            event.accepted = true;
                        } else if (event.matches(StandardKey.Copy) && inputField.selectedText === "" && AiAssistantService.selectedText !== "") {
                            AiAssistantService.copyText(AiAssistantService.selectedText);
                            event.accepted = true;
                        } else if (event.matches(StandardKey.Paste)) {
                            AiAssistantService.pasteClipboardImage();
                        }
                    }
                }
            }

            Text {
                anchors.fill: inputFlick
                text: Localization.t("aiAssistant.placeholder").arg(Config.aiAssistant.provider)
                color: Colors.md3.on_surface_variant
                font: inputField.font
                visible: inputField.text === ""
                opacity: 0.45
                elide: Text.ElideRight
            }
        }
    }

    CommandMenu {
        id: commandMenu
        open: root.menuOpen
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 10 + root.attachmentGap
        width: Math.max(root.width, 400)
        height: implicitHeight
        items: root.menuItems
        currentIndex: root.menuCurrent
        emptyText: Localization.t("aiAssistant.cmd_none")
        onHovered: i => root.menuIndex = i
        onPicked: i => root._activate(i)
    }

    Item {
        id: thinkingRow
        anchors.fill: parent
        opacity: 0

        LoadingSpinner {
            anchors.left: parent.left
            anchors.leftMargin: root.actionBtnMargin + (root.actionBtnSize - root.spinnerSize) / 2
            anchors.verticalCenter: parent.verticalCenter
            size: root.spinnerSize
            running: root.thinking
        }

        Text {
            id: hintText
            anchors.centerIn: parent
            text: hintMetrics.text
            font: hintMetrics.font
            color: Colors.md3.on_surface_variant
        }
    }

    MorphButton {
        id: actionBtn
        readonly property bool showStop: AiAssistantService.isStreaming && inputField.text.trim() === ""
        readonly property bool hasText: inputField.text.trim() !== ""
        anchors {
            right: parent.right
            rightMargin: root.actionBtnMargin
            bottom: parent.bottom
            bottomMargin: root.actionBtnMargin
        }
        size: root.actionBtnSize
        icon: actionBtn.showStop ? "stop" : "arrow-upward"
        filled: true
        iconSize: 18
        container: actionBtn.showStop ? Colors.md3.primary_container : (actionBtn.hasText ? Colors.md3.primary : Colors.md3.surface_container_high)
        content: actionBtn.showStop ? Colors.md3.on_primary_container : (actionBtn.hasText ? Colors.md3.on_primary : Colors.md3.on_surface_variant)
        onClicked: root._sendOrInterrupt()
    }
}
