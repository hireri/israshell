import QtQuick
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property var hostScreen
    property var entries: []
    property real cardW: 190

    property bool opaque: false
    readonly property bool blurActive: !root.opaque && Config.blurAllowed(true)

    readonly property alias cardItem: card
    readonly property bool coexistsWithMode: true

    readonly property real cardR: 16
    readonly property real itemH: 36
    readonly property real sepH: 11
    readonly property real pad: 3
    readonly property real padBottom: 5

    anchors.fill: parent
    visible: false

    signal opened
    signal closed

    property var activeSubmenu: null
    property bool submenuOpen: false

    property bool _originRight: false
    property bool _originBottom: false
    readonly property real cardOriginX: root._originRight ? 1 : 0
    readonly property real cardOriginY: root._originBottom ? 1 : 0

    readonly property real mainH: mainCol.implicitHeight + pad + padBottom
    readonly property real subH: subCol.implicitHeight + pad + padBottom
    readonly property real cardH: root.submenuOpen ? root.subH : root.mainH

    readonly property real activeW: root.submenuOpen ? (root.activeSubmenu?.submenuWidth ?? root.cardW) : root.cardW

    property real cardX: 0
    property real cardY: 0

    property var _pending: null

    property var _shownEntries: []
    property real _targetH: 0

    function _measuredH(list): real {
        let h = root.pad + root.padBottom;
        for (let i = 0; i < list.length; i++)
            h += (list[i].isSep ?? false) ? root.sepH : root.itemH;
        return h;
    }

    FontMetrics {
        id: rowFont
        font.family: Config.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    readonly property real minCardW: 150
    readonly property real maxCardW: 280

    function _measuredW(list): real {
        let w = root.minCardW;
        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            if (e.isSep ?? false)
                continue;
            const chrome = 52 + (((e.submenu ?? null) !== null) ? 20 : 0);
            w = Math.max(w, rowFont.advanceWidth(e.text ?? "") + chrome);
        }
        return Math.min(root.maxCardW, Math.ceil(w));
    }

    function open(localX, localY, newEntries, newCardW): void {
        if (root.visible && card.opacity > 0.01) {
            root._pending = { x: localX, y: localY, entries: newEntries, cardW: newCardW };
            openAnim.stop();
            if (!closeAnim.running)
                closeAnim.restart();
            return;
        }
        root._apply(localX, localY, newEntries, newCardW);
    }

    function _apply(x, y, newEntries, newCardW): void {
        card._wiping = true;
        root.goBack();
        if (newEntries !== undefined)
            root.entries = newEntries;
        root._shownEntries = root.entries;
        root.cardW = newCardW !== undefined ? newCardW : root._measuredW(root._shownEntries);
        root._targetH = root._measuredH(root._shownEntries);
        root.cardX = Math.max(8, Math.min(x, root.width - root.cardW - 8));
        root.cardY = Math.max(8, Math.min(y, root.height - root._targetH - 8));
        root._originRight = root.cardX < x - 0.5;
        root._originBottom = root.cardY < y - 0.5;
        card.height = root._targetH;
        card.opacity = 0;
        card.scale = 0.9;
        root.visible = true;
        openAnim.restart();
        PanelService.opened(root, root.hostScreen);
        root.opened();
    }

    function close(): void {
        if (!root.visible)
            return;
        root.goBack();
        root._pending = null;
        openAnim.stop();
        if (!closeAnim.running)
            closeAnim.restart();
        PanelService.closed(root);
        root.closed();
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
        NumberAnimation { target: card; property: "scale"; to: 0.9; duration: 110; easing.type: Easing.InCubic }
        onStarted: card._wiping = true
        onStopped: {
            const next = root._pending;
            root._pending = null;
            if (next) {
                root._apply(next.x, next.y, next.entries, next.cardW);
            } else {
                card._wiping = false;
                root.visible = false;
            }
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "scale"; from: 0.9; to: 1; duration: 160; easing.type: Easing.OutCubic }
        onStarted: card._wiping = true
        onStopped: card._wiping = false
    }

    function openSubmenu(entry): void {
        root.activeSubmenu = entry;
        root.submenuOpen = true;
    }

    function goBack(): void {
        root.submenuOpen = false;
        root.activeSubmenu = null;
    }

    MouseArea {
        id: outsideCatcher
        anchors.fill: parent
        visible: root.visible
        enabled: root.visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        onClicked: mouse => {
            root.close();
            if (mouse.button === Qt.RightButton)
                mouse.accepted = false;
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
        y: root.cardY
        width: root.activeW

        Behavior on height {
            enabled: !card._wiping
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            enabled: !card._wiping
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        color: root.blurActive ? "transparent" : Qt.alpha(Colors.md3.surface_container, root.opaque ? 1 : Config.blurOpacity)
        radius: root.cardR
        border.width: 1
        border.color: Qt.alpha(Colors.md3.on_surface, 0.3)
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            visible: root.blurActive
            color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        }

        transformOrigin: {
            if (root._originBottom && root._originRight)
                return Item.BottomRight;
            if (root._originBottom)
                return Item.BottomLeft;
            if (root._originRight)
                return Item.TopRight;
            return Item.TopLeft;
        }

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
            opacity: root.submenuOpen ? 0 : 1
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: root._shownEntries
                delegate: MenuRow {
                    required property var modelData
                    entry: modelData
                    rowWidth: root.cardW
                }
            }
        }

        Item {
            id: subCol
            x: card.slideX + root.cardW
            y: root.pad
            width: root.activeW
            implicitHeight: backRow.height + (subLoader.item?.implicitHeight ?? 0) + 4
            opacity: root.submenuOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Item {
                id: backRow
                width: subCol.width
                height: root.itemH

                Rectangle {
                    id: backHover
                    anchors {
                        fill: parent
                        topMargin: 2
                        bottomMargin: 2
                        leftMargin: 4
                        rightMargin: 6
                    }
                    radius: 10
                    color: Colors.md3.on_surface
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }
                }

                MaterialIcon {
                    id: backIcon
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    name: "chevron-left"
                    iconSize: 16
                    color: Colors.md3.on_surface_variant
                }

                Text {
                    anchors {
                        left: backIcon.right
                        leftMargin: 7
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.activeSubmenu?.text ?? ""
                    color: Colors.md3.on_surface
                    font.family: Config.fontFamily
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

            Loader {
                id: subLoader
                anchors {
                    top: backRow.bottom
                    left: parent.left
                    right: parent.right
                }
                active: root.activeSubmenu !== null
                sourceComponent: root.activeSubmenu?.submenu ?? null
            }
        }
    }

    component MenuRow: Item {
        id: row

        required property var entry
        required property real rowWidth

        readonly property bool isSep: row.entry.isSep ?? false
        readonly property bool isDanger: row.entry.danger ?? false
        readonly property bool hasSubmenu: (row.entry.submenu ?? null) !== null

        width: row.rowWidth
        height: row.isSep ? root.sepH : root.itemH

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
                leftMargin: 5
                rightMargin: 7
                topMargin: 2
                bottomMargin: 2
            }
            radius: 10
            color: row.isDanger ? Colors.md3.error : Colors.md3.on_surface
            opacity: 0
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }

        Item {
            id: icon
            visible: !row.isSep
            anchors {
                left: parent.left
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }
            width: 16
            height: 16

            Loader {
                id: iconLoader
                anchors.centerIn: parent
                active: !row.isSep && (row.entry.icon ?? null) !== null
                sourceComponent: row.entry.icon

                Binding {
                    target: iconLoader.item
                    property: "color"
                    value: row.isDanger ? Colors.md3.error : Colors.md3.on_surface_variant
                    when: iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("color")
                }
            }
        }

        Text {
            visible: !row.isSep
            anchors {
                left: icon.width > 0 ? icon.right : parent.left
                leftMargin: icon.width > 0 ? 7 : 12
                right: chevron.visible ? chevron.left : parent.right
                rightMargin: chevron.visible ? 8 : 14
                verticalCenter: parent.verticalCenter
            }
            text: row.entry.text ?? ""
            color: row.isDanger ? Colors.md3.error : Colors.md3.on_surface
            font.family: Config.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        MaterialIcon {
            id: chevron
            visible: row.hasSubmenu && !row.isSep
            anchors {
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            name: "chevron-right"
            iconSize: 14
            color: Colors.md3.on_surface_variant
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: !row.isSep
            cursorShape: Qt.PointingHandCursor
            onEntered: hoverBg.opacity = 0.08
            onExited: hoverBg.opacity = 0
            onClicked: {
                hoverBg.opacity = 0;
                if (row.hasSubmenu) {
                    root.openSubmenu(row.entry);
                    return;
                }
                const action = row.entry.action;
                root.close();
                if (action)
                    action();
            }
        }
    }
}
