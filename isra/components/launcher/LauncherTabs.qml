pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.icons
import qs.components

Item {
    id: root

    property string mode: "apps"
    signal tabRequested(string prefix)

    readonly property var tabs: [
        { mode: "apps", prefix: "", icon: "grid-view", label: Localization.t("launcher.tab_apps") },
        { mode: "clipboard", prefix: ";", icon: "assignment", label: Localization.t("launcher.tab_clipboard") },
        { mode: "emoji", prefix: ":", icon: "sentiment-satisfied", label: Localization.t("launcher.tab_emoji") }
    ]
    readonly property int current: Math.max(0, tabs.findIndex(t => t.mode === root.mode))
    readonly property real btnW: 44

    function snap() {
        ind._snap();
    }

    implicitWidth: btnW * tabs.length
    implicitHeight: 42

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.md3.surface_container_highest
    }

    SlidingIndicator {
        id: ind
        index: root.current
        step: root.btnW
        color: Colors.md3.secondary
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.tabs

            Item {
                id: tab
                required property var modelData
                required property int index

                width: root.btnW
                height: root.height

                MaterialIcon {
                    anchors.centerIn: parent
                    name: tab.modelData.icon
                    iconSize: 20
                    color: ind.covers(tab.x + tab.width / 2) ? Colors.md3.on_secondary : Colors.md3.on_surface
                    scale: tabMa.pressed ? 0.85 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: tabMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (tab.index !== root.current)
                        root.tabRequested(tab.modelData.prefix)
                }

                Tooltip {
                    text: tab.modelData.label
                }
            }
        }
    }
}
