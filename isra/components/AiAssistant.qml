pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Qt.labs.platform as Labs
import Quickshell
import Quickshell.Wayland
import qs.components.ai
import qs.style
import qs.services
import qs.icons

Item {
    id: root

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

            property var bubbleItems: []

            function registerBubble(item) {
                if (!item || sessionRoot.bubbleItems.includes(item))
                    return;
                sessionRoot.bubbleItems = [...sessionRoot.bubbleItems, item];
            }

            function unregisterBubble(item) {
                sessionRoot.bubbleItems = sessionRoot.bubbleItems.filter(i => i !== item);
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
                        Region { item: sessionRoot.bubbleItems[0] ?? null }
                        Region { item: sessionRoot.bubbleItems[1] ?? null }
                        Region { item: sessionRoot.bubbleItems[2] ?? null }
                        Region { item: sessionRoot.bubbleItems[3] ?? null }
                        Region { item: sessionRoot.bubbleItems[4] ?? null }
                        Region { item: sessionRoot.bubbleItems[5] ?? null }
                        Region { item: sessionRoot.bubbleItems[6] ?? null }
                        Region { item: sessionRoot.bubbleItems[7] ?? null }
                        Region { item: sessionRoot.bubbleItems[8] ?? null }
                        Region { item: sessionRoot.bubbleItems[9] ?? null }
                        Region { item: sessionRoot.bubbleItems[10] ?? null }
                        Region { item: sessionRoot.bubbleItems[11] ?? null }
                        Region { item: sessionRoot.bubbleItems[12] ?? null }
                        Region { item: sessionRoot.bubbleItems[13] ?? null }
                        Region { item: sessionRoot.bubbleItems[14] ?? null }
                        Region { item: sessionRoot.bubbleItems[15] ?? null }
                        Region { item: sessionRoot.bubbleItems[16] ?? null }
                        Region { item: sessionRoot.bubbleItems[17] ?? null }
                        Region { item: sessionRoot.bubbleItems[18] ?? null }
                        Region { item: sessionRoot.bubbleItems[19] ?? null }
                    }

                    onIsFocusedChanged: {
                        if (isFocused)
                            Qt.callLater(() => floatingPill.focusInput());
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
                            radius: 8
                            samples: 13
                            horizontalOffset: 0
                            verticalOffset: 2
                            color: Colors.md3.background
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
                                    onBubbleShown: item => sessionRoot.registerBubble(item)
                                    onBubbleHidden: item => sessionRoot.unregisterBubble(item)
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

                    PromptPill {
                        id: floatingPill
                        isFresh: overlay.isFresh
                        isFocused: overlay.isFocused
                        onAttachRequested: {
                            imagePicker.open();
                            AiAssistantService.close();
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
