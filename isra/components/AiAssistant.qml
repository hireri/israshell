pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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

            property var targetScreen: null

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
                return ["aiAssistant.welcome_" + bucket + "_1", "aiAssistant.welcome_" + bucket + "_2", "aiAssistant.welcome_" + bucket + "_3", "aiAssistant.welcome_" + bucket + "_4"];
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
                const name = CompositorService.focusedMonitor?.name;
                sessionRoot.targetScreen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0] ?? null;
            }

            PanelWindow {
                id: overlay
                screen: sessionRoot.targetScreen
                color: Qt.alpha(Colors.md3.background, overlay.isFresh ? 0.45 : 0.65)

                Behavior on color {
                    ColorAnimation {
                        duration: 420
                    }
                }
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:aiassistant"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                readonly property bool blurEnabled: Config.blurAllowed()

                BackgroundEffect.blurRegion: blurEnabled ? aiBlurRegion : null

                readonly property bool isFresh: AiAssistantService.history.length === 0 && !AiAssistantService.hasError && AiAssistantService.streamedAnswer === ""

                Region {
                    id: aiBlurRegion
                    item: glow
                }

                property bool revealed: false

                Component.onCompleted: {
                    Qt.callLater(() => overlay.revealed = true);
                    Qt.callLater(() => floatingPill.focusInput());
                }

                ShaderEffect {
                    id: glow
                    anchors.fill: parent
                    fragmentShader: Qt.resolvedUrl("../shaders/aiBackdrop.frag.qsb")

                    opacity: overlay.revealed ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 420
                            easing.type: Easing.OutQuint
                        }
                    }

                    property vector2d resolution: Qt.vector2d(width, height)

                    readonly property color hueLow: ColorUtils.hueShift(Colors.md3.primary, -120)
                    readonly property color hueMid: Colors.md3.primary
                    readonly property color hueHigh: ColorUtils.hueShift(Colors.md3.primary, 120)

                    property color colorA: hueMid
                    property color colorB: hueHigh
                    property color colorC: hueLow
                    property color dotColor: Colors.md3.on_surface

                    property real time: 0
                    property real gradientAngle: 0

                    property real saturation: 0.6
                    property real lightness: 0.05

                    property real edgeSigma: 11.8
                    property real edgeIntensity: 0.64

                    property real cellSize: 48
                    property real baseRadius: 1.3
                    property real maxAlpha: 0.6
                    property real noiseScale: 0.11
                    property real islandThreshold: 0.6
                    property real coreDepth: 0.5
                    property real minIslandCeiling: 0.5

                    property real glowOpacity: overlay.isFresh ? 1.0 : 0.4
                    property real dotOpacity: overlay.isFresh ? 1.0 : 0.0

                    Behavior on glowOpacity {
                        NumberAnimation {
                            duration: 750
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on dotOpacity {
                        NumberAnimation {
                            duration: 750
                            easing.type: Easing.OutCubic
                        }
                    }

                    SequentialAnimation on colorA {
                        loops: Animation.Infinite
                        running: overlay.visible
                        ColorAnimation { to: glow.hueHigh; duration: 4000 }
                        ColorAnimation { to: glow.hueLow; duration: 4000 }
                        ColorAnimation { to: glow.hueMid; duration: 4000 }
                    }
                    SequentialAnimation on colorB {
                        loops: Animation.Infinite
                        running: overlay.visible
                        ColorAnimation { to: glow.hueLow; duration: 4000 }
                        ColorAnimation { to: glow.hueMid; duration: 4000 }
                        ColorAnimation { to: glow.hueHigh; duration: 4000 }
                    }
                    SequentialAnimation on colorC {
                        loops: Animation.Infinite
                        running: overlay.visible
                        ColorAnimation { to: glow.hueMid; duration: 4000 }
                        ColorAnimation { to: glow.hueHigh; duration: 4000 }
                        ColorAnimation { to: glow.hueLow; duration: 4000 }
                    }

                    NumberAnimation on gradientAngle {
                        from: 0
                        to: 360
                        duration: 9000
                        loops: Animation.Infinite
                        running: overlay.visible
                    }

                    NumberAnimation on time {
                        from: 0
                        to: 3600
                        duration: 3600000
                        loops: Animation.Infinite
                        running: overlay.visible
                    }
                }


                Shortcut {
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

                    width: Math.min(parent.width - 96, 560)
                    height: heroText.implicitHeight

                    readonly property bool shouldShow: overlay.isFresh && floatingPill.revealed

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
                    readonly property bool shouldShow: !overlay.isFresh && floatingPill.revealed

                    clip: true
                    opacity: shouldShow ? 1.0 : 0.0
                    visible: opacity > 0
                    enabled: shouldShow
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    flickDeceleration: 4000
                    maximumFlickVelocity: 1200
                    contentWidth: width
                    contentHeight: chatColumn.height + 40

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

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
                                    text: AiAssistantService.displayedAnswer
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

                Rectangle {
                    id: chatScrollIndicator

                    readonly property real scrollRange: Math.max(chatFlick.contentHeight - chatFlick.height, 0)
                    readonly property real trackHeight: chatFlick.height - 16
                    readonly property bool lit: chatFlick.movingVertically || settleHold.running

                    visible: chatFlick.visible && scrollRange > 1
                    x: chatFlick.x + chatColumn.x + chatColumn.width + 12
                    width: 4
                    radius: 2
                    color: Colors.md3.on_surface_variant
                    height: Math.max(36, chatScrollIndicator.trackHeight * (chatFlick.height / Math.max(chatFlick.contentHeight, 1)))
                    y: chatFlick.y + 8 + (chatScrollIndicator.scrollRange > 0 ? (chatFlick.contentY / chatScrollIndicator.scrollRange) * (chatScrollIndicator.trackHeight - height) : 0)
                    opacity: chatScrollIndicator.lit ? 0.45 * chatFlick.opacity : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }

                    Timer {
                        id: settleHold
                        interval: 700
                    }

                    Connections {
                        target: chatFlick
                        function onMovingVerticallyChanged(): void {
                            if (!chatFlick.movingVertically)
                                settleHold.restart();
                        }
                    }
                }

                PromptPill {
                    id: floatingPill
                    isFresh: overlay.isFresh
                    isFocused: true
                    onAttachRequested: {
                        imagePicker.open();
                        AiAssistantService.close();
                    }
                }

                Item {
                    id: askScreenBtn
                    readonly property bool shouldShow: overlay.isFresh && floatingPill.revealed && !AiAssistantService.hasScreenAttachment && AiAssistantService.currentProviderSupportsVision()
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
                        onClicked: AiAssistantService.attachScreenshot(overlay.screen.name)
                    }
                }
            }
        }
    }
}
