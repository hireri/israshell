//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import qs.style
import qs.settings.components
import qs.settings
import qs.icons

ApplicationWindow {
    id: root

    visible: true
    width: 960
    height: 680
    minimumWidth: 900
    minimumHeight: 360
    title: "Settings"
    color: Colors.md3.background
    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint

    onClosing: Qt.quit()

    readonly property int pageOverview: 0
    readonly property int pageNetwork: 1
    readonly property int pageBar: 2
    readonly property int pageClock: 3
    readonly property int pageDisplay: 4
    readonly property int pageSound: 5
    readonly property int pageImmeria: 6
    readonly property int pageSystem: 7

    property int currentPage: pageOverview

    function openTo(page) {
        currentPage = page;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 248
            Layout.fillHeight: true
            color: Colors.md3.surface_container_low

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 20
                    color: Colors.md3.surface_container_high
                    Layout.bottomMargin: 14

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 14
                        }
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.pixelSize: 16
                            color: Colors.md3.outline
                        }

                        TextInput {
                            Layout.fillWidth: true
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            color: Colors.md3.on_surface
                            clip: true

                            Text {
                                anchors.fill: parent
                                text: "Search settings..."
                                font: parent.font
                                color: Colors.md3.outline
                                visible: parent.text === ""
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                SidebarGroup {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    currentPage: root.currentPage
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
                    onNavigate: p => root.currentPage = p

                    SidebarItem {
                        page: root.pageBar
                        label: "Bar"
                        sublabel: "Layout, clock"
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
                    onNavigate: p => root.currentPage = p

                    SidebarItem {
                        page: root.pageImmeria
                        label: Config.ai.name
                        sublabel: "AI, backend, tools"
                        onClicked: root.currentPage = page
                        ScriptsIcon {}
                    }
                    SidebarItem {
                        page: root.pageSystem
                        label: "System"
                        sublabel: "About, paths, keybinds"
                        onClicked: root.currentPage = page
                        AboutIcon {}
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.md3.surface

            StackLayout {
                anchors.fill: parent
                currentIndex: root.currentPage

                Loader {
                    active: root.currentPage === root.pageOverview
                    sourceComponent: OverviewPage {}
                }
                Loader {
                    active: root.currentPage === root.pageNetwork
                    sourceComponent: NetworkPage {}
                }
                Loader {
                    active: root.currentPage === root.pageBar
                    sourceComponent: BarPage {}
                }
                Loader {
                    active: root.currentPage === root.pageClock
                    sourceComponent: ClockPage {}
                }
                Loader {
                    active: root.currentPage === root.pageDisplay
                    sourceComponent: DisplayPage {}
                }
                Loader {
                    active: root.currentPage === root.pageSound
                    sourceComponent: SoundPage {}
                }
                Loader {
                    active: root.currentPage === root.pageImmeria
                    sourceComponent: AIPage {}
                }
                Loader {
                    active: root.currentPage === root.pageSystem
                    sourceComponent: SystemPage {}
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
            "immeria": root.pageImmeria,
            "system": root.pageSystem
        };
        const p = map[page];
        if (p !== undefined)
            root.currentPage = p;
    }
}
