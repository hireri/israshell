pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

import qs.style
import qs.services
import qs.icons
import qs.windows.components

Item {
    id: root

    property var controller: null

    readonly property bool isOpen: controller ? controller.isOpen : false

    anchors.fill: parent

    property bool _ready: false
    Component.onCompleted: {
        Qt.callLater(() => root._ready = true);
        root.syncUserPins();
    }

    onIsOpenChanged: {
        if (isOpen) {
            breadcrumbs.updatePath(WallpaperService.currentDir);
            searchInput.forceActiveFocus();
        }
    }

    readonly property string homeDir: Quickshell.env("HOME")

    readonly property string activePlace: {
        if (!panel.isLocal)
            return "";
        const dir = WallpaperService.currentDir;
        let best = "";
        for (const p of WallpaperService.fixedDirs.concat(WallpaperService.userPins)) {
            if ((dir === p || dir.startsWith(p + "/")) && p.length > best.length)
                best = p;
        }
        return best;
    }

    ListModel {
        id: userPinModel
    }

    function syncUserPins() {
        const list = WallpaperService.userPins;
        for (let i = userPinModel.count - 1; i >= 0; i--) {
            if (list.indexOf(userPinModel.get(i).path) < 0)
                userPinModel.remove(i);
        }
        for (let i = 0; i < list.length; i++) {
            if (i >= userPinModel.count)
                userPinModel.append({
                    path: list[i]
                });
            else if (userPinModel.get(i).path !== list[i])
                userPinModel.insert(i, {
                    path: list[i]
                });
        }
    }

    function pinLabel(path) {
        if (path === root.homeDir)
            return Localization.t("wallpaperPicker.place_home");
        const base = path.replace(/\/+$/, "").split("/").pop();
        return base || path;
    }

    function pinSublabel(path) {
        return path.startsWith(root.homeDir) ? "~" + path.slice(root.homeDir.length) : path;
    }

    function pinIcon(path) {
        if (path === root.homeDir)
            return "home";
        if (path === WallpaperService.randomDir)
            return "casino";
        if (path === WallpaperService.savedDir || path === root.homeDir + "/Downloads")
            return "download-for-offline";
        if (path === root.homeDir + "/Pictures")
            return "image";
        if (/wallpaper/i.test(path))
            return "panorama";
        return "folder";
    }

    Connections {
        target: WallpaperService
        function onUserPinsChanged() {
            root.syncUserPins();
        }
        function onCurrentDirChanged() {
            breadcrumbs.updatePath(WallpaperService.currentDir);
        }
        function onEntriesChanged() {
            panel.rebuildModel(panel.searchQuery, WallpaperService.entries);
        }
        function onSortModeChanged() {
            panel.rebuildModel(panel.searchQuery, WallpaperService.entries);
        }
        function onBrowseSortChanged() {
            panel.refetch();
        }
    }

    Connections {
        target: Config
        function onAllowNsfwChanged() {
            panel.refetch();
        }
    }

    Rectangle {
        id: panel

        width: 1100
        height: 600
        radius: 20
        color: Config.dim(Colors.md3.surface_container_low)
        border.width: 1
        border.color: Colors.md3.outline_variant

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: Config.bar.position === 0 ? parent.top : undefined
            bottom: Config.bar.position === 1 ? parent.bottom : undefined
            topMargin: Config.bar.position === 0
                ? ((root._ready && root.isOpen) ? (root.controller?.panelWindow.barHeight ?? 0) + 8 : -panel.height)
                : 8
            bottomMargin: Config.bar.position === 1
                ? ((root._ready && root.isOpen) ? (root.controller?.panelWindow.barHeight ?? 0) + 8 : -panel.height)
                : 8
        }

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 360
                easing.type: Easing.OutExpo
            }
        }
        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: 360
                easing.type: Easing.OutExpo
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        readonly property int outerPad: 6
        readonly property int topInset: 0
        readonly property int headerH: 52
        readonly property int railWidth: 200
        readonly property int railPad: 12

        function thumbWidth(cellW) {
            return Math.ceil((cellW - panel.cardMargin * 2 - panel.imageInset * 2) / 32) * 32;
        }
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

        property string mode: "local"
        readonly property bool isLocal: panel.mode === "local"
        property int browsePage: 1

        onModeChanged: {
            if (searchInput.text !== "")
                searchInput.text = "";
            searchDebounce.stop();
            panel.searchQuery = "";
            grid.positionViewAtBeginning();
            WallpaperService.resetBrowse();
            panel.browsePage = 1;
            if (panel.mode !== "local")
                WallpaperService.searchProvider(panel.mode, "", 1);
        }

        property real contentOpacity: 1
        property string _pendingMode: ""
        property string _pendingDir: ""

        property bool headerFades: false

        function requestMode(m, dir) {
            const targetDir = dir ?? "";
            if (m === panel.mode && (targetDir === "" || targetDir === WallpaperService.currentDir))
                return;
            panel.headerFades = (m === "local") !== (panel.mode === "local");
            panel._pendingMode = m;
            panel._pendingDir = targetDir;
            modeSwap.restart();
        }

        function _applyPending() {
            const m = panel._pendingMode;
            const d = panel._pendingDir;
            panel._pendingMode = "";
            panel._pendingDir = "";
            if (m && m !== panel.mode)
                panel.mode = m;
            if (d)
                inner.navigateTo(d);
        }

        SequentialAnimation {
            id: modeSwap
            NumberAnimation {
                target: panel
                property: "contentOpacity"
                to: 0
                duration: 130
                easing.type: Easing.InCubic
            }
            ScriptAction {
                script: panel._applyPending()
            }
            NumberAnimation {
                target: panel
                property: "contentOpacity"
                to: 1
                duration: 190
                easing.type: Easing.OutCubic
            }
        }

        function refetch() {
            if (panel.mode === "local")
                return;
            WallpaperService.resetBrowse();
            panel.browsePage = 1;
            grid.positionViewAtBeginning();
            WallpaperService.searchProvider(panel.mode, searchInput.text, 1);
        }

        function formatSize(bytes) {
            if (!bytes)
                return "";
            const mb = bytes / 1048576;
            return mb >= 1 ? mb.toFixed(1) + " MB" : Math.round(bytes / 1024) + " KB";
        }

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

            const key = sorted.map(e => e.path).join("");
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
            id: rail
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: panel.railPad
                topMargin: panel.topInset
                bottomMargin: panel.outerPad
            }
            width: panel.railWidth - panel.railPad * 2

            Item {
                id: railHeader
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: panel.headerH
                clip: true

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 6
                        rightMargin: 6
                        verticalCenter: parent.verticalCenter
                    }
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: Localization.t("wallpaperPicker.title")
                    font.family: Config.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                    color: Colors.md3.on_secondary_container
                }
            }

            Flickable {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: railHeader.bottom
                    bottom: parent.bottom
                }
                contentWidth: width
                contentHeight: railContent.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: railContent
                    width: parent.width
                    spacing: 0

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        spacing: 3

                        Repeater {
                            model: WallpaperService.fixedDirs

                            SidebarItem {
                                required property var modelData
                                required property int index

                                label: root.pinLabel(modelData)
                                sublabel: root.pinSublabel(modelData)
                                active: root.activePlace === modelData
                                topRadius: index === 0 ? 18 : 6
                                bottomRadius: index === WallpaperService.fixedDirs.length - 1 ? 18 : 6
                                onClicked: panel.requestMode("local", modelData)

                                MaterialIcon {
                                    name: root.pinIcon(modelData)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        spacing: 3
                        visible: userPinModel.count > 0

                        Repeater {
                            model: userPinModel

                            SidebarItem {
                                required property string path
                                required property int index

                                label: root.pinLabel(path)
                                sublabel: root.pinSublabel(path)
                                active: root.activePlace === path
                                topRadius: index === 0 ? 18 : 6
                                bottomRadius: index === userPinModel.count - 1 ? 18 : 6
                                onClicked: panel.requestMode("local", path)

                                MaterialIcon {
                                    name: root.pinIcon(path)
                                }
                            }
                        }
                    }

                    SidebarGroup {
                        Layout.fillWidth: true
                        currentPage: panel.isLocal ? -1 : (panel.mode === "konachan" ? 0 : 1)

                        SidebarItem {
                            page: 0
                            label: Localization.t("wallpaperPicker.konachan")
                            sublabel: Localization.t("wallpaperPicker.konachan_sub")
                            onClicked: panel.requestMode("konachan")
                            MaterialIcon {
                                name: "okonomiyaki"
                            }
                        }
                        SidebarItem {
                            page: 1
                            label: Localization.t("wallpaperPicker.wallhaven")
                            sublabel: Localization.t("wallpaperPicker.wallhaven_sub")
                            onClicked: panel.requestMode("wallhaven")
                            MaterialIcon {
                                name: "panorama"
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: topBar
            anchors {
                top: parent.top
                left: rail.right
                right: parent.right
                leftMargin: panel.railPad
                topMargin: panel.topInset
            }
            height: panel.headerH

            Item {
                id: headerContext
                anchors {
                    left: parent.left
                    right: localActions.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 10
                    rightMargin: 8
                }
                opacity: panel.headerFades ? panel.contentOpacity : 1

                BreadCrumbBar {
                    id: breadcrumbs
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    height: 24
                    visible: panel.isLocal
                    navigateCallback: function (path) {
                        panel.requestMode("local", path);
                    }
                }

                SettingChips {
                    id: sortChips
                    anchors {
                        left: parent.left
                        leftMargin: -14
                        verticalCenter: parent.verticalCenter
                    }
                    width: 210
                    compact: true
                    stack: false
                    isLast: true
                    visible: !panel.isLocal
                    options: [
                        {
                            label: Localization.t("wallpaperPicker.sort_top"),
                            value: "top"
                        },
                        {
                            label: Localization.t("wallpaperPicker.sort_new"),
                            value: "new"
                        },
                        {
                            label: Localization.t("wallpaperPicker.sort_random"),
                            value: "random"
                        }
                    ]
                    currentValue: WallpaperService.browseSort
                    onSelected: v => WallpaperService.browseSort = v
                }
            }

            Row {
                id: rightActions
                anchors {
                    right: parent.right
                    rightMargin: panel.railPad - 2
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6

                IconBtn {
                    btnIcon: "settings"
                    onBtnClicked: {
                        Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "settings", "open", "overview"]);
                        WallpaperService.close();
                    }
                }
                IconBtn {
                    btnIcon: "close"
                    onBtnClicked: WallpaperService.close()
                }
            }

            Row {
                id: localActions
                anchors {
                    right: rightActions.left
                    rightMargin: 6
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6
                opacity: panel.isLocal ? (panel.headerFades ? panel.contentOpacity : 1) : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }

                SortBtn {
                    onBtnClicked: WallpaperService.cycleSortMode()
                }
                IconBtn {
                    btnIcon: "keep"
                    btnFilled: WallpaperService.isPinned(WallpaperService.currentDir)
                    btnEnabled: !WallpaperService.isFixedDir(WallpaperService.currentDir)
                    onBtnClicked: WallpaperService.togglePin(WallpaperService.currentDir)
                }
                IconBtn {
                    btnIcon: "folder-open"
                    onBtnClicked: {
                        WallpaperService.openFolder();
                        WallpaperService.close();
                    }
                }
            }
        }

        Rectangle {
            id: inner
            anchors {
                top: topBar.bottom
                left: rail.right
                right: parent.right
                bottom: parent.bottom
                leftMargin: panel.railPad
                rightMargin: panel.outerPad
                bottomMargin: panel.outerPad
            }
            radius: panel.innerRadius
            color: Qt.alpha(Colors.md3.surface_container_lowest, Config.blurOpacity)
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
                onTriggered: {
                    if (panel.isLocal)
                        panel.searchQuery = searchInput.text;
                    else
                        panel.refetch();
                }
            }

            Item {
                id: gridWrapper
                anchors.fill: parent
                opacity: panel.contentOpacity

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
                    model: panel.isLocal ? panel.gridModel : WallpaperService.browseModel

                    onAtYEndChanged: {
                        if (atYEnd && !panel.isLocal && WallpaperService.browseModel.count > 0 && WallpaperService.browseHasMore && !WallpaperService.browseLoading) {
                            panel.browsePage++;
                            WallpaperService.searchProvider(panel.mode, searchInput.text, panel.browsePage);
                        }
                    }

                    footer: Item {
                        id: gridFooter
                        width: grid.width

                        readonly property bool showSpinner: !panel.isLocal && WallpaperService.browseLoading && WallpaperService.browseModel.count > 0

                        height: panel.pillH + panel.pillMargin + panel.gridPad + (gridFooter.showSpinner ? 48 : 0)
                        Behavior on height {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        LoadingSpinner {
                            anchors {
                                top: parent.top
                                topMargin: 12
                                horizontalCenter: parent.horizontalCenter
                            }
                            running: gridFooter.showSpinner
                            visible: running
                            size: 24
                        }
                    }

                    Column {
                        id: emptyCol
                        anchors.centerIn: parent
                        spacing: 20
                        visible: panel.isLocal ? panel.gridModel.count === 0 : WallpaperService.browseModel.count === 0

                        readonly property bool loading: panel.isLocal ? WallpaperService.loading : WallpaperService.browseLoading

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 70
                            height: 70

                            LoadingSpinner {
                                anchors.centerIn: parent
                                visible: emptyCol.loading
                                running: emptyCol.loading
                                size: 64
                                background: true
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                visible: !emptyCol.loading
                                width: kaoLbl.implicitWidth + 36
                                height: 70
                                radius: 35
                                color: Colors.md3.primary_container

                                Text {
                                    id: kaoLbl
                                    anchors.centerIn: parent
                                    text: "(ᵕ—ᴗ—)?"
                                    color: Colors.md3.primary
                                    font.pixelSize: 38
                                    renderType: Text.NativeRendering
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (emptyCol.loading)
                                    return Localization.t("wallpaperPicker.loading");
                                if (!panel.isLocal && WallpaperService.browseError)
                                    return Localization.t("wallpaperPicker.browse_error");
                                return panel.searchQuery !== "" || searchInput.text !== "" ? Localization.t("wallpaperPicker.no_results") : Localization.t("wallpaperPicker.no_wallpapers_found");
                            }
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 16
                            font.family: Config.fontFamily
                            renderType: Text.NativeRendering
                            opacity: 0.45
                        }
                    }

                    Component {
                        id: localDelegateComp
                        EntryCard {
                            required property var modelData
                            required property int index
                            entry: modelData
                            entryIndex: index
                            navigateCallback: function (path) {
                                panel.requestMode("local", path);
                            }
                        }
                    }

                    Component {
                        id: browseDelegateComp
                        BrowseCard {}
                    }

                    delegate: panel.isLocal ? localDelegateComp : browseDelegateComp

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
                        right: parent.right
                        rightMargin: 9
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
                            onClicked: WallpaperService.randomizeFrom(panel.mode)
                        }
                    }
                }

                Rectangle {
                    id: inputPill
                    anchors {
                        left: parent.left
                        leftMargin: 9
                        right: pillLeftBtns.left
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
                            name: panel.isLocal ? "search" : "image-search"
                            iconSize: 15
                            color: Colors.md3.on_surface_variant
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: panel.isLocal
                                ? Localization.t("wallpaperPicker.filter")
                                : Localization.t("wallpaperPicker.search") + " " + WallpaperService.providerName(panel.mode) + "..."
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
        property bool btnFilled: false
        property bool btnEnabled: true
        signal btnClicked

        width: 34
        height: 34
        radius: 17
        opacity: iBtn.btnEnabled ? 1 : 0.45
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
            filled: iBtn.btnFilled
            color: iBtn.btnFilled ? Colors.md3.primary : (iBtnMA.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        MouseArea {
            id: iBtnMA
            anchors.fill: parent
            enabled: iBtn.btnEnabled
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: iBtn.btnClicked()
        }
    }

    component BreadCrumbBar: Item {
        id: bar
        readonly property int spacing: 2
        clip: true
        implicitWidth: bar._contentWidth
        implicitHeight: 24

        property var pathItems: []
        property int activeIndex: -1
        property string currentDir: ""
        required property var navigateCallback

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
                if (i < children.length)
                    children[i].updateActive(i === newActiveIndex);
            }
            for (let i = bar.pathItems.length - 1; i >= structCommon; i--) {
                if (i < children.length)
                    children[i].animateOut();
            }
            for (let i = structCommon; i < nextItems.length; i++) {
                crumbComponent.createObject(bar, {
                    crumbData: nextItems[i],
                    isActive: i === newActiveIndex,
                    indexInBar: i
                });
            }

            bar.pathItems = nextItems;
            bar.activeIndex = newActiveIndex;
        }

        Component {
            id: crumbComponent

            Item {
                id: crumb
                property var crumbData
                property bool isActive: false
                property int indexInBar: 0

                property bool _removing: false
                property real targetX: 0

                readonly property bool hasIcon: !!crumbData?.icon
                readonly property bool showSeparator: indexInBar > 0
                readonly property color tone: crumb.isActive ? Colors.md3.on_surface : (crumbMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                height: bar.height
                width: crumbRow.implicitWidth
                y: 0
                x: targetX
                opacity: 0
                scale: 0.92
                transformOrigin: Item.Left

                onWidthChanged: bar.relayout()

                function updateActive(active) {
                    isActive = active;
                }
                function animateOut() {
                    crumb._removing = true;
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
                        target: crumb
                        property: "opacity"
                        to: 1
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: crumb
                        property: "scale"
                        to: 1
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
                SequentialAnimation {
                    id: outAnim
                    ParallelAnimation {
                        NumberAnimation {
                            target: crumb
                            property: "opacity"
                            to: 0
                            duration: 120
                        }
                        NumberAnimation {
                            target: crumb
                            property: "scale"
                            to: 0.85
                            duration: 120
                        }
                    }
                    ScriptAction {
                        script: crumb.destroy()
                    }
                }

                Row {
                    id: crumbRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    MaterialIcon {
                        visible: crumb.showSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron-right"
                        iconSize: 13
                        transitionType: "none"
                        color: Colors.md3.outline
                    }

                    MaterialIcon {
                        visible: crumb.hasIcon
                        anchors.verticalCenter: parent.verticalCenter
                        name: crumb.crumbData?.icon ?? ""
                        iconSize: 15
                        color: crumb.tone
                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }
                        }
                    }

                    Text {
                        id: crumbLabel
                        visible: !crumb.hasIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: crumb.hasIcon ? "" : (crumb.crumbData?.label ?? "")
                        font.pixelSize: 12
                        font.weight: crumb.isActive ? Font.DemiBold : Font.Medium
                        font.family: Config.fontFamily
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        color: crumb.tone
                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }
                        }
                    }
                }

                MouseArea {
                    id: crumbMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: crumb.isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !crumb.isActive
                    onClicked: bar.navigateCallback(crumb.crumbData.path)
                }
            }
        }
    }

    component EntryCard: Item {
        id: card

        property var entry: null
        property int entryIndex: 0
        required property var navigateCallback

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
            color: card.isCurrent ? Qt.alpha(Colors.md3.primary_container, 0.55) : (cardMA.containsMouse ? Qt.alpha(Colors.md3.surface_container, Config.blurOpacity) : Qt.alpha(Colors.md3.surface_container_lowest, Config.blurOpacity))
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
                    color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

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

                    sourceSize.width: panel.thumbWidth(grid.cellWidth)
                    sourceSize.height: Math.round(panel.thumbWidth(grid.cellWidth) * 9 / 16)

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
                    color: Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: card.isVideo ? "video" : "image"
                        iconSize: 22
                        transitionType: "none"
                        color: Colors.md3.on_surface_variant
                        opacity: 0.25
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

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "video"
                        iconSize: 12
                        transitionType: "none"
                        color: Colors.md3.on_surface_variant
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

    component BrowseCard: Item {
        id: bcard
        required property var modelData

        readonly property string itemId: String(bcard.modelData?.id ?? "")
        readonly property bool hovered: bcardMA.containsMouse || saveMA.containsMouse
        readonly property bool pending: WallpaperService.pendingDownloads[bcard.itemId] === true
        readonly property bool saved: WallpaperService.savedItems[bcard.itemId] !== undefined
        readonly property int imgW: bcard.modelData?.width ?? 0
        readonly property int imgH: bcard.modelData?.height ?? 0

        width: grid.cellWidth
        height: grid.cellHeight

        Rectangle {
            id: bcardBody
            anchors {
                fill: parent
                margins: panel.cardMargin
            }
            radius: 12
            color: bcard.hovered ? Qt.alpha(Colors.md3.surface_container, Config.blurOpacity) : Qt.alpha(Colors.md3.surface_container_lowest, Config.blurOpacity)
            Behavior on color {
                ColorAnimation {
                    duration: 80
                }
            }

            ClippingRectangle {
                id: bimageClip
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
                    id: bwallImg
                    anchors.fill: parent
                    source: bcard.modelData?.thumb ?? ""
                    fillMode: Image.PreserveAspectCrop
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
                    visible: bwallImg.status !== Image.Ready
                    anchors.fill: parent
                    color: Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "image"
                        iconSize: 22
                        transitionType: "none"
                        color: Colors.md3.on_surface_variant
                        opacity: 0.25
                    }
                }

                Rectangle {
                    id: saveBtn
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 6
                    }
                    width: 24
                    height: 24
                    radius: 12
                    z: 3
                    opacity: (bcard.saved || bcard.hovered) && !bcard.pending ? 1 : 0
                    visible: opacity > 0
                    color: bcard.saved
                        ? Colors.md3.primary
                        : (saveMA.containsMouse ? Colors.md3.surface_container_highest : Qt.alpha(Colors.md3.surface_container_lowest, 0.88))

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: bcard.saved ? "check" : "arrow-downward"
                        iconSize: 14
                        transitionType: "crossfade-scale"
                        color: bcard.saved ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        id: saveMA
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !bcard.saved && !bcard.pending
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.saveBrowseItem(bcard.modelData, panel.mode, false)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    z: 4
                    visible: bcard.pending
                    color: Qt.alpha(Colors.md3.surface_container_lowest, 0.65)

                    LoadingSpinner {
                        anchors.centerIn: parent
                        running: bcard.pending
                        size: 40
                        background: true
                    }
                }
            }

            Item {
                anchors {
                    top: bimageClip.bottom
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
                    text: {
                        if (bcard.imgW <= 0 || bcard.imgH <= 0)
                            return "";
                        const size = panel.formatSize(bcard.modelData?.size ?? 0);
                        return bcard.imgW + " × " + bcard.imgH + (size ? "  ·  " + size : "");
                    }
                    font.pixelSize: 11
                    font.family: Config.fontFamily
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    color: Colors.md3.on_surface_variant
                    opacity: 0.7
                }
            }

            MouseArea {
                id: bcardMA
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                enabled: !bcard.pending && !WallpaperService.applying
                onClicked: WallpaperService.saveBrowseItem(bcard.modelData, panel.mode, true)
            }
        }
    }
}
