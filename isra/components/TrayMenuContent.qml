pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services

Item {
    id: root

    property var controller: null

    readonly property bool isOpen: controller ? controller.isOpen : false

    readonly property real cardW: 210
    readonly property real cardR: 16
    readonly property real itemH: 34
    readonly property real sepH: 14
    readonly property real pad: 4
    readonly property real barGap: 3

    readonly property bool barAtBottom: Config.bar.position === 1

    anchors.fill: parent

    QsMenuOpener {
        id: mainOpener
        menu: root.controller?.trayItem?.menu ?? null
    }
    QsMenuOpener {
        id: subOpener
        menu: root.controller?.activeSubmenu ?? null
    }

    readonly property real mainH: mainCol.implicitHeight + pad * 2
    readonly property real subH: subCol.implicitHeight + pad * 2
    readonly property real cardH: (root.controller?.submenuOpen ?? false) ? subH : mainH

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: root.isOpen
        Keys.onEscapePressed: event => {
            event.accepted = true;
            if (root.controller)
                root.controller.closeAll();
        }
    }
    onIsOpenChanged: if (isOpen) Qt.callLater(() => keyHandler.forceActiveFocus())

    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => root._ready = true)

    Rectangle {
        id: card

        x: root.controller?.cardX ?? 0
        width: root.cardW
        height: (root._ready && root.isOpen) ? root.cardH : 0
        y: root.barAtBottom
            ? (root.height - (root.controller?.panelWindow.barHeight ?? 0) - root.barGap - height)
            : ((root.controller?.panelWindow.barHeight ?? 0) + root.barGap)

        Behavior on height {
            NumberAnimation {
                duration: root.isOpen ? 180 : 110
                easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
            }
        }

        clip: true

        color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        radius: root.cardR
        border.width: 1
        border.color: Qt.alpha(Colors.md3.on_surface, 0.3)

        property real slideX: (root.controller?.submenuOpen ?? false) ? -root.cardW : 0
        Behavior on slideX {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: mainCol
            x: card.slideX
            y: root.pad
            width: root.cardW

            Repeater {
                model: mainOpener.children
                delegate: TrayMenuItem {
                    required property var modelData
                    menuEntry: modelData
                    totalWidth: root.cardW
                    itemH: root.itemH
                    sepH: root.sepH
                    onSubmenuClicked: entry => {
                        if (root.controller)
                            root.controller.openSubmenu(entry);
                    }
                    onTriggered: {
                        if (root.controller)
                            root.controller.closeAll();
                    }
                }
            }
        }

        Column {
            id: subCol
            x: card.slideX + root.cardW
            y: root.pad
            width: root.cardW

            Item {
                width: root.cardW
                height: root.itemH

                Rectangle {
                    id: backHover
                    anchors {
                        fill: parent
                        topMargin: 2
                        bottomMargin: 2
                        leftMargin: 6
                        rightMargin: 6
                    }
                    radius: 12
                    color: Colors.md3.on_surface
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 60
                        }
                    }
                }
                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    text: "󰅁"
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 15
                    renderType: Text.NativeRendering
                }
                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 30
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.controller?.activeSubmenu?.text ?? ""
                    color: Colors.md3.on_surface
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: backHover.opacity = 0.08
                    onExited: backHover.opacity = 0
                    onClicked: {
                        if (root.controller)
                            root.controller.goBack();
                    }
                }
            }

            Repeater {
                model: subOpener.children
                delegate: TrayMenuItem {
                    required property var modelData
                    menuEntry: modelData
                    totalWidth: root.cardW
                    itemH: root.itemH
                    sepH: root.sepH
                    onSubmenuClicked: entry => {}
                    onTriggered: {
                        if (root.controller)
                            root.controller.closeAll();
                    }
                }
            }
        }
    }
}
