pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

import qs.style

PopupWindow {
    id: root

    required property Item dockRoot

    property Item targetButton: null
    property string targetKey: ""

    property var appToplevels: targetButton ? targetButton.toplevels : []

    onAppToplevelsChanged: {
        syncCardModel();
        if (visible && (!appToplevels || appToplevels.length === 0)) {
            hide();
        }
    }

    readonly property bool barOnTop: (Config && Config.bar) ? Config.bar.position === 0 : false
    readonly property int gap: 8

    visible: false
    implicitWidth: 900
    implicitHeight: 260
    color: "transparent"

    anchor.window: dockRoot.QsWindow.window
    anchor.rect: {
        let win = dockRoot.QsWindow.window;
        if (!win || !win.contentItem) return Qt.rect(0, 0, implicitWidth, implicitHeight);
        let topLeft = dockRoot.mapToItem(win.contentItem, 0, 0);
        return Qt.rect(
            topLeft.x - implicitWidth / 2 + dockRoot.width / 2,
            topLeft.y + (barOnTop ? dockRoot.height + gap : -gap - implicitHeight),
            implicitWidth,
            implicitHeight
        );
    }
    anchor.edges: Edges.Top | Edges.Left

    property bool animateIn: false
    property bool containsMouse: popupHover.hovered

    property Item nextTargetButton: null
    property bool contentVisible: true
    property real contentOpacity: contentVisible ? 1.0 : 0.0

    Behavior on contentOpacity {
        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
    }

    property bool useListTransitions: true

    readonly property Transition listAdd: Transition {
        NumberAnimation { property: "width"; from: 0; to: 180; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.4; to: 1.0; duration: 180; easing.type: Easing.OutBack }
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
    }

    readonly property Transition listRemove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "width"; to: 0; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; to: 0.0; duration: 180; easing.type: Easing.InBack }
            NumberAnimation { property: "opacity"; to: 0; duration: 140; easing.type: Easing.InCubic }
        }
    }

    readonly property Transition listDisplaced: Transition {
        NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic }
    }

    function request(button: Item): void {
        hideTimer.stop();
        
        if (closeTimer.running) {
            closeTimer.stop();
            root.animateIn = true;
            root.contentVisible = true;
        }

        if (visible) {
            show(button);
        } else {
            openTimer.stop();
            pendingButton = button;
            openTimer.restart();
        }
    }

    function release(button: Item): void {
        if (pendingButton === button) pendingButton = null;
        openTimer.stop();
        hideTimer.restart();
    }

    property var pendingButton: null

    Timer {
        id: openTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (root.pendingButton) root.show(root.pendingButton);
        }
    }

    Timer {
        id: hideTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (!root.containsMouse) root.hide();
        }
    }

    property double lastSwitchTime: 0

    Timer {
        id: restoreTransitionsTimer
        interval: 150
        repeat: false
        onTriggered: {
            root.useListTransitions = true;
        }
    }

    function show(button: Item): void {
        if (!button) return;
        let wasOpen = visible;
        
        if (wasOpen && targetButton === button) {
            return;
        }

        if (wasOpen && targetButton !== null) {
            let now = Date.now();
            let timeSinceLastSwitch = now - lastSwitchTime;
            lastSwitchTime = now;

            if (timeSinceLastSwitch < 250) {
                switchTimer.stop();
                restoreTransitionsTimer.stop();

                root.useListTransitions = false;
                root.targetButton = button;
                root.targetKey = button.itemKey;
                root.nextTargetButton = null;
                
                root.contentVisible = true;
                
                restoreTransitionsTimer.restart();
            } else {
                root.useListTransitions = false;
                restoreTransitionsTimer.stop();

                nextTargetButton = button;
                contentVisible = false;
                switchTimer.restart();
            }
        } else {
            root.lastSwitchTime = Date.now();
            targetButton = button;
            targetKey = button.itemKey;
            contentVisible = true;
            
            visible = true;
            animateIn = false;
            revealFallbackTimer.restart();
            revealIfReady();
        }
    }

    Timer {
        id: switchTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (root.nextTargetButton) {
                root.lastSwitchTime = Date.now();
                root.targetButton = root.nextTargetButton;
                root.targetKey = root.nextTargetButton.itemKey;
                root.nextTargetButton = null;
                
                root.contentVisible = true;
                restoreTransitionsTimer.restart();
            }
        }
    }

    function revealIfReady(): void {
        if (animateIn) return;
        if (allCardsReady) {
            revealFallbackTimer.stop();
            Qt.callLater(() => { animateIn = true; });
        }
    }
    onAllCardsReadyChanged: if (visible) revealIfReady()

    Timer {
        id: revealFallbackTimer
        interval: 300
        repeat: false
        onTriggered: root.revealNow()
    }

    function revealNow(): void {
        if (!animateIn) Qt.callLater(() => { animateIn = true; });
    }

    function hide(): void {
        animateIn = false;
        revealFallbackTimer.stop();
        openTimer.stop();
        pendingButton = null;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: {
            root.visible = false;
            root.targetButton = null;
            root.targetKey = "";
            root.contentVisible = true;
            root.useListTransitions = true;
            restoreTransitionsTimer.stop();
            scrollAnimation.stop();
            previewListView.contentX = 0;
            root.lastSwitchTime = 0;
        }
    }

    readonly property real targetWidth: {
        let count = cardModel.count;
        return count > 0 ? Math.max(0, count * 180 + (count - 1) * 10) : 0;
    }

    readonly property real cappedContentWidth: Math.min(targetWidth + 14, root.implicitWidth - 32)

    readonly property real targetX: {
        if (!targetButton) return 0;
        let win = dockRoot.QsWindow.window;
        if (!win || !win.contentItem) return 0;
        let buttonCenterInWindow = targetButton.width / 2;
        let buttonCenterInGlobal = targetButton.mapToItem(win.contentItem, buttonCenterInWindow, 0).x;
        let surfaceLeftInWindow = anchor.rect.x;
        
        let rawX = buttonCenterInGlobal - surfaceLeftInWindow - cappedContentWidth / 2;

        let minX = 8;
        let maxX = Math.max(minX, root.implicitWidth - 8 - cappedContentWidth);
        return Math.max(minX, Math.min(maxX, rawX));
    }

    readonly property bool allCardsReady: {
        if (cardModel.count === 0) return false;
        for (let i = 0; i < cardModel.count; i++) {
            let card = previewListView.contentItem.children[i];
            if (!card || !("contentReady" in card) || !card.contentReady) return false;
        }
        return true;
    }

    property var toplevelIds: new Map()
    property int nextId: 0

    function getToplevelId(tl: var): string {
        if (!tl) return "";
        if (!toplevelIds.has(tl)) {
            nextId++;
            toplevelIds.set(tl, "tl_" + nextId);
        }
        return toplevelIds.get(tl);
    }

    function syncWithModel(): void {
        syncCardModel();
    }

    ListModel { id: cardModel }

    function syncCardModel(): void {
        let items = root.appToplevels;
        if (!items) items = [];

        let activeToplevels = [];
        for (let i = 0; i < items.length; i++) {
            let tl = items[i];
            if (tl && typeof tl !== "undefined" && tl.toString() !== "null") {
                activeToplevels.push(tl);
            }
        }

        for (let [tl, id] of toplevelIds.entries()) {
            if (activeToplevels.indexOf(tl) === -1) {
                toplevelIds.delete(tl);
            }
        }

        let activeIds = activeToplevels.map(tl => getToplevelId(tl));

        for (let i = cardModel.count - 1; i >= 0; i--) {
            let id = cardModel.get(i)._id;
            if (activeIds.indexOf(id) === -1) {
                cardModel.remove(i);
            }
        }

        for (let targetIdx = 0; targetIdx < activeIds.length; targetIdx++) {
            let id = activeIds[targetIdx];
            let tl = activeToplevels[targetIdx];
            let currentIdx = -1;
            for (let i = 0; i < cardModel.count; i++) {
                if (cardModel.get(i)._id === id) { currentIdx = i; break; }
            }
            if (currentIdx === -1) {
                cardModel.insert(targetIdx, { _id: id, toplevel: tl });
            } else {
                cardModel.setProperty(currentIdx, "toplevel", tl);
                if (currentIdx !== targetIdx) {
                    cardModel.move(currentIdx, targetIdx, 1);
                }
            }
        }
    }
    Component.onCompleted: syncCardModel()

    Item {
        id: popupContent

        implicitWidth: root.targetWidth + 14
        implicitHeight: 137 + 14
        width: root.cappedContentWidth
        height: implicitHeight

        x: root.targetX
        y: root.barOnTop ? 0 : (root.implicitHeight - implicitHeight)

        Behavior on width {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on x {
            enabled: root.visible && root.animateIn
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        opacity: root.animateIn ? root.contentOpacity : 0
        scale: root.animateIn ? 1 : 0.92
        transformOrigin: root.barOnTop ? Item.Top : Item.Bottom

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: popupContainer
            anchors.fill: parent
            radius: 12
            color: Colors.md3.surface_container
            border.width: 1
            border.color: Qt.alpha(Colors.md3.outline, 0.2)

            HoverHandler {
                id: popupHover
                onHoveredChanged: {
                    if (hovered) {
                        hideTimer.stop();
                    } else {
                        hideTimer.restart();
                    }
                }
            }

            ListView {
                id: previewListView
                anchors.fill: parent
                anchors.margins: 7
                orientation: ListView.Horizontal
                interactive: contentWidth > width
                spacing: 10
                clip: true
                model: cardModel
                cacheBuffer: 200

                NumberAnimation {
                    id: scrollAnimation
                    target: previewListView
                    property: "contentX"
                    duration: 220
                    easing.type: Easing.OutCubic
                }

                MouseArea {
                    id: scrollHandler
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (event) => {
                        let delta = event.angleDelta.y;
                        let maxScroll = Math.max(0, previewListView.contentWidth - previewListView.width);
                        if (maxScroll <= 0) return;

                        let startPos = scrollAnimation.running ? scrollAnimation.to : previewListView.contentX;
                        let newTarget = Math.max(0, Math.min(maxScroll, startPos - (delta * 1.5)));

                        scrollAnimation.stop();
                        scrollAnimation.to = newTarget;
                        scrollAnimation.start();
                        event.accepted = true;
                    }
                }

                add: root.useListTransitions ? root.listAdd : null
                remove: root.useListTransitions ? root.listRemove : null
                displaced: root.useListTransitions ? root.listDisplaced : null

                delegate: Rectangle {
                    id: previewCard
                    required property string _id
                    required property var toplevel

                    property bool isClosing: false

                    readonly property bool contentReady: screencopyView.hasContent

                    width: implicitWidth
                    implicitWidth: 180
                    implicitHeight: 137
                    radius: 8
                    color: Qt.alpha(Colors.md3.background, 0.85)
                    border.width: toplevel && toplevel.activated ? 2 : 1
                    border.color: toplevel && toplevel.activated ? Colors.md3.primary : Qt.alpha(Colors.md3.outline, 0.15)
                    clip: true

                    Connections {
                        target: previewCard.toplevel ? previewCard.toplevel : null
                        ignoreUnknownSignals: true
                        function onClosed() {
                            previewCard.isClosing = true;
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 3

                        RowLayout {
                            id: titleRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16

                            Text {
                                text: (previewCard.toplevel && previewCard.toplevel.title) ? previewCard.toplevel.title : "Window"
                                font.pixelSize: 11
                                font.family: (Config && Config.fontFamily) ? Config.fontFamily : "sans-serif"
                                font.weight: Font.Medium
                                font.letterSpacing: 0.1
                                color: Colors.md3.on_surface_variant
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: closeMouse.containsMouse ? Qt.alpha(Colors.md3.on_surface_variant, 0.15) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.pixelSize: 9
                                    color: Colors.md3.on_surface_variant
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (previewCard.toplevel) {
                                            previewCard.isClosing = true;
                                            previewCard.toplevel.close();
                                        }
                                        if (root.appToplevels.length <= 1) {
                                            root.hide();
                                        }
                                    }
                                }
                            }
                        }

                        ClippingRectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 4
                            color: "transparent"

                            ScreencopyView {
                                id: screencopyView
                                anchors.fill: parent
                                captureSource: (!previewCard.isClosing && previewCard.toplevel) ? previewCard.toplevel : null
                                live: !previewCard.isClosing
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        if (previewCard.toplevel) {
                                            previewCard.isClosing = true;
                                            previewCard.toplevel.close();
                                        }
                                        if (root.appToplevels.length <= 1) {
                                            root.hide();
                                        }
                                    } else if (mouse.button === Qt.LeftButton) {
                                        if (previewCard.toplevel) {
                                            previewCard.toplevel.activate();
                                        }
                                        root.hide();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}