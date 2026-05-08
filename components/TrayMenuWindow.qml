import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.style

PanelWindow {
    id: root

    property var trayItem: null
    required property var panelWindow

    readonly property real cardW: 210
    readonly property real cardR: 16
    readonly property real itemH: 34
    readonly property real sepH: 14
    readonly property real pad: 4
    readonly property real barGap: 15

    property var activeSubmenu: null
    property bool submenuOpen: false
    property bool _pendingOpen: false
    property bool _pendingSubOpen: false

    QsMenuOpener {
        id: mainOpener
        menu: root.trayItem?.menu ?? null
    }
    QsMenuOpener {
        id: subOpener
        menu: root.activeSubmenu
    }

    readonly property real mainH: mainCol.implicitHeight + pad * 2 + 2
    readonly property real subH: subCol.implicitHeight + pad * 2
    readonly property real cardH: submenuOpen ? subH : mainH

    property real cardX: 0
    property real cardY: 0

    readonly property bool barAtBottom: Config.barPosition === 1
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

    Connections {
        target: mainCol
        function onImplicitHeightChanged() {
            if (root._pendingOpen && mainCol.implicitHeight > 0) {
                root._pendingOpen = false;
                wipeAnim.restart();
            }
        }
    }

    Connections {
        target: subCol
        function onImplicitHeightChanged() {
            if (root._pendingSubOpen && subCol.implicitHeight > root.itemH) {
                root._pendingSubOpen = false;
                root.submenuOpen = true;
            }
        }
    }

    function open(item, globalIconPos) {
        submenuOpen = false;
        activeSubmenu = null;
        _pendingOpen = _pendingSubOpen = false;
        trayItem = item;

        var sx = panelWindow.screen?.x ?? 0;
        var sy = panelWindow.screen?.y ?? 0;
        var sw = panelWindow.screen?.width ?? 1920;
        var sh = panelWindow.screen?.height ?? 1080;

        cardX = Math.max(8, Math.min(globalIconPos.x - sx - cardW / 2, sw - cardW - 8));

        if (barAtBottom) {
            cardY = (globalIconPos.y - sy) - barGap - cardH;
        } else {
            cardY = (globalIconPos.y - sy) + barGap;
        }

        card._wiping = true;
        card.height = 0;
        visible = true;

        if (mainCol.implicitHeight > 0)
            wipeAnim.restart();
        else
            _pendingOpen = true;
    }

    function closeAll() {
        _pendingOpen = _pendingSubOpen = false;
        submenuOpen = false;
        activeSubmenu = null;
        closeAnim.start();
    }

    function openSubmenu(entry) {
        activeSubmenu = entry;
        if (subCol.implicitHeight > itemH)
            submenuOpen = true;
        else
            _pendingSubOpen = true;
    }

    function goBack() {
        _pendingSubOpen = false;
        submenuOpen = false;
        activeSubmenu = null;
    }

    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: root.closeAll()
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
            script: {
                card._wiping = true;
            }
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
        y: root.barAtBottom ? root.cardY + root.cardH - height : root.cardY

        Behavior on height {
            enabled: !card._wiping
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container, 0.92) : Colors.md3.surface_container
        radius: root.cardR
        border.width: 1
        border.color: Colors.md3.outline_variant
        clip: true
        layer.enabled: true

        property real slideX: root.submenuOpen ? -root.cardW : 0
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
                    onSubmenuClicked: entry => root.openSubmenu(entry)
                    onTriggered: root.closeAll()
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
                        rightMargin: 8
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
                }
                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 30
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.activeSubmenu?.text ?? ""
                    color: Colors.md3.on_surface
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: backHover.opacity = 0.08
                    onExited: backHover.opacity = 0
                    onClicked: root.goBack()
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
                    onTriggered: root.closeAll()
                }
            }
        }
    }
}
