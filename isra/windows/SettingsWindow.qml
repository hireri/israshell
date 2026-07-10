import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.style
import qs.windows.components
import qs.windows
import qs.icons

FloatingWindow {
    id: root

    visible: true
    implicitWidth: 960
    implicitHeight: 680
    title: "Settings"
    color: Colors.md3.background

    readonly property int pageOverview: 0
    readonly property int pageNetwork: 1
    readonly property int pageBar: 2
    readonly property int pageClock: 3
    readonly property int pageDisplay: 4
    readonly property int pageSound: 5
    readonly property int pageLocale: 6
    readonly property int pageSystem: 7

    property int currentPage: pageOverview
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

    function open(page) {
        currentPage = page;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: root.sidebarCollapsed ? 72 : 248
            Layout.fillHeight: true
            color: Colors.md3.surface_container_low
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
                    margins: 12
                }
                contentWidth: width
                contentHeight: sidebarContent.implicitHeight
                clip: true
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: sidebarContent
                    width: parent.width
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        height: 48
                        Layout.bottomMargin: 14

                        Text {
                            anchors.centerIn: parent
                            text: "Settings"
                            font.family: Config.fontFamily
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: Colors.md3.on_secondary_container
                            opacity: root.sidebarCollapsed ? 0 : 1
                            Behavior on opacity {
                                NumberAnimation { duration: 120 }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
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
                                id: toggleHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sidebarCollapsed = !root.sidebarCollapsed
                            }
                        }
                    }

                    SidebarGroup {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        currentPage: root.currentPage
                        collapsed: root.sidebarCollapsed
                        onNavigate: p => root.currentPage = p

                        SidebarItem {
                            page: root.pageOverview
                            label: "Overview"
                            sublabel: "Wallpaper, appearance"
                            onClicked: root.currentPage = page
                            OverviewIcon {}
                        }
                        SidebarItem {
                            page: root.pageNetwork
                            label: "Connectivity"
                            sublabel: "Wi-Fi, Bluetooth"
                            onClicked: root.currentPage = page
                            NetworkingIcon {}
                        }
                    }

                    SidebarGroup {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        currentPage: root.currentPage
                        collapsed: root.sidebarCollapsed
                        onNavigate: p => root.currentPage = p

                        SidebarItem {
                            page: root.pageBar
                            label: "Bar"
                            sublabel: "Layout, media, tray"
                            onClicked: root.currentPage = page
                            CustomizationIcon {}
                        }
                        SidebarItem {
                            page: root.pageClock
                            label: "Desktop Clock"
                            sublabel: "Mode, colors"
                            onClicked: root.currentPage = page
                            AnalogClockIcon {}
                        }
                        SidebarItem {
                            page: root.pageDisplay
                            label: "Display"
                            sublabel: "Nightlight, gamma"
                            onClicked: root.currentPage = page
                            NightlightIcon {}
                        }
                        SidebarItem {
                            page: root.pageSound
                            label: "Sound & Notifications"
                            sublabel: "Audio, popups"
                            onClicked: root.currentPage = page
                            NotificationsIcon {}
                        }
                    }

                    SidebarGroup {
                        Layout.fillWidth: true
                        currentPage: root.currentPage
                        collapsed: root.sidebarCollapsed
                        onNavigate: p => root.currentPage = p

                        SidebarItem {
                            page: root.pageLocale
                            label: "Locale"
                            sublabel: "Time, date, units"
                            onClicked: root.currentPage = page
                            LocaleIcon {}
                        }

                        SidebarItem {
                            page: root.pageSystem
                            label: "System"
                            sublabel: "About, paths, keybinds"
                            onClicked: root.currentPage = page
                            AboutIcon {}
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.md3.surface
            clip: true

            Component { id: overviewComp; OverviewPage {} }
            Component { id: networkComp; NetworkPage {} }
            Component { id: barComp; BarPage {} }
            Component { id: clockComp; ClockPage {} }
            Component { id: displayComp; DisplayPage {} }
            Component { id: soundComp; SoundPage {} }
            Component { id: localeComp; LocalePage {} }
            Component { id: systemComp; SystemPage {} }

            function componentForPage(page) {
                switch (page) {
                case root.pageOverview: return overviewComp;
                case root.pageNetwork: return networkComp;
                case root.pageBar: return barComp;
                case root.pageClock: return clockComp;
                case root.pageDisplay: return displayComp;
                case root.pageSound: return soundComp;
                case root.pageLocale: return localeComp;
                case root.pageSystem: return systemComp;
                default: return overviewComp;
                }
            }

            StackView {
                id: pageStack
                anchors.fill: parent
                clip: true
                initialItem: parent.componentForPage(root.currentPage)

                property int previousPage: -1
                property int enterOffset: 48

                Component.onCompleted: previousPage = root.currentPage

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
                        pageStack.enterOffset = root.currentPage > pageStack.previousPage ? 48 : -48;
                        pageStack.previousPage = root.currentPage;
                        pageStack.replace(pageStack.parent.componentForPage(root.currentPage));
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        const page = Quickshell.env("QS_PAGE");
        if (!page)
            return;
        const map = {
            "overview": root.pageOverview,
            "network": root.pageNetwork,
            "bar": root.pageBar,
            "clock": root.pageClock,
            "display": root.pageDisplay,
            "sound": root.pageSound,
            "locale": root.pageLocale,
            "system": root.pageSystem
        };
        const p = map[page];
        if (p !== undefined)
            root.currentPage = p;
    }
}
