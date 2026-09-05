import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import qs.style
import qs.services
import qs.windows.components
import qs.windows
import qs.icons

FloatingWindow {
    id: root

    visible: true
    implicitWidth: 960
    implicitHeight: 680
    title: Localization.t("settingsWindow.settings")
    color: "transparent"

    property string currentPage: "overview"
    property string searchText: ""
    readonly property bool resultsActive: searchText !== ""
    property string searchQuery: ""
    property bool sidebarCollapsed: false
    readonly property int collapseThreshold: 900

    onWidthChanged: {
        const wasBelow = prevWidth < collapseThreshold
        const isBelow = width < collapseThreshold
        if (wasBelow !== isBelow)
            sidebarCollapsed = isBelow
        prevWidth = width
    }
    property int prevWidth: width

    function open(pageKey) {
        if (SettingsPages.pageDef(pageKey) === null) {
            console.warn("[SettingsWindow] unknown page:", pageKey);
            return;
        }
        if (root.searchText !== "")
            searchInput.text = "";
        currentPage = pageKey;
    }

    onVisibleChanged: {
        if (visible) {
            const it = pageStack.currentItem;
            if (it) {
                it.opacity = 1;
                it.y = 0;
            }
            return;
        }
        for (let i = 0; i < pageStack.depth; i++) {
            const it = pageStack.get(i);
            if (it)
                it.opacity = 1;
        }
        searchDebounce.stop();
        searchText = "";
        searchQuery = "";
        pageStack.clear();
    }

    onResultsActiveChanged: _syncSearchStack()

    function _syncSearchStack() {
        if (root.resultsActive)
            pageStack.replace(searchResultsComp);
        else
            pageStack.replace(SettingsRegistry.pageInstance(root.currentPage));
    }

    Rectangle {
        anchors.fill: parent
        color: Config.dim(Colors.md3.surface_container_low)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            id: titleBar

            Layout.fillWidth: true
            Layout.preferredHeight: 56

            MouseArea {
                anchors.fill: parent
                onPressed: root.startSystemMove()
            }

            Rectangle {
                id: collapseButton
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 40
                radius: 16
                color: Colors.md3.secondary_container
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰮫"
                    font.pixelSize: 20
                    color: Colors.md3.on_secondary_container
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sidebarCollapsed = !root.sidebarCollapsed
                }
            }

            Text {
                id: titleLabel
                anchors.left: collapseButton.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: Localization.t("settingsWindow.settings")
                font.family: Config.fontFamily
                font.pixelSize: 18
                font.weight: Font.Bold
                color: Colors.md3.on_surface
            }

            Rectangle {
                id: searchPane
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(420, parent.width - 340)
                height: 36
                radius: 18
                color: Config.dim(Colors.md3.surface_container)

                Row {
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 6
                    opacity: searchInput.text.length === 0 ? 0.5 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "search"
                        iconSize: 15
                        color: Colors.md3.on_surface_variant
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Localization.t("settingsWindow.search_settings")
                        font.family: Config.fontFamily
                        font.pixelSize: 13
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
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    color: Colors.md3.on_surface
                    selectionColor: Qt.alpha(Colors.md3.primary, 0.3)
                    selectedTextColor: Colors.md3.on_surface
                    clip: true

                    onTextChanged: {
                        root.searchText = text;
                        if (text === "") {
                            searchDebounce.stop();
                            root.searchQuery = "";
                        } else {
                            searchDebounce.restart();
                        }
                    }
                    Keys.onEscapePressed: {
                        text = "";
                        focus = false;
                    }

                    Timer {
                        id: searchDebounce
                        interval: 150
                        onTriggered: root.searchQuery = searchInput.text
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
                        NumberAnimation { duration: 100 }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 80 }
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
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }

            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 20
                color: closeHover.containsMouse ? Config.dim(Colors.md3.surface_container_high) : Qt.alpha(Colors.md3.surface_container_high, 0) 
                Behavior on color { ColorAnimation { duration: 120 } }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "close"
                    iconSize: 18
                    color: Colors.md3.on_surface
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.visible = false
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                id: sidebarPane
                Layout.preferredWidth: root.sidebarCollapsed ? 64 : 248
                Layout.fillHeight: true
                color: "transparent"
                clip: true

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                Flickable {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    contentWidth: width
                    contentHeight: sidebarContent.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    ColumnLayout {
                        id: sidebarContent
                        width: parent.width
                        spacing: 0

                        Repeater {
                            model: 4

                            delegate: SidebarGroup {
                                id: sidebarGroup
                                required property int index

                                readonly property var groupPages: SettingsPages.pages.filter(p => p.group === index)

                                Layout.fillWidth: true
                                Layout.bottomMargin: index < 3 ? 8 : 0
                                currentPage: root.currentPage
                                collapsed: root.sidebarCollapsed
                                onNavigate: pageKey => root.currentPage = pageKey

                                Repeater {
                                    model: sidebarGroup.groupPages

                                    delegate: SidebarItem {
                                        required property var modelData

                                        pageKey: modelData.key
                                        label: SettingsPages.pageTitle(modelData)
                                        sublabel: Localization.t(modelData.sublabelKey)
                                        onClicked: root.currentPage = pageKey

                                        MaterialIcon {
                                            name: modelData.icon
                                            transitionType: modelData.iconTransition
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                        }
                    }
                }
            }

            Item {
                id: contentPane
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: 8
                Layout.bottomMargin: 8

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Config.dim(Colors.md3.surface)
                    clip: true
                }

                StackView {
                    id: pageStack
                    anchors.fill: parent
                    clip: true
                    initialItem: SettingsRegistry.pageInstance(root.currentPage)

                    property int previousPage: -1
                    property int enterOffset: 48

                    Component.onCompleted: previousPage = SettingsPages.pageIndex(root.currentPage)

                    onCurrentItemChanged: {
                        for (let i = 0; i < pageStack.depth; i++) {
                            const it = pageStack.get(i);
                            if (it)
                                it.active = (i === pageStack.depth - 1);
                        }
                    }

                    replaceEnter: Transition {
                        SequentialAnimation {
                            PropertyAction { property: "opacity"; value: 0 }
                            PropertyAction { property: "y"; value: pageStack.enterOffset }
                            PauseAnimation { duration: 150 }
                            ParallelAnimation {
                                NumberAnimation {
                                    property: "opacity"
                                    to: 1
                                    duration: 260
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                                }
                                NumberAnimation {
                                    property: "y"
                                    to: 0
                                    duration: 260
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                                }
                            }
                        }
                    }

                    replaceExit: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 150
                            easing.type: Easing.InCubic
                        }
                    }

                    Connections {
                        target: root
                        function onCurrentPageChanged() {
                            const prevIdx = pageStack.previousPage;
                            const nextIdx = SettingsPages.pageIndex(root.currentPage);
                            pageStack.enterOffset = nextIdx > prevIdx ? 48 : -48;
                            pageStack.previousPage = nextIdx;

                            searchDebounce.stop();
                            searchInput.text = "";
                            root.searchQuery = "";
                            pageStack.replace(SettingsRegistry.pageInstance(root.currentPage));
                        }
                    }
                }
            }
        }
    }

    Component {
        id: searchResultsComp
        SearchResultsPage {
            objectName: "searchResults"
            query: root.searchQuery
            onOpenPage: pageId => root.open(pageId)
        }
    }

    Component.onCompleted: {
        const page = Quickshell.env("QS_PAGE");
        if (page && SettingsPages.pageKeys.includes(page))
            root.currentPage = page;
    }
}
