pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.components.launcher
import qs.style
import qs.services

Item {
    id: root

    property var controller: null

    readonly property bool isOpen: controller ? controller.isOpen : false

    anchors.fill: parent

    property alias stack: _stack
    property alias closeAnim: _closeAnim
    property alias launcherInput: _launcherInput
    property alias launcherList: _launcherList

    readonly property var activeWidget: {
        switch (root.controller?.widgetType ?? "") {
            case "math":      return mathWidget;
            case "translate": return translateWidget;
            case "color":     return colorWidget;
            case "timestamp": return timestampWidget;
            case "define":    return defineWidget;
            case "whois":     return whoisWidget;
            case "kaomoji":   return kaomojiWidget;
            case "password":  return passwordWidget;
            case "weather":   return weatherWidget;
            case "wolfram":   return wolframWidget;
            default:          return null;
        }
    }

    readonly property bool widgetShown: activeWidget !== null && activeWidget.hasResult

    function _resetForOpen() {
        if (!root.controller)
            return;
        _closeAnim.stop();
        _stack.opacity = 1.0;
        _stack.scale = 1.0;
        _launcherInput.reset();
        if (root.controller._pendingPrefix !== "")
            _launcherInput.prefill(root.controller._pendingPrefix);
        Qt.callLater(() => {
            _launcherInput.forceInputFocus();
            _launcherList.resetToTop();
        });
    }

    Component.onCompleted: Qt.callLater(_resetForOpen)
    onIsOpenChanged: {
        if (root.isOpen)
            Qt.callLater(_resetForOpen);
        else
            _closeAnim.start();
    }

    Connections {
        target: root.controller
        function onModeChanged() {
            _launcherList.resetToTop();
        }
    }

    Item {
        id: _stack
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property real _restFraction: 0.3
        y: Math.round(root.height * _restFraction)

        width: {
            const controller = root.controller;
            if (!controller)
                return 420;
            if (controller.mode === "apps") {
                if (controller.widgetType === "kaomoji")
                    return 480;
                if (controller.widgetType === "wolfram") {
                    const len = root.activeWidget?.answerLength ?? 0;
                    if (len > 140)
                        return 640;
                    if (len > 45)
                        return 520;
                    return 420;
                }
                return 420;
            }
            if (controller.mode === "emoji")
                return 480;
            return 520;
        }

        Behavior on width {
            enabled: !(root.controller?._opening ?? false)
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        height: listCard.y + listCard.height
        transformOrigin: Item.Center

        opacity: 1.0
        scale: 1.0

        ParallelAnimation {
            id: _closeAnim
            NumberAnimation {
                target: _stack
                property: "opacity"
                to: 0.0
                duration: 100
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: _stack
                property: "scale"
                to: 0.80
                duration: 200
                easing.type: Easing.OutSine
            }
            onFinished: {
                if (root.controller)
                    root.controller._query = "";
                _launcherList.resetToTop();
            }
        }

        readonly property int gap: 8

        LauncherInput {
            id: _launcherInput
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            mode: root.controller?.mode ?? "apps"
            widgetType: root.controller?.widgetType ?? ""
            onQueryChanged: q => {
                _launcherList.resetToTop();
                if (root.controller)
                    root.controller._query = q;
            }
            onEscapePressed: root.controller?.close()
            onUpPressed: _launcherList.moveUp()
            onDownPressed: _launcherList.moveDown()
            onEnterPressed: _launcherList.activateCurrent()
            onTabPressed: _launcherList.moveDown()
        }

        ClippingRectangle {
            id: widgetCard
            anchors {
                top: _launcherInput.bottom
                topMargin: _stack.gap
                left: parent.left
                right: parent.right
            }
            radius: 20
            color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
            clip: true

            height: root.widgetShown ? (widgetInner.implicitHeight + 32) : 0
            opacity: root.widgetShown ? 1.0 : 0.0
            scale: root.widgetShown ? 1.0 : 0.80
            transformOrigin: Item.Top

            border.width: 1
            border.color: Colors.md3.outline_variant

            Behavior on height {
                enabled: !(root.controller?._opening ?? false)
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                enabled: !(root.controller?._opening ?? false)
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                enabled: !(root.controller?._opening ?? false)
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutExpo
                }
            }

            Item {
                id: widgetInner
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 16
                }
                implicitHeight: root.activeWidget ? root.activeWidget.implicitHeight : 0

                MathWidget {
                    id: mathWidget
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    visible: root.controller?.widgetType === "math"
                    query: root.controller?.modeQuery ?? ""
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                    onSwapRequested: q => {
                        _launcherInput.prefill(q);
                    }
                }

                TranslateWidget {
                    id: translateWidget
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    visible: root.controller?.widgetType === "translate"
                    sourceText: root.controller?.modeQuery ?? ""
                    targetLang: root.controller?.translateTarget ?? ""
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                }

                ColorWidget {
                    id: colorWidget
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    visible: root.controller?.widgetType === "color"
                    query: (root.controller?._query ?? "").trim()
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                }

                TimestampWidget {
                    id: timestampWidget
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    visible: root.controller?.widgetType === "timestamp"
                    query: (root.controller?._query ?? "").trim()
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                }

                DefineWidget {
                    id: defineWidget
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    visible: root.controller?.widgetType === "define"
                    word: root.controller?.widgetQuery ?? ""
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                }

                WhoisWidget {
                    id: whoisWidget
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    visible: root.controller?.widgetType === "whois"
                    subject: root.controller?.widgetQuery ?? ""
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                }

                KaomojiWidget {
                    id: kaomojiWidget
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    visible: root.controller?.widgetType === "kaomoji"
                    entries: root.controller?._kaomojiData ?? []
                    query: root.controller?.widgetQuery ?? ""
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                    onCategoryRequested: tag => {
                        _launcherInput.prefill("kao " + tag);
                    }
                }

                PasswordWidget {
                    id: passwordWidget
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    visible: root.controller?.widgetType === "password"
                    query: root.controller?.modeQuery ?? ""
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                }

                WeatherWidget {
                    id: weatherWidget
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    visible: root.controller?.widgetType === "weather"
                    query: root.controller?.widgetQuery ?? ""
                }

                WolframWidget {
                    id: wolframWidget
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    visible: root.controller?.widgetType === "wolfram"
                    question: root.controller?.widgetQuery ?? ""
                    onCopyResult: text => root.controller?.copyToClipboard(text)
                }
            }
        }

        ClippingRectangle {
            id: listCard
            anchors {
                top: widgetCard.bottom
                topMargin: _stack.gap
                left: parent.left
                right: parent.right
            }
            radius: 20
            color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
            clip: true

            border.width: 1
            border.color: Colors.md3.outline_variant

            readonly property int _max: root.controller?.mode === "clipboard" ? 600 : 400
            height: _launcherList.count === 0 ? 220 : Math.min(_max, Math.max(60, _launcherList.listContentHeight + 40))

            Behavior on height {
                enabled: !(root.controller?._opening ?? false)
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                anchors.fill: parent

                LauncherHeader {
                    id: listHeader
                    width: parent.width
                    mode: root.controller?.mode ?? "apps"
                    count: root.controller?.unifiedModel.values.length ?? 0
                    sortAlpha: root.controller?._sortAlpha ?? true
                    onClearRequested: {
                        clearProc.running = true;
                        clearClipboardProc.running = true;
                        if (root.controller)
                            root.controller._clipEntries = [];
                    }
                    onSortToggled: {
                        if (root.controller)
                            root.controller._sortAlpha = !root.controller._sortAlpha;
                        _launcherList.resetToTop();
                    }
                    onSkinToneChanged: index => _launcherList.skinToneIndex = index
                }

                Process {
                    id: clearProc
                    command: ["clipvault", "clear"]
                    running: false
                    onRunningChanged: if (!running && root.controller)
                        root.controller._reloadClipboard()
                }

                Process {
                    id: clearClipboardProc
                    command: ["wl-copy", "--clear"]
                    running: false
                }

                LauncherList {
                    id: _launcherList
                    width: parent.width
                    height: parent.height - listHeader.height
                    model: root.controller?.unifiedModel ?? null
                    mode: root.controller?.mode ?? "apps"
                    onItemActivated: entry => root.controller?._handleActivation(entry)
                    onActionActivated: root.controller?.close()
                }
            }
        }
    }
}
