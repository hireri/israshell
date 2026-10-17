pragma ComponentBehavior: Bound

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
import "system"

FloatingWindow {
    id: root

    visible: true
    implicitWidth: 1000
    implicitHeight: 700
    title: Localization.t("systemApp.title")
    color: "transparent"

    property string currentPage: "overview"
    property bool sidebarCollapsed: false
    readonly property int collapseThreshold: 900
    property int prevWidth: width
    readonly property bool resultsActive: searchField.text !== ""

    onWidthChanged: {
        const wasBelow = prevWidth < collapseThreshold;
        const isBelow = width < collapseThreshold;
        if (wasBelow !== isBelow)
            sidebarCollapsed = isBelow;
        prevWidth = width;
    }

    Connections {
        target: SystemPages

        function onOpenPage(key) {
            root.open(key);
        }
    }

    function open(pageKey: string): void {
        const def = SystemPages.pageDef(pageKey);
        if (def === null) {
            console.warn("[SystemWindow] unknown page:", pageKey);
            return;
        }
        root.currentPage = def.key;
        searchField.clear();
    }

    function _pageUrl(key: string): url {
        return Qt.resolvedUrl("system/" + SystemPages.pageDef(key).source);
    }

    onResultsActiveChanged: {
        if (root.resultsActive)
            pageStack.replace(searchResultsComp);
        else if (pageStack.currentItem?.objectName === "searchResults")
            pageStack.replace(root._pageUrl(root.currentPage));
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: searchField.focusInput()
    }

    Rectangle {
        anchors.fill: parent
        color: Config.dim(Colors.md3.surface_container_low)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
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

                Text {
                    anchors.centerIn: parent
                    text: "󰮫"
                    font.pixelSize: 20
                    color: Colors.md3.on_secondary_container
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sidebarCollapsed = !root.sidebarCollapsed
                }
            }

            Text {
                id: titleLabel
                anchors.left: collapseButton.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: Localization.t("systemApp.title")
                font.family: Config.fontFamily
                font.pixelSize: 18
                font.weight: Font.Bold
                color: Colors.md3.on_surface
            }

            SearchField {
                id: searchField
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(420, parent.width - 400)
                placeholder: Localization.t("systemApp.search")
            }

            Rectangle {
                anchors.right: closeButton.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 20
                color: gearHover.containsMouse ? Config.dim(Colors.md3.surface_container_high) : Qt.alpha(Colors.md3.surface_container_high, 0)
                Behavior on color { ColorAnimation { duration: 120 } }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "settings"
                    iconSize: 18
                    color: Colors.md3.on_surface
                }

                MouseArea {
                    id: gearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "settings", "open", "overview"])
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
                Layout.preferredWidth: root.sidebarCollapsed ? 64 : 248
                Layout.fillHeight: true
                color: "transparent"
                clip: true

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
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
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                    ColumnLayout {
                        id: sidebarContent
                        width: parent.width
                        spacing: 0

                        Repeater {
                            model: SystemPages.groupIds

                            delegate: SidebarGroup {
                                id: sidebarGroup
                                required property int modelData

                                readonly property var groupPages: SystemPages.pages.filter(p => p.group === sidebarGroup.modelData)

                                Layout.fillWidth: true
                                Layout.bottomMargin: sidebarGroup.modelData < SystemPages.groupIds.length - 1 ? 8 : 0
                                currentPage: root.resultsActive ? "" : root.currentPage
                                collapsed: root.sidebarCollapsed
                                onNavigate: pageKey => root.open(pageKey)

                                Repeater {
                                    model: sidebarGroup.groupPages

                                    delegate: SidebarItem {
                                        id: sideItem
                                        required property var modelData

                                        pageKey: sideItem.modelData.key
                                        label: SystemPages.pageTitle(sideItem.modelData)
                                        sublabel: SystemPages.sublabel(sideItem.modelData.key)
                                        onClicked: root.open(sideItem.pageKey)

                                        MaterialIcon {
                                            name: sideItem.modelData.icon
                                            transitionType: sideItem.modelData.iconTransition
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

                    property int previousPage: -1
                    property int enterOffset: 48

                    Component.onCompleted: {
                        previousPage = SystemPages.pageIndex(root.currentPage);
                        pageStack.push(root._pageUrl(root.currentPage), {}, StackView.Immediate);
                    }

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
                                NumberAnimation { property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "y"; to: 0; duration: 260; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    replaceExit: Transition {
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
                    }

                    Connections {
                        target: root

                        function onCurrentPageChanged() {
                            const next = SystemPages.pageIndex(root.currentPage);
                            pageStack.enterOffset = next > pageStack.previousPage ? 48 : -48;
                            pageStack.previousPage = next;
                            pageStack.replace(root._pageUrl(root.currentPage));
                        }
                    }
                }
            }
        }
    }

    Component {
        id: searchResultsComp

        SearchPage {
            objectName: "searchResults"
            query: searchField.query
            onOpenPage: key => root.open(key)
        }
    }
}
