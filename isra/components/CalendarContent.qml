pragma ComponentBehavior: Bound
import QtQuick
import qs.style

FocusScope {
    id: root

    property var controller: null

    readonly property bool isOpen: controller ? controller.isOpen : false

    anchors.fill: parent
    focus: root.isOpen

    readonly property var win: root.controller?.panelWindow ?? null
    readonly property bool melt: win?.meltActive ?? false
    anchors.topMargin: melt && Config.bar.position === 0 ? win.barHeight : 0
    anchors.bottomMargin: melt && Config.bar.position === 1 ? win.barHeight : 0
    clip: melt

    readonly property real meltTop: Math.max(root.y + wrapper.y + calContent.cardItem.y, root.y)
    readonly property real meltBottom: Math.min(root.y + wrapper.y + calContent.cardItem.y + calContent.cardItem.height, root.y + root.height)
    readonly property real meltVisible: Math.max(0, meltBottom - meltTop)

    MeltReporter {
        win: root.win
        key: "calendar"
        rect: Qt.rect(root.x + wrapper.x, root.meltTop, wrapper.width, root.meltVisible)
        active: root.melt && (root.isOpen || root.meltVisible > 0.5)
    }

    Component.onCompleted: forceActiveFocus()
    onIsOpenChanged: if (isOpen)
        forceActiveFocus()

    Keys.onEscapePressed: event => {
        event.accepted = true;
        if (root.controller)
            root.controller.isOpen = false;
    }

    Item {
        id: wrapper
        width: calContent.implicitWidth
        height: calContent.implicitHeight

        readonly property real screenEdgeMargin: (root.controller?.panelWindow?.frameInset ?? 0) + (root.controller?.panelWindow?.panelGap ?? 12)

        anchors {
            top: Config.bar.position === 0 ? parent.top : undefined
            bottom: Config.bar.position === 1 ? parent.bottom : undefined
            topMargin: Config.bar.position === 0 && !root.melt ? (root.controller?.panelWindow.barHeight ?? 0) + (root.controller?.panelWindow?.panelGap ?? 12) : 0
            bottomMargin: Config.bar.position === 1 && !root.melt ? (root.controller?.panelWindow.barHeight ?? 0) + (root.controller?.panelWindow?.panelGap ?? 12) : 0
        }

        function _clamp(value, min, max) {
            return max >= min ? Math.max(min, Math.min(max, value)) : min;
        }

        function _screenWidth() {
            const screen = root.controller?.panelWindow?.screen;
            return (screen && screen.width > 0) ? screen.width : root.width;
        }

        x: {
            if (!root.controller)
                return 0;
            const pillCenterLocal = root.controller.width / 2;
            const mappedPoint = root.controller.mapToItem(root, pillCenterLocal, 0);
            const idealX = mappedPoint.x - (calContent.implicitWidth / 2);
            return Math.round(wrapper._clamp(idealX, screenEdgeMargin, wrapper._screenWidth() - calContent.implicitWidth - screenEdgeMargin));
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ClockCalendar {
            id: calContent
            anchors.fill: parent
            isOpen: root.isOpen
            edgeMargin: root.melt ? 0 : (root.controller?.panelWindow.barHeight ?? 0)
            melt: root.melt
            meltFade: Math.max(0, Math.min(1, (root.meltVisible / calContent.cardItem.height - 0.5) * 2))

        }
    }
}
