pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

import qs.style
import qs.services

Item {
    id: root

    required property var panelWindow

    implicitWidth: btnRect.implicitWidth
    implicitHeight: btnRect.implicitHeight

    property bool isOpen: false
    property bool _popupVisible: false

    onIsOpenChanged: {
        if (isOpen) {
            _popupVisible = true;
        } else {
            closeTimer.restart();
        }
    }

    GlobalShortcut {
        name: "openWallpaperPicker"
        description: "Toggle wallpaper picker"
        onPressed: {
            const screen = root.panelWindow.screen;
            if (!screen)
                return;
            if (Hyprland.focusedMonitor?.name !== screen.name)
                return;
            root.isOpen = !root.isOpen;
            if (root.isOpen)
                WallpaperService.openFor(root.panelWindow);
        }
    }

    Timer {
        id: closeTimer
        interval: 380
        onTriggered: if (!root.isOpen)
            root._popupVisible = false
    }

    HyprlandFocusGrab {
        windows: [popup]
        active: root.isOpen
        onCleared: root.isOpen = false
    }

    Rectangle {
        id: btnRect
        implicitWidth: 42
        implicitHeight: 32
        radius: 16
        color: root.isOpen ? Colors.md3.secondary_container : (Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high)
        opacity: WallpaperService.applying ? 0.4 : 1.0

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Text {
            anchors.centerIn: parent
            text: "󰸉"
            font.family: Config.fontFamily
            font.pixelSize: 19
            renderType: Text.NativeRendering
            color: root.isOpen ? Colors.md3.on_secondary_container : Colors.md3.on_surface
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: WallpaperService.applying ? Qt.ForbiddenCursor : Qt.PointingHandCursor
            enabled: !WallpaperService.applying
            onClicked: {
                root.isOpen = !root.isOpen;
                if (root.isOpen)
                    WallpaperService.openFor(root.panelWindow);
            }
        }
    }

    PopupWindow {
        id: popup
        visible: root._popupVisible

        anchor.window: root.panelWindow
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.rect: Qt.rect(Math.round((root.panelWindow.width - panel.width) / 2), 0, panel.width, root.panelWindow.height + panel.height + 16)

        implicitWidth: panel.width
        implicitHeight: root.panelWindow.height + panel.height + 16
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                breadcrumbs.updatePath(WallpaperService.currentDir);
                searchInput.focus = false;
                keyHandler.forceActiveFocus();
            }
        }

        Connections {
            target: WallpaperService
            function onCurrentDirChanged() {
                breadcrumbs.updatePath(WallpaperService.currentDir);
            }
            function onEntriesChanged() {
                panel.rebuildModel(panel.searchQuery, WallpaperService.entries);
            }
        }

        Item {
            id: keyHandler
            anchors.fill: parent

            Keys.onEscapePressed: event => {
                event.accepted = true;
                root.isOpen = false;
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Slash) {
                    searchInput.forceActiveFocus();
                    event.accepted = true;
                }
            }
        }

        MouseArea {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: root.panelWindow.height + 8
            onClicked: root.isOpen = false
        }

        Rectangle {
            id: panel

            readonly property int outerPad: 6
            readonly property int headerH: 52
            readonly property int gridPad: 8
            readonly property int cardMargin: 4
            readonly property int cols: 4
            readonly property int innerRadius: 16
            readonly property int scrollbarWidth: 8
            readonly property int imageInset: 4
            readonly property int textAreaH: 32
            readonly property int pillH: 52
            readonly property int pillMargin: 10

            property string searchQuery: ""

            property ListModel gridModel: ListModel {}

            function rebuildModel(query, entries) {
                const q = (query ?? "").toLowerCase().trim();
                const src = entries ?? WallpaperService.entries;
                const filtered = q ? src.filter(e => e.name.toLowerCase().includes(q)) : src;
                panel.gridModel.clear();
                for (const e of filtered)
                    panel.gridModel.append(e);
            }

            onSearchQueryChanged: rebuildModel(panel.searchQuery, WallpaperService.entries)

            width: 900
            height: 600
            radius: 20
            color: Colors.md3.surface_container
            border.width: 1
            border.color: Colors.md3.outline_variant

            y: root.isOpen ? root.panelWindow.height + 8 : -(height + 8)
            Behavior on y {
                NumberAnimation {
                    duration: 360
                    easing.type: Easing.OutExpo
                }
            }

            Item {
                id: topBar
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: panel.headerH

                BreadCrumbBar {
                    id: breadcrumbs
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    height: 32
                    navigateCallback: function (path) {
                        inner.navigateTo(path);
                    }
                }

                Row {
                    id: rightActions
                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 6

                    IconBtn {
                        btnIcon: "󰉋"
                        onBtnClicked: {
                            WallpaperService.openFolder();
                            root.isOpen = false;
                        }
                    }
                    IconBtn {
                        btnIcon: "󰅖"
                        onBtnClicked: root.isOpen = false
                    }
                }
            }

            Rectangle {
                id: inner
                anchors {
                    top: topBar.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: panel.outerPad
                    topMargin: panel.outerPad
                }
                radius: panel.innerRadius
                color: Colors.md3.surface_container_lowest
                clip: true

                function navigateTo(path) {
                    panel.searchQuery = "";
                    searchInput.text = "";
                    searchInput.focus = false;
                    keyHandler.forceActiveFocus();
                    WallpaperService.navigate(path);
                    grid.positionViewAtBeginning();
                }

                Timer {
                    id: searchDebounce
                    interval: 120
                    onTriggered: panel.searchQuery = searchInput.text
                }

                Item {
                    id: gridWrapper
                    anchors.fill: parent

                    GridView {
                        id: grid
                        anchors {
                            fill: parent
                            margins: panel.gridPad
                            rightMargin: panel.gridPad + panel.scrollbarWidth + 4
                            bottomMargin: 0
                        }

                        cellWidth: Math.floor(width / panel.cols)
                        cellHeight: {
                            const cw = Math.floor(width / panel.cols);
                            const cardW = cw - panel.cardMargin * 2;
                            const imgW = cardW - panel.imageInset * 2;
                            const imgH = Math.round(imgW * 9 / 16);
                            return panel.imageInset + imgH + panel.textAreaH + panel.cardMargin * 2;
                        }

                        cacheBuffer: 600
                        flickableDirection: Flickable.VerticalFlick
                        boundsBehavior: Flickable.DragOverBounds
                        pixelAligned: true
                        model: panel.gridModel

                        footer: Item {
                            width: 1
                            height: panel.pillH + panel.pillMargin + panel.gridPad
                        }

                        onVisibleChanged: {
                            if (!visible || !WallpaperService.currentWall)
                                return;
                            let idx = -1;
                            for (let i = 0; i < panel.gridModel.count; i++) {
                                const e = panel.gridModel.get(i);
                                if (!e.isDir && e.path === WallpaperService.currentWall) {
                                    idx = i;
                                    break;
                                }
                            }
                            if (idx >= 0) {
                                currentIndex = idx;
                                Qt.callLater(() => positionViewAtIndex(idx, GridView.Center));
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: panel.gridModel.count === 0
                            text: WallpaperService.loading ? "Loading…" : (panel.searchQuery !== "" ? "No results" : "No images found")
                            font.pixelSize: 14
                            font.family: Config.fontFamily
                            renderType: Text.NativeRendering
                            color: Colors.md3.on_surface_variant
                            opacity: 0.6
                        }

                        delegate: EntryCard {
                            required property var modelData
                            required property int index
                            entry: modelData
                            entryIndex: index
                            navigateCallback: function (path) {
                                inner.navigateTo(path);
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            id: vBar
                            width: panel.scrollbarWidth
                            anchors.right: parent.right
                            anchors.rightMargin: -panel.scrollbarWidth - 4
                            policy: ScrollBar.AsNeeded
                            snapMode: ScrollBar.NoSnap
                            stepSize: 0.08
                            contentItem: Rectangle {
                                implicitWidth: panel.scrollbarWidth
                                radius: panel.scrollbarWidth / 2
                                color: vBar.pressed ? Colors.md3.primary : Qt.alpha(Colors.md3.on_surface_variant, 0.5)
                            }
                            background: Item {
                                visible: false
                            }
                        }
                    }
                }

                Rectangle {
                    id: searchPill
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: panel.pillMargin
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: 400
                    height: panel.pillH
                    radius: panel.pillH / 2
                    color: Colors.md3.surface_container_high
                    z: 10

                    Row {
                        id: pillLeftBtns
                        anchors {
                            left: parent.left
                            leftMargin: 9
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 6

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: themeBtnMA.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰖙"
                                font.family: Config.fontFamily
                                font.pixelSize: 17
                                renderType: Text.NativeRendering
                                color: Colors.md3.on_surface_variant
                                opacity: WallpaperService.isDark ? 0 : 1
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "󰖔"
                                font.family: Config.fontFamily
                                font.pixelSize: 17
                                renderType: Text.NativeRendering
                                color: Colors.md3.on_surface_variant
                                opacity: WallpaperService.isDark ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            MouseArea {
                                id: themeBtnMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WallpaperService.isDark = !WallpaperService.isDark;
                                    WallpaperService.applyTheme();
                                }
                            }
                        }

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: randomBtnMA.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰒝"
                                font.family: Config.fontFamily
                                font.pixelSize: 17
                                renderType: Text.NativeRendering
                                color: Colors.md3.on_surface_variant
                            }

                            MouseArea {
                                id: randomBtnMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WallpaperService.randomize()
                            }
                        }
                    }

                    Rectangle {
                        id: inputPill
                        anchors {
                            left: pillLeftBtns.right
                            leftMargin: 9
                            right: parent.right
                            rightMargin: 9
                            verticalCenter: parent.verticalCenter
                        }
                        height: 36
                        radius: 18
                        color: Colors.md3.surface_container_low

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 14
                                right: clearBtn.left
                                rightMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                            text: "Search..."
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            renderType: Text.NativeRendering
                            color: Colors.md3.on_surface_variant
                            opacity: searchInput.text.length === 0 ? 0.5 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                        }

                        TextInput {
                            id: searchInput
                            anchors {
                                left: parent.left
                                leftMargin: 14
                                right: clearBtn.left
                                rightMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            color: Colors.md3.on_surface
                            selectionColor: Qt.alpha(Colors.md3.primary, 0.3)
                            selectedTextColor: Colors.md3.on_surface
                            clip: true

                            onTextChanged: searchDebounce.restart()

                            Keys.onEscapePressed: event => {
                                event.accepted = true;
                                root.isOpen = false;
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                acceptedButtons: Qt.NoButton
                            }
                        }

                        Rectangle {
                            id: clearBtn
                            anchors {
                                right: parent.right
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            width: 20
                            height: 20
                            radius: 10
                            opacity: searchInput.text.length > 0 ? 1 : 0
                            visible: opacity > 0
                            color: clearMA.containsMouse ? Qt.alpha(Colors.md3.on_surface_variant, 0.18) : "transparent"
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 100
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                renderType: Text.NativeRendering
                                color: Colors.md3.on_surface_variant
                            }
                            MouseArea {
                                id: clearMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            cursorShape: Qt.IBeamCursor
                            onClicked: searchInput.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    component IconBtn: Rectangle {
        id: iBtn
        property string btnIcon: ""
        signal btnClicked

        width: 34
        height: 34
        radius: 17
        color: iBtnMA.containsMouse ? Qt.alpha(Colors.md3.on_surface_variant, 0.15) : Qt.alpha(Colors.md3.on_surface_variant, 0.06)
        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }

        Text {
            anchors.centerIn: parent
            text: iBtn.btnIcon
            font.family: Config.fontFamily
            font.pixelSize: 18
            renderType: Text.NativeRendering
            color: iBtnMA.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        MouseArea {
            id: iBtnMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: iBtn.btnClicked()
        }
    }

    component BreadCrumbBar: Row {
        id: bar
        spacing: 4
        clip: true

        property var currentPathItems: []
        property string currentDir: ""
        property var navigateCallback: function (path) {
            WallpaperService.navigate(path);
        }

        function updatePath(newPath) {
            const home = Quickshell.env("HOME");
            let newItems = [];
            currentDir = newPath;

            if (newPath === home) {
                newItems.push({
                    label: "󰋜",
                    path: home
                });
            } else if (newPath.startsWith(home)) {
                newItems.push({
                    label: "󰋜",
                    path: home
                });
                let p = home;
                for (const part of newPath.slice(home.length).split("/").filter(Boolean)) {
                    p += "/" + part;
                    newItems.push({
                        label: part,
                        path: p
                    });
                }
            } else {
                let p = "";
                const parts = newPath.split("/").filter(Boolean);
                for (let i = 0; i < parts.length; i++) {
                    p += "/" + parts[i];
                    newItems.push({
                        label: parts[i],
                        path: p
                    });
                }
            }

            let common = 0;
            while (common < currentPathItems.length && common < newItems.length && currentPathItems[common].path === newItems[common].path)
                common++;

            for (let i = 0; i < common; i++) {
                if (i < children.length)
                    children[i].updateIsLast(i === newItems.length - 1);
            }
            for (let i = currentPathItems.length - 1; i >= common; i--) {
                if (i < children.length)
                    children[i].animateOut();
            }
            for (let i = common; i < newItems.length; i++) {
                crumbComponent.createObject(bar, {
                    crumbData: newItems[i],
                    isLast: i === newItems.length - 1,
                    indexInBar: i
                });
            }
            currentPathItems = newItems;
        }

        Component {
            id: crumbComponent

            Rectangle {
                id: chip
                property var crumbData
                property bool isLast: false
                property int indexInBar: 0

                height: 32
                radius: isLast ? height / 2 : 8
                width: Math.max(isLast ? 48 : 38, chipLabel.implicitWidth + (isLast ? 24 : 16))
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0
                scale: 0.82

                color: isLast ? Colors.md3.primary : (chipMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)

                Behavior on radius {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                function updateIsLast(last) {
                    isLast = last;
                }
                function animateOut() {
                    outAnim.start();
                }

                Timer {
                    interval: chip.indexInBar * 35
                    running: true
                    onTriggered: inAnim.start()
                }

                ParallelAnimation {
                    id: inAnim
                    NumberAnimation {
                        target: chip
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: chip
                        property: "scale"
                        to: 1
                        duration: 280
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }
                SequentialAnimation {
                    id: outAnim
                    ParallelAnimation {
                        NumberAnimation {
                            target: chip
                            property: "opacity"
                            to: 0
                            duration: 150
                        }
                        NumberAnimation {
                            target: chip
                            property: "scale"
                            to: 0.75
                            duration: 150
                        }
                    }
                    ScriptAction {
                        script: chip.destroy()
                    }
                }

                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: chip.crumbData?.label ?? ""
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: chip.isLast ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: chip.isLast ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !chip.isLast
                    onClicked: bar.navigateCallback(chip.crumbData.path)
                }
            }
        }
    }

    component EntryCard: Item {
        id: card

        property var entry: null
        property int entryIndex: 0
        property var navigateCallback: function (path) {
            WallpaperService.navigate(path);
        }

        readonly property bool isDir: entry?.isDir ?? false
        readonly property string entryPath: entry?.path ?? ""
        readonly property string entryName: entry?.name ?? ""
        readonly property bool isCurrent: !isDir && entryPath === WallpaperService.currentWall

        width: grid.cellWidth
        height: grid.cellHeight

        Rectangle {
            id: cardBody
            anchors {
                fill: parent
                margins: panel.cardMargin
            }
            radius: 12
            color: card.isCurrent ? Qt.alpha(Colors.md3.primary_container, 0.55) : (cardMA.containsMouse ? Colors.md3.surface_container : Colors.md3.surface_container_lowest)
            Behavior on color {
                ColorAnimation {
                    duration: 80
                }
            }

            border.width: card.isCurrent ? 2 : 0
            border.color: card.isCurrent ? Colors.md3.primary : "transparent"
            Behavior on border.color {
                ColorAnimation {
                    duration: 160
                }
            }
            Behavior on border.width {
                NumberAnimation {
                    duration: 160
                }
            }

            Column {
                visible: card.isDir
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 36
                    height: 36
                    radius: 10
                    color: Colors.md3.surface_container_high

                    Text {
                        anchors.centerIn: parent
                        text: "󰉋"
                        font.family: Config.fontFamily
                        font.pixelSize: 20
                        renderType: Text.NativeRendering
                        color: Colors.md3.on_surface_variant
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: cardBody.width - 16
                    text: card.entryName
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                    renderType: Text.NativeRendering
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                    color: Colors.md3.on_surface_variant
                }
            }

            ClippingRectangle {
                id: imageClip
                visible: !card.isDir
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: panel.imageInset
                    leftMargin: panel.imageInset
                    rightMargin: panel.imageInset
                }
                height: Math.round(width * 9 / 16)
                radius: 8
                color: "transparent"

                Image {
                    id: wallImg
                    anchors.fill: parent
                    source: card.isDir ? "" : "file://" + card.entryPath
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: Math.round(imageClip.width)
                    sourceSize.height: Math.round(imageClip.height)
                    asynchronous: true
                    smooth: false
                    cache: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                Rectangle {
                    visible: wallImg.status !== Image.Ready
                    anchors.fill: parent
                    color: Colors.md3.surface_container_highest

                    Text {
                        anchors.centerIn: parent
                        text: "󰋩"
                        font.family: Config.fontFamily
                        font.pixelSize: 22
                        renderType: Text.NativeRendering
                        color: Colors.md3.on_surface_variant
                        opacity: 0.25
                    }
                }

                Rectangle {
                    visible: card.isCurrent
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 6
                    }
                    width: 22
                    height: 22
                    radius: 11
                    color: Colors.md3.primary
                    z: 2

                    Text {
                        anchors.centerIn: parent
                        text: "󰄬"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        renderType: Text.NativeRendering
                        color: Colors.md3.on_primary
                    }
                }
            }

            Item {
                visible: !card.isDir
                anchors {
                    top: imageClip.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 6
                        rightMargin: 6
                    }
                    text: card.entryName.replace(/\.[^.]+$/, "")
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    color: card.isCurrent ? Colors.md3.primary : Colors.md3.on_surface_variant
                    Behavior on color {
                        ColorAnimation {
                            duration: 160
                        }
                    }
                }
            }

            MouseArea {
                id: cardMA
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    searchInput.focus = false;
                    keyHandler.forceActiveFocus();
                    if (card.isDir) {
                        card.navigateCallback(card.entryPath);
                    } else {
                        grid.currentIndex = card.entryIndex;
                        WallpaperService.selectWall(card.entryPath);
                    }
                }
            }
        }
    }
}
