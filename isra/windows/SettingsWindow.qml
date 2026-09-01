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
    title: Localization.t("settingsWindow.settings")
    color: "transparent"

    readonly property int pageOverview: 0
    readonly property int pageNetwork: 1
    
    readonly property int pageBar: 2
    readonly property int pageFloatingDock: 3
    readonly property int pageBackground: 4
    readonly property int pageClock: 5

    readonly property int pageDisplay: 6
    readonly property int pageSound: 7

    readonly property int pageAiAssistant:  8
    readonly property int pageLocale: 9
    readonly property int pageSystem: 10

    readonly property var pageIndexByName: ({
        "overview": pageOverview,
        "network": pageNetwork,
        "bar": pageBar,
        "floatingdock": pageFloatingDock,
        "background": pageBackground,
        "clock": pageClock,
        "display": pageDisplay,
        "sound": pageSound,
        "aiassistant": pageAiAssistant,
        "locale": pageLocale,
        "system": pageSystem
    })

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
            id: sidebarPane
            Layout.preferredWidth: root.sidebarCollapsed ? 72 : 248
            Layout.fillHeight: true
            color: Config.dim(Colors.md3.surface_container_low)
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
                    policy: ScrollBar.AlwaysOff
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
                            text: Localization.t("settingsWindow.settings")
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
                            label: Localization.t("settingsWindow.overview")
                            sublabel: Localization.t("settingsWindow.wallpaper_appearance")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "overview"; transitionType: "wipe-right" }
                        }
                        SidebarItem {
                            page: root.pageNetwork
                            label: Localization.t("settingsWindow.connectivity")
                            sublabel: Localization.t("settingsWindow.wi_fi_bluetooth")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "networking" }
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
                            label: Localization.t("settingsWindow.bar")
                            sublabel: Localization.t("settingsWindow.layout_media_tray")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "customization"; transitionType: "wipe-up" }
                        }
                        SidebarItem {
                            page: root.pageFloatingDock
                            label: Localization.t("widgetService.dock")
                            sublabel: Localization.t("settingsWindow.position_hiding_icon_size")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "call-to-action"; transitionType: "circle" }
                        }
                        SidebarItem {
                            page: root.pageBackground
                            label: Localization.t("settingsWindow.background")
                            sublabel: Localization.t("settingsWindow.effects_wallpaper_widgets")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "panorama"; transitionType: "wipe-right" }
                        }
                        SidebarItem {
                            page: root.pageClock
                            label: Localization.t("settingsWindow.desktop_clock")
                            sublabel: Localization.t("settingsWindow.mode_colors")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "analog-clock"; transitionType: "circle" }
                        }
                    }

                    SidebarGroup {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        currentPage: root.currentPage
                        collapsed: root.sidebarCollapsed
                        onNavigate: p => root.currentPage = p

                        SidebarItem {
                            page: root.pageDisplay
                            label: Localization.t("settingsWindow.visuals_display")
                            sublabel: Localization.t("settingsWindow.night_light_blur")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "monitor"; transitionType: "wipe-down" }
                        }
                        SidebarItem {
                            page: root.pageSound
                            label: Localization.t("settingsWindow.sound_audio")
                            sublabel: Localization.t("settingsWindow.audio_popups")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "notifications"; transitionType: "wipe-up" }
                        }
                    }

                    SidebarGroup {
                        Layout.fillWidth: true
                        currentPage: root.currentPage
                        collapsed: root.sidebarCollapsed
                        onNavigate: p => root.currentPage = p

                        SidebarItem {
                            page: root.pageAiAssistant
                            label: Localization.t("settingsWindow.ai_assistant")
                            sublabel: Localization.t("settingsWindow.provider_prompt_behavior")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "automation"; }
                        }
                        SidebarItem {
                            page: root.pageLocale
                            label: Localization.t("settingsWindow.locale")
                            sublabel: Localization.t("settingsWindow.time_date_units")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "language" }
                        }
                        SidebarItem {
                            page: root.pageSystem
                            label: Localization.t("settingsWindow.system")
                            sublabel: Localization.t("settingsWindow.about_paths_keybinds")
                            onClicked: root.currentPage = page
                            MaterialIcon { name: "about"; transitionType: "circle" }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: contentPane
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Config.dim(Colors.md3.surface)
            clip: true

            Component { id: overviewComp; OverviewPage {} }
            Component { id: networkComp; NetworkPage {} }
            Component { id: barComp; BarPage {} }
            Component { id: backgroundComp; BackgroundPage {} }
            Component { id: clockComp; ClockPage {} }
            Component { id: displayComp; DisplayPage {} }
            Component { id: soundComp; SoundPage {} }
            Component { id: localeComp; LocalePage {} }
            Component { id: systemComp; SystemPage {} }
            Component { id: floatingDockComp; DockPage {} }
            Component { id: aiAssistantComp; AiAssistantPage {} }

            function componentForPage(page) {
                switch (page) {
                case root.pageOverview: return overviewComp;
                case root.pageNetwork: return networkComp;
                case root.pageBar: return barComp;
                case root.pageFloatingDock: return floatingDockComp;
                case root.pageBackground: return backgroundComp;
                case root.pageClock: return clockComp;
                case root.pageDisplay: return displayComp;
                case root.pageSound: return soundComp;
                case root.pageLocale: return localeComp;
                case root.pageSystem: return systemComp;
                case root.pageAiAssistant: return aiAssistantComp;
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
            "floatingdock": root.pageFloatingDock,
            "background": root.pageBackground,
            "clock": root.pageClock,
            "display": root.pageDisplay,
            "sound": root.pageSound,
            "locale": root.pageLocale,
            "system": root.pageSystem,
            "aiassistant": root.pageAiAssistant
        };
        const p = map[page];
        if (p !== undefined)
            root.currentPage = p;
    }
}