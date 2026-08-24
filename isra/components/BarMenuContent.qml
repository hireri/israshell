pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    property var controller: null

    readonly property bool isOpen: controller ? controller.isOpen : false

    readonly property real cardW: 190
    readonly property real cardR: 16
    readonly property real itemH: 34
    readonly property real pad: 3
    readonly property real barGap: 3

    readonly property bool barAtBottom: Config.bar.position === 1

    anchors.fill: parent

    Component {
        id: missionCenterIconComp
        MaterialIcon {
            name: "mission-center"
            iconSize: 16
            color: Colors.md3.on_surface_variant
        }
    }
    Component {
        id: settingsIconComp
        MaterialIcon {
            name: "settings"
            iconSize: 16
            color: Colors.md3.on_surface_variant
        }
    }

    readonly property var entries: [
        {
            text: Localization.t("barMenu.mission_center"),
            icon: missionCenterIconComp,
            action: () => Quickshell.execDetached(["missioncenter"])
        },
        {
            text: Localization.t("settingsWindow.settings"),
            icon: settingsIconComp,
            action: () => Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "settings", "open", "bar"])
        }
    ]

    readonly property real cardH: col.implicitHeight + pad * 2 + 2

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: root.isOpen
        Keys.onEscapePressed: event => {
            event.accepted = true;
            if (root.controller)
                root.controller.close();
        }
    }

    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => root._ready = true)

    ClippingRectangle {
        id: card

        x: root.controller?.cardX ?? 0
        width: root.cardW
        height: (root._ready && root.isOpen) ? root.cardH : 0
        y: root.barAtBottom
            ? (root.height - (root.controller?.panelWindow.barHeight ?? 0) - root.barGap - height)
            : ((root.controller?.panelWindow.barHeight ?? 0) + root.barGap)

        Behavior on height {
            NumberAnimation {
                duration: root.isOpen ? 160 : 110
                easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
            }
        }

        color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        radius: root.cardR
        border.width: 1
        border.color: Qt.alpha(Colors.md3.on_surface, 0.3)
        clip: true

        Column {
            id: col
            x: 0
            y: root.pad
            width: root.cardW

            Repeater {
                model: root.entries
                delegate: Item {
                    id: row
                    required property var modelData
                    width: root.cardW
                    height: root.itemH

                    Rectangle {
                        id: hoverBg
                        anchors {
                            fill: parent
                            leftMargin: 5
                            rightMargin: 7
                            topMargin: 2
                            bottomMargin: 2
                        }
                        radius: 10
                        color: Colors.md3.on_surface
                        opacity: 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 60
                            }
                        }
                    }

                    Item {
                        id: icon
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        width: 18
                        height: 18

                        Loader {
                            id: iconLoader
                            anchors.centerIn: parent
                            active: row.modelData.icon !== null
                            sourceComponent: row.modelData.icon

                            Binding {
                                target: iconLoader.item
                                property: "color"
                                value: Colors.md3.on_surface_variant
                                when: iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("color")
                            }
                        }
                    }

                    Text {
                        anchors {
                            left: icon.width > 0 ? icon.right : parent.left
                            leftMargin: icon.width > 0 ? 7 : 14
                            right: parent.right
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        text: row.modelData.text
                        color: Colors.md3.on_surface
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: hoverBg.opacity = 0.08
                        onExited: hoverBg.opacity = 0
                        onClicked: {
                            row.modelData.action();
                            if (root.controller)
                                root.controller.close();
                        }
                    }
                }
            }
        }
    }
}
