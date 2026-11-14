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

    readonly property bool _mine: {
        const screen = root.QsWindow.window?.screen ?? null;
        const target = root.controller?._targetScreen ?? null;
        return screen === null || target === null || screen === target;
    }
    readonly property bool isOpen: (controller ? controller.isOpen : false) && _mine

    anchors.fill: parent

    property var shellWindow: null
    readonly property bool melt: docked && (shellWindow?.meltActive ?? false)
    anchors.topMargin: melt && Config.bar.position === 0 ? shellWindow.barHeight : 0
    anchors.bottomMargin: melt && Config.bar.position === 1 ? shellWindow.barHeight : 0
    clip: melt

    readonly property real meltTop: Math.max(root.y + _stack.y, root.y)
    readonly property real meltBottom: Math.min(root.y + _stack.y + _stack.height, root.y + root.height)
    readonly property real meltVisible: Math.max(0, meltBottom - meltTop)

    MeltReporter {
        win: root.shellWindow
        key: "launcher"
        rect: Qt.rect(root.x + _stack.x, root.meltTop, _stack.width, root.meltVisible)
        active: root.melt && (root.isOpen || root.meltVisible > 0.5)
    }

    Binding {
        target: _stack
        property: "opacity"
        value: Math.max(0, Math.min(1, ((1 - root._slide) - 0.5) * 2))
        when: root.melt
    }

    property alias stack: _stack
    property alias closeAnim: _closeAnim
    property alias launcherInput: _launcherInput
    property alias launcherList: _launcherList

    readonly property var activeWidget: {
        switch (root.controller?.widgetType ?? "") {
            case "math":      return mathLoader.item;
            case "translate": return translateLoader.item;
            case "color":     return colorLoader.item;
            case "timestamp": return timestampLoader.item;
            case "define":    return defineLoader.item;
            case "whois":     return whoisLoader.item;
            case "kaomoji":   return kaomojiLoader.item;
            case "password":  return passwordLoader.item;
            case "weather":   return weatherLoader.item;
            case "wolfram":   return wolframLoader.item;
            default:          return null;
        }
    }

    readonly property var _loaders: ({
            math: mathLoader,
            translate: translateLoader,
            color: colorLoader,
            timestamp: timestampLoader,
            define: defineLoader,
            whois: whoisLoader,
            kaomoji: kaomojiLoader,
            password: passwordLoader,
            weather: weatherLoader,
            wolfram: wolframLoader
        })

    function _wake() {
        const l = root._loaders[root.controller?.widgetType ?? ""];
        if (l)
            l.active = true;
    }

    readonly property bool widgetShown: activeWidget !== null && activeWidget.hasResult

    readonly property bool docked: Config.launcher.docked
    readonly property bool _gridMode: docked && (root.controller?.mode ?? "") === "emoji"
    readonly property var _nav: _gridMode ? _emojiGrid : _launcherList
    readonly property int _pad: docked ? 8 : 0

    readonly property string _zone: {
        const pos = Config.launcher.position;
        if (pos === "left" || pos === "center" || pos === "right")
            return pos;
        const b = Config.bar;
        if (b.left.includes("launcher"))
            return "left";
        if (b.right.includes("launcher"))
            return "right";
        return "center";
    }
    readonly property real _barInset: {
        if (melt)
            return 0;
        const mode = Config.bar.transparency === 2 ? (Config.bar.mode === 2 ? 2 : 0) : Config.bar.mode;
        return (mode === 2 ? 66 : 44) + (shellWindow?.panelGap ?? 12);
    }

    readonly property bool _showFrequent: docked && !widgetShown && (root.controller?.mode ?? "") === "apps" && (root.controller?._query ?? "") === "" && (root.controller?.frequentApps.length ?? 0) >= 3
    readonly property real _freqW: _showFrequent ? 252 : 0

    function _resetForOpen() {
        if (!root.controller)
            return;
        root._wake();
        _closeAnim.stop();
        _stack.opacity = 1.0;
        _stack.scale = 1.0;
        _launcherInput.reset();
        if (root.controller._pendingPrefix !== "")
            _launcherInput.prefill(root.controller._pendingPrefix);
        _launcherInput.snapTabs();
        Qt.callLater(() => {
            _launcherInput.forceInputFocus();
            _launcherList.resetToTop();
            _emojiGrid.resetToTop();
        });
    }

    property bool _ready: false
    Component.onCompleted: {
        if (root.isOpen)
            Qt.callLater(_resetForOpen);
        Qt.callLater(() => root._ready = true);
    }
    onDockedChanged: {
        _closeAnim.stop();
        dockResetTimer.stop();
        _stack.opacity = root.isOpen ? 1.0 : 0.0;
        _stack.scale = 1.0;
    }
    onIsOpenChanged: {
        if (root.isOpen)
            Qt.callLater(_resetForOpen);
        else if (root.docked)
            dockResetTimer.restart();
        else
            _closeAnim.start();
    }

    Timer {
        id: dockResetTimer
        interval: 360
        onTriggered: {
            if (root.isOpen || !root.controller)
                return;
            root.controller._query = "";
            _launcherList.resetToTop();
            _emojiGrid.resetToTop();
        }
    }

    property real _slide: (root._ready && root.isOpen) ? 0 : 1
    Behavior on _slide {
        enabled: root.docked
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutExpo
        }
    }

    readonly property real _bodyTarget: {
        if (!docked)
            return 0;
        const content = root.widgetShown ? (widgetInner.implicitHeight + 32) : listCard._contentH;
        return Math.min(360, Math.max(168, content));
    }
    property real _bodyH: _bodyTarget
    Behavior on _bodyH {
        enabled: root.docked && root.isOpen && root._slide === 0 && !(root.controller?._opening ?? false)
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: root.controller
        function onWidgetTypeChanged() {
            root._wake();
        }
        function onModeChanged() {
            _launcherList.resetToTop();
            _emojiGrid.resetToTop();
        }
    }

    Item {
        id: _stack

        readonly property real _restFraction: 0.3
        readonly property real _edge: (root.shellWindow?.frameInset ?? 0) + (root.shellWindow?.panelGap ?? 12)
        x: {
            if (!root.docked)
                return Math.round((root.width - width) / 2);
            if (root._zone === "left")
                return _edge;
            if (root._zone === "right")
                return root.width - width - _edge;
            return Math.round((root.width - width) / 2);
        }
        y: {
            if (!root.docked)
                return Math.round(root.height * _restFraction);
            const travel = (height + root._barInset + 8) * root._slide;
            return Config.bar.position === 1 ? root.height - height - root._barInset + travel : root._barInset - travel;
        }

        width: {
            if (root.docked)
                return 640;
            const controller = root.controller;
            if (!controller)
                return 460;
            if (controller.mode === "apps") {
                if (controller.widgetType === "kaomoji")
                    return 480;
                if (controller.widgetType === "wolfram") {
                    const len = root.activeWidget?.answerLength ?? 0;
                    if (len > 140)
                        return 640;
                    if (len > 45)
                        return 520;
                    return 460;
                }
                return 460;
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

        height: root.docked ? (root._pad + _launcherInput.height + gap + root._bodyH + root._pad) : (listCard.y + listCard.height)
        transformOrigin: root.docked ? (Config.bar.position === 1 ? Item.Bottom : Item.Top) : Item.Center


        opacity: 0.0
        scale: 1.0
        visible: root.docked ? root._slide < 0.999 : opacity > 0.01

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

        Rectangle {
            visible: root.docked && !root.melt
            anchors.fill: parent
            z: -1
            radius: 28
            color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
            border.width: 1
            border.color: Colors.md3.outline_variant
        }

        LauncherInput {
            id: _launcherInput
            embedded: root.docked
            gridNav: root._gridMode
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: root._pad
                leftMargin: root._pad
                rightMargin: root._pad
            }
            mode: root.controller?.mode ?? "apps"
            widgetType: root.controller?.widgetType ?? ""
            onQueryChanged: q => {
                _launcherList.resetToTop();
                if (root.controller)
                    root.controller._query = q;
            }
            onEscapePressed: root.controller?.close()
            onUpPressed: root._nav.moveUp()
            onDownPressed: root._nav.moveDown()
            onEnterPressed: root._nav.activateCurrent()
            onTabPressed: root._gridMode ? _emojiGrid.moveRight() : _launcherList.moveDown()
            onBacktabPressed: root._gridMode ? _emojiGrid.moveLeft() : _launcherList.moveUp()
            onLeftPressed: _emojiGrid.moveLeft()
            onRightPressed: _emojiGrid.moveRight()
            onPageUpPressed: root._nav.pageUp()
            onPageDownPressed: root._nav.pageDown()
            onDeletePressed: _launcherList.deleteCurrent()
            onFrequentRequested: index => {
                const app = root.controller?.frequentApps[index];
                if (app && root._freqW > 0)
                    root.controller._handleActivation({ type: "app", uid: "fav_" + app.id, entry: app });
            }
            sortAlpha: root.controller?._sortAlpha ?? true
            skinToneIndex: _launcherList.skinToneIndex
            canClear: (root.controller?._clipEntries.length ?? 0) > 0
            onSortToggled: {
                Config.update({ launcher: Object.assign({}, Config.launcher, { sections: !Config.launcher.sections }) });
                _launcherList.resetToTop();
            }
            onClearRequested: {
                clearProc.running = true;
                clearClipboardProc.running = true;
                if (root.controller)
                    root.controller._clipEntries = [];
            }
            onSkinToneCycled: _launcherList.skinToneIndex = (_launcherList.skinToneIndex + 1) % 6
        }

        ClippingRectangle {
            id: widgetCard
            anchors {
                top: _launcherInput.bottom
                topMargin: _stack.gap
                left: parent.left
                right: parent.right
                leftMargin: root._pad
                rightMargin: root._pad
            }
            radius: root.docked ? 20 : 28
            color: root.docked ? Qt.alpha(Colors.md3.surface_container_low, Config.blurOpacity) : Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
            clip: true

            visible: root.docked ? opacity > 0.01 : true
            height: root.docked ? root._bodyH : (root.widgetShown ? (widgetInner.implicitHeight + 32) : 0)
            opacity: root.widgetShown ? 1.0 : 0.0
            scale: root.widgetShown ? 1.0 : 0.80
            transformOrigin: Item.Top

            border.width: root.docked ? 0 : 1
            border.color: Colors.md3.outline_variant

            Behavior on height {
                enabled: !root.docked && !(root.controller?._opening ?? false)
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

                Loader {
                    id: mathLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "math"
                    sourceComponent: MathWidget {
                        query: root.controller?.modeQuery ?? ""
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                        onSwapRequested: q => {
                            _launcherInput.prefill(q);
                        }
                    }
                }

                Loader {
                    id: translateLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "translate"
                    sourceComponent: TranslateWidget {
                        sourceText: root.controller?.modeQuery ?? ""
                        targetLang: root.controller?.translateTarget ?? ""
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                    }
                }

                Loader {
                    id: colorLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "color"
                    sourceComponent: ColorWidget {
                        query: (root.controller?._query ?? "").trim()
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                    }
                }

                Loader {
                    id: timestampLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "timestamp"
                    sourceComponent: TimestampWidget {
                        query: (root.controller?._query ?? "").trim()
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                    }
                }

                Loader {
                    id: defineLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "define"
                    sourceComponent: DefineWidget {
                        word: root.controller?.widgetQuery ?? ""
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                    }
                }

                Loader {
                    id: whoisLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "whois"
                    sourceComponent: WhoisWidget {
                        subject: root.controller?.widgetQuery ?? ""
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                    }
                }

                Loader {
                    id: kaomojiLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "kaomoji"
                    sourceComponent: KaomojiWidget {
                        entries: root.controller?._kaomojiData ?? []
                        query: root.controller?.widgetQuery ?? ""
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                        onCategoryRequested: tag => {
                            _launcherInput.prefill("kao " + tag);
                        }
                    }
                }

                Loader {
                    id: passwordLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "password"
                    sourceComponent: PasswordWidget {
                        query: root.controller?.modeQuery ?? ""
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                    }
                }

                Loader {
                    id: weatherLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "weather"
                    sourceComponent: WeatherWidget {
                        query: root.controller?.widgetQuery ?? ""
                    }
                }

                Loader {
                    id: wolframLoader
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    active: false
                    visible: root.controller?.widgetType === "wolfram"
                    sourceComponent: WolframWidget {
                        question: root.controller?.widgetQuery ?? ""
                        onCopyResult: text => root.controller?.copyToClipboard(text)
                    }
                }
            }
        }

        ClippingRectangle {
            id: listCard
            anchors {
                top: root.docked ? _launcherInput.bottom : widgetCard.bottom
                topMargin: _stack.gap
                left: parent.left
                right: parent.right
                leftMargin: root._pad
                rightMargin: root._pad
            }
            radius: root.docked ? 20 : 28
            color: root.docked ? "transparent" : Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
            clip: true

            border.width: root.docked ? 0 : 1
            border.color: Colors.md3.outline_variant

            opacity: root.docked && root.widgetShown ? 0.0 : 1.0
            visible: root.docked ? opacity > 0.01 : !(root.widgetShown && _launcherList.count === 0)
            readonly property int _max: root.docked ? 360 : (root.controller?.mode === "clipboard" ? 600 : 448)
            readonly property real _contentH: root._gridMode ? _emojiGrid.contentHeight : _launcherList.listContentHeight
            readonly property real _inset: border.width * 2
            height: root.docked ? root._bodyH : (_launcherList.count === 0 ? 168 : Math.min(_max, Math.max(60, _contentH + _inset)))

            Behavior on opacity {
                enabled: root.docked && !(root.controller?._opening ?? false)
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                enabled: !root.docked && !(root.controller?._opening ?? false)
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                anchors.fill: parent

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
                    visible: !root._gridMode
                    width: parent.width - (root._freqW > 0 ? root._freqW + 8 : 0)
                    height: parent.height
                    model: root.controller?.unifiedModel ?? null
                    mode: root.controller?.mode ?? "apps"
                    onItemActivated: entry => root.controller?._handleActivation(entry)
                    onActionActivated: root.controller?.close()
                    onClipDeleteRequested: id => root.controller?.deleteClip(id)
                    busy: root.controller?.busy ?? false
                }

                EmojiGrid {
                    id: _emojiGrid
                    visible: root._gridMode
                    anchors.fill: parent
                    model: root._gridMode ? (root.controller?.unifiedModel ?? null) : null
                    skinToneIndex: _launcherList.skinToneIndex
                    onItemActivated: entry => root.controller?._handleActivation(entry)
                }

                Rectangle {
                    visible: root._freqW > 0
                    anchors {
                        top: parent.top
                        right: parent.right
                        bottom: parent.bottom
                    }
                    width: root._freqW
                    radius: 20
                    color: Qt.alpha(Colors.md3.surface_container_low, Config.blurOpacity)

                    FrequentGrid {
                        anchors.fill: parent
                        apps: root.controller?.frequentApps ?? []
                        onLaunchRequested: entry => root.controller?._handleActivation({ type: "app", uid: "fav_" + entry.id, entry: entry })
                    }
                }
            }
        }
    }
}
