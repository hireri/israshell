import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property var hostScreen
    readonly property alias cardItem: card

    readonly property real cardW: 190
    readonly property real cardR: 16
    readonly property real itemH: 34
    readonly property real sepH: 14
    readonly property real pad: 4

    anchors.fill: parent
    visible: false

    Component {
        id: editIconComp
        MaterialIcon {
            name: "edit"
            iconSize: 16
            color: Colors.md3.on_surface_variant
        }
    }
    Component {
        id: checkIconComp
        MaterialIcon {
            name: "check"
            iconSize: 16
            color: Colors.md3.on_surface_variant
        }
    }
    Component {
        id: undoIconComp
        MaterialIcon {
            name: "history"
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
    Component {
        id: wallpaperIconComp
        MaterialIcon {
            name: "wallpapers"
            iconSize: 16
            color: Colors.md3.on_surface_variant
        }
    }
    Component {
        id: terminalIconComp
        MaterialIcon {
            name: "terminal"
            iconSize: 16
            color: Colors.md3.on_surface_variant
        }
    }

    Process {
        id: launchProc
        running: false
    }

    function run(cmd) {
        launchProc.command = cmd;
        launchProc.running = true;
    }

    readonly property var entries: EditModeService.active ? [
        {
            text: Localization.t("backgroundMenu.exit_edit_mode"),
            icon: checkIconComp,
            action: () => EditModeService.disable()
        },
        {
            text: Localization.t("background.undo_changes"),
            icon: undoIconComp,
            action: () => EditModeService.undoChanges()
        }
    ] : [
        {
            text: Localization.t("backgroundMenu.edit_widgets"),
            icon: editIconComp,
            action: () => EditModeService.enable()
        },
        {
            isSep: true
        },
        {
            text: Localization.t("backgroundMenu.wallpaper"),
            icon: wallpaperIconComp,
            action: () => root.run(["qs", "-c", "isra", "ipc", "call", "wallpaperpicker", "toggle"])
        },
        {
            text: Localization.t("backgroundMenu.settings"),
            icon: settingsIconComp,
            action: () => root.run(["qs", "-c", "isra", "ipc", "call", "settings", "open", "overview"])
        },
        {
            isSep: true
        },
        {
            text: Localization.t("backgroundMenu.open_terminal"),
            icon: terminalIconComp,
            action: () => Quickshell.execDetached({
                command: ["kitty"],
                workingDirectory: Quickshell.env("HOME")
            })
        }
    ]

    readonly property real cardH: col.implicitHeight + pad * 2 + 2

    property real cardX: 0
    property real cardY: 0

    function _doOpen(localX, localY) {
        cardX = Math.max(8, Math.min(localX, root.width - cardW - 8));
        cardY = Math.max(8, Math.min(localY, root.height - cardH - 8));

        card._wiping = true;
        card.height = 0;
        visible = true;
        wipeAnim.restart();
        PanelService.opened(root, root.hostScreen);
    }

    function close() {
        if (!root.visible)
            return;
        closeAnim.start();
        PanelService.closed(root);
        if (BackgroundMenuService.openScreen === root.hostScreen)
            BackgroundMenuService.close();
    }

    Connections {
        target: BackgroundMenuService
        function onOpenRequested(screen, localX, localY) {
            if (screen === root.hostScreen) {
                root._doOpen(localX, localY);
            }
        }
        function onOpenScreenChanged() {
            if (BackgroundMenuService.openScreen !== root.hostScreen && root.visible) {
                root.close();
            }
        }
    }

    MouseArea {
        id: outsideCatcher
        anchors.fill: parent
        visible: root.visible
        enabled: root.visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.close()
    }

    NumberAnimation {
        id: wipeAnim
        target: card
        property: "height"
        from: 0
        to: root.cardH
        duration: 160
        easing.type: Easing.OutCubic
        onStarted: card._wiping = true
        onStopped: card._wiping = false
    }

    SequentialAnimation {
        id: closeAnim
        ScriptAction {
            script: card._wiping = true
        }
        NumberAnimation {
            target: card
            property: "height"
            to: 0
            duration: 110
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                card._wiping = false;
                root.visible = false;
            }
        }
    }

    Binding {
        when: root.visible && !card._wiping
        target: card
        property: "height"
        value: root.cardH
        restoreMode: Binding.RestoreNone
    }

    Rectangle {
        id: card
        property bool _wiping: false

        x: root.cardX
        y: root.cardY
        width: root.cardW

        Behavior on height {
            enabled: !card._wiping
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
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
                    readonly property bool isSep: modelData.isSep ?? false
                    width: root.cardW
                    height: isSep ? root.sepH : root.itemH

                    Rectangle {
                        visible: row.isSep
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            right: parent.right
                            rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        height: 1
                        color: Qt.alpha(Colors.md3.on_surface, 0.15)
                    }

                    Rectangle {
                        id: hoverBg
                        visible: !row.isSep
                        anchors {
                            fill: parent
                            leftMargin: 6
                            rightMargin: 6
                            topMargin: 2
                            bottomMargin: 2
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

                    Item {
                        id: icon
                        visible: !row.isSep
                        anchors {
                            left: parent.left
                            leftMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        width: 16
                        height: 16

                        Loader {
                            id: iconLoader
                            anchors.centerIn: parent
                            active: !row.isSep && (row.modelData.icon ?? null) !== null
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
                        visible: !row.isSep
                        anchors {
                            left: icon.width > 0 ? icon.right : parent.left
                            leftMargin: icon.width > 0 ? 7 : 14
                            right: parent.right
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        text: row.modelData.text ?? ""
                        color: Colors.md3.on_surface
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.isSep
                        cursorShape: Qt.PointingHandCursor
                        onEntered: hoverBg.opacity = 0.08
                        onExited: hoverBg.opacity = 0
                        onClicked: {
                            const action = row.modelData.action;
                            root.close();
                            action();
                        }
                    }
                }
            }
        }
    }
}
