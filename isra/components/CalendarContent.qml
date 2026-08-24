pragma ComponentBehavior: Bound
import QtQuick
import qs.style

Item {
    id: root

    property var controller: null

    readonly property bool isOpen: controller ? controller.isOpen : false

    anchors.fill: parent

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: root.isOpen

        Component.onCompleted: forceActiveFocus()

        Keys.onEscapePressed: event => {
            event.accepted = true;
            if (root.controller)
                root.controller.isOpen = false;
        }
    }

    Item {
        id: wrapper
        width: calContent.implicitWidth
        height: calContent.implicitHeight

        readonly property real screenEdgeMargin: 12

        anchors {
            top: Config.bar.position === 0 ? parent.top : undefined
            bottom: Config.bar.position === 1 ? parent.bottom : undefined
            topMargin: Config.bar.position === 0 ? (root.controller?.panelWindow.barHeight ?? 0) + 8 : 0
            bottomMargin: Config.bar.position === 1 ? (root.controller?.panelWindow.barHeight ?? 0) + 8 : 0
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
            edgeMargin: root.controller?.panelWindow.barHeight ?? 0

            onCalendarRequested: if (root.controller)
                root.controller.isOpen = false
            onSettingsRequested: if (root.controller)
                root.controller.isOpen = false
        }
    }
}
