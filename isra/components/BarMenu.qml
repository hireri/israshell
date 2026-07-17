import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.style
import qs.icons
import Qt5Compat.GraphicalEffects
import qs.services

PanelWindow {
    id: root

    required property var panelWindow

    readonly property real cardW: 190
    readonly property real cardR: 16
    readonly property real itemH: 34
    readonly property real pad: 4
    readonly property real barGap: 3

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
            text: "Mission Center",
            icon: missionCenterIconComp,
            action: () => Quickshell.execDetached(["missioncenter"])
        },
        {
            text: "Settings",
            icon: settingsIconComp,
            action: () => Quickshell.execDetached(["qs", "-c", "isra", "ipc", "call", "settings", "open", "bar"])
        }
    ]

    readonly property real cardH: col.implicitHeight + pad * 2 + 2

    property real cardX: 0

    readonly property bool barAtBottom: Config.bar.position === 1
    screen: panelWindow.screen
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    function open(globalClickPos) {
        var sx = panelWindow.screen?.x ?? 0;
        var sw = panelWindow.screen?.width ?? 1920;

        cardX = Math.max(8, Math.min(globalClickPos.x - sx - cardW / 2, sw - cardW - 8));

        card._wiping = true;
        card.height = 0;
        visible = true;
        wipeAnim.restart();
    }

    function close() {
        closeAnim.start();
    }

    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: root.close()
        acceptedButtons: Qt.LeftButton | Qt.RightButton
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

    ClippingRectangle {
        id: card
        property bool _wiping: false

        x: root.cardX
        width: root.cardW
        y: root.barAtBottom ? (root.height - panelWindow.height - root.barGap - height) : (panelWindow.height + root.barGap)

        Behavior on height {
            enabled: !card._wiping
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        color: Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container, 0.92) : Colors.md3.surface_container
        radius: root.cardR
        border.width: 1
        border.color: Config.bar.transparency ? Qt.alpha(Colors.md3.on_surface, 0.3) : Colors.md3.outline_variant
        clip: true
        layer.enabled: true

        Loader {
            id: cardBlurLoader
            anchors.fill: parent
            active: root.visible && Config.blurEffects && !GameModeService.active && Config.bar.transparency > 0
            
            sourceComponent: Item {
                id: cardBlurContainer
                anchors.fill: parent
                Item {
                    id: blurSource
                    anchors.fill: parent
                    clip: true
                    visible: false

                    Image {
                        id: cardBlurSrc
                        x: -card.x
                        y: -card.y
                        width: root.screen ? root.screen.width : 0
                        height: root.screen ? root.screen.height : 0
                        
                        sourceSize.width: root.screen ? root.screen.width / 4 : 0
                        sourceSize.height: root.screen ? root.screen.height / 4 : 0

                        source: (WallpaperService.currentWallPreview || WallpaperService.currentWall) 
                            ? ("file://" + (WallpaperService.currentWallPreview || WallpaperService.currentWall)) 
                            : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                FastBlur {
                    id: cardBlurEffect
                    anchors.fill: parent
                    source: blurSource
                    radius: Config.blurRadius
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
                }
            }
        }


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
                            leftMargin: 6
                            rightMargin: 8
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
                            root.close();
                        }
                    }
                }
            }
        }
    }
}