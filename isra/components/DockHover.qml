pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

import qs.style
import qs.services

Item {
    id: root

    required property Item dockRoot
    property DockModel dockModel: null

    width: 0
    height: 0

    readonly property Item host: root.dockRoot.QsWindow.window?.contentItem ?? null

    property bool isOpen: false

    readonly property rect maskRect: isOpen
        ? Qt.rect(popupContent.x, popupContent.y, popupContent.width, popupContent.height)
        : Qt.rect(0, 0, 0, 0)

    Binding {
        target: root.dockRoot.QsWindow.window
        property: "dockHoverRect"
        value: root.maskRect
        when: root.host !== null
    }

    property Item targetButton: null
    property string targetKey: ""

    property real latchedDockX: 0
    property real latchedDockY: 0
    property real latchedDockWidth: 0
    property real latchedDockHeight: 0
    property real latchedCentreX: 0
    property real latchedCentreY: 0

    function relayout(): void {
        if (!dockRoot || !host) return;

        const dockTopLeft = dockRoot.mapToItem(host, 0, 0);
        latchedDockX = dockTopLeft.x;
        latchedDockY = dockTopLeft.y;
        latchedDockWidth = dockRoot.width;
        latchedDockHeight = dockRoot.height;

        if (!targetButton) return;

        const centre = targetButton.mapToItem(host, targetButton.width / 2, targetButton.height / 2);
        latchedCentreX = centre.x;
        latchedCentreY = centre.y;
    }

    onTargetButtonChanged: relayout()
    onIsOpenChanged: if (isOpen) relayout()

    Timer {
        id: pinTrackTimer
        interval: 16
        repeat: true
        property int ticksLeft: 0
        onTriggered: {
            root.relayout();
            ticksLeft--;
            if (ticksLeft <= 0) stop();
        }
    }

    Connections {
        target: root.dockModel
        function onPinRequested(): void {
            root.relayout();
            pinTrackTimer.ticksLeft = 18;
            pinTrackTimer.restart();
        }
    }

    property var appToplevels: targetButton ? targetButton.toplevels : []

    onAppToplevelsChanged: {
        syncCardModel();
        if (isOpen && (!appToplevels || appToplevels.length === 0)) {
            hide();
        }
    }

    property int dockEdge: (Config && Config.bar && Config.bar.position === 0) ? 0 : 1
    readonly property bool sideEdge: dockEdge === 2 || dockEdge === 3
    readonly property bool barOnTop: dockEdge === 0
    readonly property int gap: 8

    readonly property real contentHeight: 137 + 14
    readonly property real maxContentWidth: 868
    readonly property int edgeMargin: 8

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

        if (isOpen) {
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

    property Item pendingButton: null

    function forget(button: Item): void {
        if (pendingButton === button)
            pendingButton = null;
        if (nextTargetButton === button)
            nextTargetButton = null;
        if (targetButton === button) {
            openTimer.stop();
            hideTimer.stop();
            switchTimer.stop();
            closeTimer.stop();
            targetButton = null;
            targetKey = "";
            animateIn = false;
            isOpen = false;
        }
    }

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
        let wasOpen = isOpen;
        
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
            
            isOpen = true;
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
    onAllCardsReadyChanged: if (isOpen) revealIfReady()

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
            root.isOpen = false;
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

    readonly property int cardCount: Math.max(cardModel.count, appToplevels ? appToplevels.length : 0)

    readonly property real targetWidth: {
        let count = cardCount;
        return count > 0 ? Math.max(0, count * 180 + (count - 1) * 10) : 0;
    }

    readonly property real cappedContentWidth: Math.min(
        targetWidth + 14,
        maxContentWidth,
        Math.max(180, (host ? host.width : 900) - edgeMargin * 2))

    readonly property real cardX: {
        if (!host) return 0;
        if (sideEdge)
            return dockEdge === 2
                ? (latchedDockX + latchedDockWidth + gap)
                : (latchedDockX - gap - cappedContentWidth);
        const raw = latchedCentreX - cappedContentWidth / 2;
        return Math.round(Math.max(edgeMargin, Math.min(raw, host.width - cappedContentWidth - edgeMargin)));
    }

    readonly property real cardY: {
        if (!host) return 0;
        if (!sideEdge)
            return barOnTop
                ? (latchedDockY + latchedDockHeight + gap)
                : (latchedDockY - gap - contentHeight);
        const raw = latchedCentreY - contentHeight / 2;
        return Math.round(Math.max(edgeMargin, Math.min(raw, host.height - contentHeight - edgeMargin)));
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

    function getIconSource(appId: string): string {
        if (!appId) return "image://icon/application-x-executable?fallback=application-x-executable";
        if (appId.startsWith("steam_app_")) {
            const steamId = appId.replace("steam_app_", "");
            return "image://icon/steam_icon_" + steamId + "?fallback=steam";
        }
        const entry = DesktopEntries.heuristicLookup(appId);
        if (entry && entry.icon) {
            return "image://icon/" + entry.icon + "?fallback=application-x-executable";
        }
        return "image://icon/" + appId + "?fallback=application-x-executable";
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

        parent: root.host
        z: 100
        visible: root.isOpen

        implicitWidth: root.targetWidth + 14
        implicitHeight: root.contentHeight
        width: root.cappedContentWidth
        height: implicitHeight

        x: root.cardX
        y: root.cardY

        Behavior on width {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on x {
            enabled: root.isOpen && root.animateIn
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            enabled: root.isOpen && root.animateIn
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        opacity: root.animateIn ? root.contentOpacity : 0
        scale: root.animateIn ? 1 : 0.92
        transformOrigin: {
            if (root.sideEdge)
                return root.dockEdge === 2 ? Item.Left : Item.Right;
            return root.barOnTop ? Item.Top : Item.Bottom;
        }

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
            color: Config.dim(Colors.md3.surface_container)
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

                    readonly property bool isHyprland: SystemInfo.compositor === "hyprland"
                    
                    readonly property bool contentReady: !isHyprland || screencopyView.hasContent || isClosing

                    width: implicitWidth
                    implicitWidth: 180
                    implicitHeight: 137
                    radius: 8
                    color: Qt.alpha(Colors.md3.background, 0.85)
                    border.width: (toplevel && (toplevel.activated || toplevel.is_focused || toplevel.focused)) ? 2 : 1
                    border.color: (toplevel && (toplevel.activated || toplevel.is_focused || toplevel.focused)) ? Colors.md3.primary : Qt.alpha(Colors.md3.outline, 0.15)
                    clip: true

                    function closeWindow(): void {
                        previewCard.isClosing = true;
                        if (previewCard.toplevel) {
                            if (typeof previewCard.toplevel.close === "function") {
                                previewCard.toplevel.close();
                            } else if (previewCard.toplevel.address) {
                                CompositorService.closeWindow(previewCard.toplevel.address);
                            }
                        }
                        if (root.appToplevels.length <= 1) {
                            root.hide();
                        }
                    }

                    function activateWindow(): void {
                        if (previewCard.toplevel) {
                            if (typeof previewCard.toplevel.activate === "function") {
                                previewCard.toplevel.activate();
                            } else if (previewCard.toplevel.address) {
                                CompositorService.focusWindow(previewCard.toplevel.address);
                            }
                        }
                        root.hide();
                    }

                    Connections {
                        target: previewCard.toplevel && typeof previewCard.toplevel === "object" ? previewCard.toplevel : null
                        ignoreUnknownSignals: true
                        function onClosed() {
                            previewCard.isClosing = true;
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        RowLayout {
                            id: titleRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16

                            Text {
                                text: (previewCard.toplevel && previewCard.toplevel.title) ? previewCard.toplevel.title : Localization.t("dockHover.window")
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
                                    onClicked: previewCard.closeWindow()
                                }
                            }
                        }

                        ClippingRectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            color: Qt.alpha(Colors.md3.surface_container_high, 0.4)

                            ScreencopyView {
                                id: screencopyView
                                anchors.fill: parent
                                captureSource: (previewCard.isHyprland && !previewCard.isClosing && previewCard.toplevel) ? previewCard.toplevel : null
                                live: previewCard.isHyprland && !previewCard.isClosing
                                visible: previewCard.isHyprland && screencopyView.hasContent
                            }

                            Item {
                                id: fallbackView
                                anchors.fill: parent
                                visible: !screencopyView.visible

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    IconImage {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 36
                                        implicitHeight: 36
                                        source: {
                                            let tl = previewCard.toplevel;
                                            let appId = tl ? (tl.appId ?? tl.app_id ?? tl.wayland?.appId ?? "") : "";
                                            return root.getIconSource(appId);
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.maximumWidth: 150
                                        text: (previewCard.toplevel && previewCard.toplevel.title) ? previewCard.toplevel.title : Localization.t("dockHover.window")
                                        font.pixelSize: 11
                                        font.family: (Config && Config.fontFamily) ? Config.fontFamily : "sans-serif"
                                        color: Colors.md3.on_surface_variant
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        previewCard.closeWindow();
                                    } else if (mouse.button === Qt.LeftButton) {
                                        previewCard.activateWindow();
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