import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import qs.style
import qs.services
import qs.windows.components
import qs.components
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
    readonly property string searchText: searchField.text
    readonly property bool resultsActive: searchText !== ""
    readonly property string searchQuery: searchField.query
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
        searchField.clear();
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
        searchField.clear();
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

    MouseArea {
        anchors.fill: parent
        onPressed: root.startSystemMove()
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: searchField.focusInput()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                id: sidebarPane
                Layout.preferredWidth: root.sidebarCollapsed ? 64 : 208
                Layout.fillHeight: true
                color: "transparent"
                clip: true

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                SidebarSearch {
                    id: searchField
                    anchors {
                        top: parent.top
                        topMargin: 8
                        left: parent.left
                        leftMargin: 8
                        right: parent.right
                        rightMargin: 8
                    }
                    placeholder: Localization.t("settingsWindow.search_settings")
                    collapsed: root.sidebarCollapsed
                    onToggled: root.sidebarCollapsed = !root.sidebarCollapsed
                }

                Flickable {
                    anchors {
                        top: searchField.bottom
                        topMargin: 8
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
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
                                        iconBg: Config.colorfulSidebar ? modelData.tint : Colors.md3.primary_container
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
                Layout.topMargin: 8
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

                            searchField.clear();
                            pageStack.replace(SettingsRegistry.pageInstance(root.currentPage));
                        }
                    }
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        topMargin: 8
                        right: parent.right
                        rightMargin: 8
                    }
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
