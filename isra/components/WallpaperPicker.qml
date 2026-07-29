pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io

import qs.style
import qs.services
import qs.icons

Item {
    id: root

    required property var panelWindow

    readonly property bool isOpen: WallpaperService.isOpen && WallpaperService.openWindow === root.panelWindow
    property bool _popupVisible: false
    property var registry: null

    function toggleSelf(): void {
        WallpaperService.toggleFor(root.panelWindow);
    }

    function close(): void {
        if (root.isOpen)
            WallpaperService.close();
    }

    onIsOpenChanged: {
        if (isOpen) {
            _popupVisible = true;
            PanelService.opened(root, root.panelWindow.screen);
        } else {
            closeTimer.restart();
            PanelService.closed(root);
        }
    }

    Component.onCompleted: Qt.callLater(() => {
        if (root.registry && root.panelWindow?.screen)
            root.registry[root.panelWindow.screen.name] = root;
    })

    Timer {
        id: closeTimer
        interval: 380
        onTriggered: if (!root.isOpen)
            root._popupVisible = false
    }

    LazyLoader {
        id: popupLoader
        active: root._popupVisible

        Variants {
            id: popupVariants
            model: Quickshell.screens

            PanelWindow {
                id: popup

                required property ShellScreen modelData
                screen: modelData

                readonly property bool isOwnScreen: modelData === root.panelWindow?.screen

                visible: root._popupVisible

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.namespace: "quickshell-wallpaper-overlay"

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                color: "transparent"

                exclusionMode: ExclusionMode.Ignore

                property bool _ready: false
                Component.onCompleted: Qt.callLater(() => _ready = true)

                MouseArea {
                    anchors.fill: parent
                    onClicked: WallpaperService.close()
                }

                Component {
                    id: videoIconComp
                    MaterialIcon {
                        name: "video"
                        iconSize: 16
                    }
                }
                Component {
                    id: imageIconComp
                    MaterialIcon {
                        name: "image"
                        iconSize: 16
                    }
                }

                onVisibleChanged: {
                    if (visible && popup.isOwnScreen) {
                        breadcrumbs.updatePath(WallpaperService.currentDir);
                        searchInput.forceActiveFocus();
                    }
                }

                Connections {
                    target: WallpaperService
                    function onCurrentDirChanged() {
                        if (popup.isOwnScreen)
                            breadcrumbs.updatePath(WallpaperService.currentDir);
                    }
                    function onEntriesChanged() {
                        if (popup.isOwnScreen)
                            panel.rebuildModel(panel.searchQuery, WallpaperService.entries);
                    }
                    function onSortModeChanged() {
                        if (popup.isOwnScreen)
                            panel.rebuildModel(panel.searchQuery, WallpaperService.entries);
                    }
                }

                Item {
                    id: keyHandler

                    Keys.onEscapePressed: event => {
                        event.accepted = true;
                        WallpaperService.close();
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Slash) {
                            searchInput.forceActiveFocus();
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    id: panel
                    visible: popup.isOwnScreen

                    width: 1100
                    height: 600
                    radius: 20
                    color: Colors.md3.surface_container
                    border.width: 1
                    border.color: Colors.md3.outline_variant

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: Config.bar.position === 0 ? parent.top : undefined
                        bottom: Config.bar.position === 1 ? parent.bottom : undefined
                        topMargin: Config.bar.position === 0 ? root.panelWindow.implicitHeight + 8 : 8
                        bottomMargin: Config.bar.position === 1 ? root.panelWindow.implicitHeight + 8 : 8
                    }

                    property real slideY: (popup._ready && root.isOpen)
                        ? 0
                        : (Config.bar.position === 1
                            ? (height + root.panelWindow.implicitHeight + 8)
                            : -(height + root.panelWindow.implicitHeight + 8))

                    Behavior on slideY {
                        NumberAnimation {
                            duration: 360
                            easing.type: Easing.OutExpo
                        }
                    }

                    transform: Translate {
                        y: panel.slideY
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => mouse.accepted = true
                    }

                    readonly property int outerPad: 6
                    readonly property int headerH: 52
                    readonly property int gridPad: 8
                    readonly property int cardMargin: 4
                    readonly property int cols: 5
                    readonly property int innerRadius: 16
                    readonly property int scrollbarWidth: 8
                    readonly property int imageInset: 4
                    readonly property int textAreaH: 32
                    readonly property int pillH: 52
                    readonly property int pillMargin: 10

                    property string searchQuery: ""
                    property ListModel gridModel: ListModel {}

                    readonly property string thumbScript: "
                        set -e
                        video=\"$1\"
                        cache_dir=\"$HOME/.cache/isra/wallpaper-frames\"
                        mkdir -p \"$cache_dir\"
                        mtime=$(stat -c '%Y' \"$video\" 2>/dev/null || echo 0)
                        key=$(printf '%s:%s' \"$video\" \"$mtime\" | sha256sum | cut -d' ' -f1)
                        frame=\"$cache_dir/$key.png\"
                        if [ -s \"$frame\" ]; then printf '%s' \"$frame\"; exit 0; fi
                        ffmpeg -y -i \"$video\" -vf \"thumbnail,scale=320:-1\" -frames:v 1 \"$frame\" -loglevel error >/dev/null 2>&1 && printf '%s' \"$frame\"
                    "

                    QtObject {
                        id: thumbQueue
                        property int active: 0
                        readonly property int maxActive: 2
                        property var _pending: []

                        function request(startFn) {
                            if (active < maxActive) {
                                active++;
                                startFn();
                            } else {
                                _pending.push(startFn);
                            }
                        }

                        function release() {
                            active--;
                            if (_pending.length > 0) {
                                const next = _pending.shift();
                                active++;
                                next();
                            }
                        }
                    }

                    function isVideoPath(path) {
                        return /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path ?? "");
                    }

                    property string _lastRebuildKey: ""

                    function rebuildModel(query, entries) {
                        const q = (query ?? "").toLowerCase().trim();
                        const src = entries ?? WallpaperService.entries;
                        const filtered = q ? src.filter(e => e.name.toLowerCase().includes(q)) : src;
                        
                        const sorted = [...filtered].sort((a, b) => {
                            if (a.isDir !== b.isDir)
                                return a.isDir ? -1 : 1;
                            switch (WallpaperService.sortMode) {
                            case 1:
                                return b.name.localeCompare(a.name, undefined, {
                                    sensitivity: 'base'
                                });
                            case 2:
                                return (b.mtime ?? 0) - (a.mtime ?? 0);
                            case 3:
                                return (a.mtime ?? 0) - (b.mtime ?? 0);
                            default:
                                return a.name.localeCompare(b.name, undefined, {
                                    sensitivity: 'base'
                                });
                            }
                        });

                        const key = sorted.map(e => e.path).join("\u0001");
                        if (key === panel._lastRebuildKey)
                            return;
                        panel._lastRebuildKey = key;

                        grid.visible = false;
                        panel.gridModel.clear();
                        
                        panel.gridModel.append(sorted);
                        grid.visible = true;

                        if (root.isOpen && !q && WallpaperService.currentWall) {
                            Qt.callLater(() => {
                                for (let i = 0; i < panel.gridModel.count; i++) {
                                    const e = panel.gridModel.get(i);
                                    if (!e.isDir && e.path === WallpaperService.currentWall) {
                                        grid.currentIndex = i;
                                        grid.positionViewAtIndex(i, GridView.Center);
                                        break;
                                    }
                                }
                            });
                        }
                    }

                    onSearchQueryChanged: rebuildModel(panel.searchQuery, WallpaperService.entries)
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

                            SortBtn {
                                onBtnClicked: WallpaperService.cycleSortMode()
                            }
                            IconBtn {
                                btnIcon: "folder-open"
                                onBtnClicked: {
                                    WallpaperService.openFolder();
                                    WallpaperService.close();
                                }
                            }
                            IconBtn {
                                btnIcon: "settings"
                                onBtnClicked: {
                                    Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "settings", "open", "overview"])
                                    WallpaperService.close();
                                }
                            }
                            IconBtn {
                                btnIcon: "close"
                                onBtnClicked: WallpaperService.close()
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
                            WallpaperService.navigate(path);
                            grid.positionViewAtBeginning();
                        }

                        Timer {
                            id: searchDebounce
                            interval: 200
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

                                cacheBuffer: 200
                                flickableDirection: Flickable.VerticalFlick
                                boundsBehavior: Flickable.DragOverBounds
                                pixelAligned: true
                                reuseItems: true
                                model: panel.gridModel

                                footer: Item {
                                    width: 1
                                    height: panel.pillH + panel.pillMargin + panel.gridPad
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 20
                                    visible: panel.gridModel.count === 0

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        implicitWidth: kaoLbl.implicitWidth + 36
                                        height: 70
                                        radius: 35
                                        color: Colors.md3.primary_container

                                        Text {
                                            id: kaoLbl
                                            anchors.centerIn: parent
                                            text: WallpaperService.loading ? "(╭_•́)" : "(ᵕ—ᴗ—)?"
                                            color: Colors.md3.primary
                                            font.pixelSize: 38
                                            renderType: Text.NativeRendering
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: WallpaperService.loading ? "Loading..." : (panel.searchQuery !== "" ? "No results" : "No wallpapers found")
                                        color: Colors.md3.on_surface_variant
                                        font.pixelSize: 16
                                        font.family: Config.fontFamily
                                        renderType: Text.NativeRendering
                                        opacity: 0.45
                                    }
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

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        name: "light-mode"
                                        iconSize: 17
                                        color: Colors.md3.on_surface_variant
                                        opacity: WallpaperService.isDark ? 0 : 1
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        name: "dark-mode"
                                        iconSize: 17
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

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        name: "shuffle"
                                        iconSize: 17
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

                                Row {
                                    anchors {
                                        left: parent.left
                                        leftMargin: 14
                                        right: clearBtn.left
                                        rightMargin: 4
                                        verticalCenter: parent.verticalCenter
                                    }
                                    spacing: 6
                                    opacity: searchInput.text.length === 0 ? 0.5 : 0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 100
                                        }
                                    }

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "search"
                                        iconSize: 15
                                        color: Colors.md3.on_surface_variant
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Search..."
                                        font.pixelSize: 13
                                        font.family: Config.fontFamily
                                        renderType: Text.NativeRendering
                                        color: Colors.md3.on_surface_variant
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
                                        WallpaperService.close();
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

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        name: "close"
                                        iconSize: 12
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
        }

        component SortBtn: Rectangle {
            id: sBtn
            signal btnClicked

            readonly property int mode: WallpaperService.sortMode
            readonly property bool isAlphaMode: mode === 0 || mode === 1
            readonly property bool isDescending: mode === 1 || mode === 2
            readonly property color iconColor: sBtnMA.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant

            width: sortRow.implicitWidth + 16
            height: 34
            radius: 17
            color: sBtnMA.containsMouse ? Qt.alpha(Colors.md3.on_surface_variant, 0.15) : Qt.alpha(Colors.md3.on_surface_variant, 0.06)
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }

            Row {
                id: sortRow
                anchors.centerIn: parent
                spacing: 2

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: sBtn.isAlphaMode ? "sort-by-alpha" : "history"
                    iconSize: 15
                    color: sBtn.iconColor
                    transitionType: "crossfade-scale"
                }

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "arrow-upward"
                    iconSize: 15
                    color: sBtn.iconColor
                    rotation: sBtn.isDescending ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            MouseArea {
                id: sBtnMA
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: sBtn.btnClicked()
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

            MaterialIcon {
                anchors.centerIn: parent
                name: iBtn.btnIcon
                iconSize: 18
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

        component BreadCrumbBar: Item {
            id: bar
            readonly property int spacing: 3
            clip: true
            implicitWidth: bar._contentWidth
            implicitHeight: 32

            property var pathItems: []
            property int activeIndex: -1
            property string currentDir: ""
            property var navigateCallback: function (path) {
                WallpaperService.navigate(path);
            }

            property real _contentWidth: 0

            function relayout() {
                let x = 0;
                for (const c of bar.children) {
                    if (c._removing)
                        continue;
                    c.targetX = x;
                    x += c.width + bar.spacing;
                }
                bar._contentWidth = Math.max(0, x - bar.spacing);
            }

            function updatePath(newPath) {
                const home = Quickshell.env("HOME");
                currentDir = newPath;

                let newItems = [];
                if (newPath === home) {
                    newItems.push({
                        label: "",
                        icon: "home",
                        path: home
                    });
                } else if (newPath.startsWith(home)) {
                    newItems.push({
                        label: "",
                        icon: "home",
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

                let matchLen = 0;
                while (matchLen < bar.pathItems.length && matchLen < newItems.length && bar.pathItems[matchLen].path === newItems[matchLen].path)
                    matchLen++;

                const isBackNavWithinBranch = matchLen === newItems.length && newItems.length <= bar.pathItems.length;
                const nextItems = isBackNavWithinBranch ? bar.pathItems : bar.pathItems.slice(0, matchLen).concat(newItems.slice(matchLen));
                const newActiveIndex = newItems.length - 1;

                let structCommon = 0;
                while (structCommon < bar.pathItems.length && structCommon < nextItems.length && bar.pathItems[structCommon].path === nextItems[structCommon].path)
                    structCommon++;

                for (let i = 0; i < structCommon; i++) {
                    if (i < children.length) {
                        children[i].updateActive(i === newActiveIndex);
                        children[i].updateRightmost(i === nextItems.length - 1);
                    }
                }
                for (let i = bar.pathItems.length - 1; i >= structCommon; i--) {
                    if (i < children.length)
                        children[i].animateOut();
                }
                for (let i = structCommon; i < nextItems.length; i++) {
                    crumbComponent.createObject(bar, {
                        crumbData: nextItems[i],
                        isActive: i === newActiveIndex,
                        isRightmost: i === nextItems.length - 1,
                        indexInBar: i
                    });
                }

                bar.pathItems = nextItems;
                bar.activeIndex = newActiveIndex;
            }

            Component {
                id: crumbComponent

                Rectangle {
                    id: chip
                    property var crumbData
                    property bool isActive: false
                    property bool isRightmost: false
                    property int indexInBar: 0

                    property bool _removing: false
                    property real targetX: 0

                    readonly property bool hasIcon: !!crumbData?.icon

                    height: 32
                    width: hasIcon ? height : Math.max(isActive ? 48 : 38, chipLabel.implicitWidth + (isActive ? 24 : 16))
                    y: (bar.height - height) / 2
                    x: targetX
                    opacity: 0
                    scale: 0.82

                    readonly property real innerRadius: 6

                    topLeftRadius: isActive || indexInBar === 0 ? height / 2 : innerRadius
                    bottomLeftRadius: isActive || indexInBar === 0 ? height / 2 : innerRadius
                    topRightRadius: isActive || isRightmost ? height / 2 : innerRadius
                    bottomRightRadius: isActive || isRightmost ? height / 2 : innerRadius
                    
                    color: isActive ? Colors.md3.primary : (chipMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)

                    onWidthChanged: bar.relayout()

                    Behavior on topLeftRadius {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on bottomLeftRadius {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on topRightRadius {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on bottomRightRadius {
                        NumberAnimation {
                            duration: 180
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
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    function updateActive(active) {
                        isActive = active;
                    }
                    function updateRightmost(rightmost) {
                        isRightmost = rightmost;
                    }
                    function animateOut() {
                        chip._removing = true;
                        bar.relayout();
                        outAnim.start();
                    }

                    Component.onCompleted: {
                        bar.relayout();
                        inAnim.start();
                    }
                    Component.onDestruction: bar.relayout()

                    ParallelAnimation {
                        id: inAnim
                        NumberAnimation {
                            target: chip
                            property: "opacity"
                            to: 1
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: chip
                            property: "scale"
                            to: 1
                            duration: 200
                            easing.type: Easing.OutCubic
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

                    MaterialIcon {
                        visible: chip.hasIcon
                        anchors.centerIn: parent
                        name: chip.crumbData?.icon ?? ""
                        iconSize: 16
                        color: chip.isActive ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                    }

                    Text {
                        id: chipLabel
                        visible: !chip.hasIcon
                        anchors.centerIn: parent
                        text: chip.hasIcon ? "" : (chip.crumbData?.label ?? "")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        font.family: Config.fontFamily
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        color: chip.isActive ? Colors.md3.on_primary : Colors.md3.on_surface_variant
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
                        cursorShape: chip.isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !chip.isActive
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
            readonly property bool isVideo: !isDir && panel.isVideoPath(entryPath)

            property string thumbPath: ""
            property bool thumbRequested: false
            property int thumbAttempts: 0
            property string _thumbTargetPath: ""

            GridView.onReused: {
                card.thumbRequested = false;
                card.thumbPath = "";
                card.thumbAttempts = 0;
                card._thumbTargetPath = "";
            }

            function ensureThumbnail() {
                if (!card.isVideo || card.thumbRequested)
                    return;
                
                if (!card.GridView.view)
                    return;

                card.thumbRequested = true;
                card._thumbTargetPath = card.entryPath;
                thumbQueue.request(() => {
                    thumbProc.running = true;
                });
            }


            Timer {
                interval: 100
                running: card.isVideo && !card.thumbRequested
                repeat: true
                onTriggered: card.ensureThumbnail()
            }

            Process {
                id: thumbProc
                command: ["bash", "-c", panel.thumbScript, "_", card.entryPath]
                stdout: StdioCollector {
                    id: thumbCollector
                    onStreamFinished: {
                        if (card._thumbTargetPath !== card.entryPath) {
                            thumbQueue.release();
                            return;
                        }
                        const p = thumbCollector.text.trim();
                        if (p) {
                            card.thumbPath = p;
                        } else if (card.thumbAttempts < 1) {
                            card.thumbAttempts++;
                            card.thumbRequested = false;
                        }
                        thumbQueue.release();
                    }
                }
            }

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

                        MaterialIcon {
                            anchors.centerIn: parent
                            name: "folder"
                            iconSize: 20
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
                        source: {
                            if (card.isDir)
                                return "";
                            if (card.isVideo)
                                return card.thumbPath ? ("file://" + card.thumbPath) : "";
                            return "file://" + card.entryPath;
                        }
                        fillMode: Image.PreserveAspectCrop
                        
                        sourceSize.width: Math.round((grid.cellWidth - panel.cardMargin * 2) - panel.imageInset * 2)
                        sourceSize.height: Math.round(((grid.cellWidth - panel.cardMargin * 2) - panel.imageInset * 2) * 9 / 16)
                        
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

                        Loader {
                            anchors.centerIn: parent
                            sourceComponent: card.isVideo ? videoIconComp : imageIconComp
                            opacity: 0.25
                            onLoaded: {
                                if (item) item.iconSize = 22;
                            }
                        }
                    }

                    Rectangle {
                        visible: card.isVideo
                        anchors {
                            top: parent.top
                            left: parent.left
                            margins: 6
                        }
                        width: 22
                        height: 22
                        radius: 11
                        color: Qt.alpha(Colors.md3.surface_container_lowest, 0.85)
                        z: 2

                        Loader {
                            anchors.centerIn: parent
                            sourceComponent: videoIconComp
                            onLoaded: {
                                if (item) item.iconSize = 12;
                            }
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

                        MaterialIcon {
                            anchors.centerIn: parent
                            name: "check"
                            iconSize: 14
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
}