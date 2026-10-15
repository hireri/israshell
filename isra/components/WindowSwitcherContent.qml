pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.services
import qs.style

Item {
    id: root

    property var controller: null
    readonly property bool isOpen: controller ? controller.isOpen : false
    readonly property var entries: controller?.entries ?? []
    readonly property int index: controller?.index ?? 0

    anchors.fill: parent

    readonly property var scr: controller?._targetScreen ?? Quickshell.screens[0]

    function iconSource(appId: string): string {
        const entry = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(entry?.icon || appId || "application-x-executable", "application-x-executable");
    }

    property bool settled: false
    Timer {
        id: settleTimer
        interval: 200
        onTriggered: root.settled = true
    }

    focus: isOpen
    onIsOpenChanged: {
        settled = false;
        if (isOpen) {
            settleTimer.restart();
            Qt.callLater(() => root.forceActiveFocus());
        }
    }
    Component.onCompleted: if (isOpen) {
        settleTimer.restart();
        Qt.callLater(() => root.forceActiveFocus());
    }

    Keys.onPressed: event => {
        const c = root.controller;
        if (!c)
            return;
        if (event.key === Qt.Key_Escape)
            c.close();
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
            c.step(1);
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
            c.step(-1);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            c.commit();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Alt)
            root.controller?.commit();
    }

    Rectangle {
        id: panel

        property bool shown: false
        Component.onCompleted: Qt.callLater(() => panel.shown = true)
        readonly property bool vis: root.isOpen && shown

        readonly property real screenEdgeMargin: 12
        readonly property int cellW: 272
        readonly property int cellH: 228
        readonly property int fitCols: Math.max(1, Math.floor(((root.scr?.width ?? 1920) - 2 * screenEdgeMargin - 32 + 12) / cellW))
        readonly property int n: root.entries.length
        readonly property int cols: n <= fitCols ? Math.max(1, n) : Math.min(Math.ceil(n / 2), fitCols)
        readonly property int rows: n <= fitCols ? 1 : 2

        width: cols * cellW - 12 + 32
        height: rows * cellH - 12 + 32
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        radius: 24
        color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)

        opacity: vis ? 1 : 0
        scale: vis ? 1 : 0.94
        Behavior on opacity {
            NumberAnimation {
                duration: panel.vis ? 160 : 120
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: panel.vis ? 260 : 160
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        GridView {
            id: strip
            x: 16
            y: 16
            width: panel.cols * panel.cellW
            height: panel.rows * panel.cellH
            cellWidth: panel.cellW
            cellHeight: panel.cellH
            interactive: false
            clip: true
            model: root.entries
            currentIndex: root.index
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
            highlightFollowsCurrentItem: true
            highlightMoveDuration: root.settled ? 160 : 0
            highlight: Rectangle {
                width: 260
                height: 216
                radius: 18
                color: Colors.md3.primary_container
            }

            delegate: Rectangle {
                id: card
                required property var modelData
                required property int index
                readonly property bool selected: strip.highlightItem !== null && x + width / 2 > strip.highlightItem.x && x + width / 2 < strip.highlightItem.x + strip.highlightItem.width && y + height / 2 > strip.highlightItem.y && y + height / 2 < strip.highlightItem.y + strip.highlightItem.height

                width: 260
                height: 216
                radius: 18
                color: selected ? "transparent" : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

                Item {
                    id: thumb
                    x: 10
                    y: 10
                    width: parent.width - 20
                    height: 150

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 64
                        source: root.iconSource(card.modelData.appId)
                        visible: !shot.hasContent
                    }

                    ScreencopyView {
                        id: shot
                        readonly property real fit: implicitWidth > 0 ? Math.min(thumb.width / implicitWidth, thumb.height / implicitHeight) : 0
                        anchors.centerIn: parent
                        width: implicitWidth * fit
                        height: implicitHeight * fit
                        live: PowerProfileService.liveCaptureAllowed
                        constraintSize: Qt.size(thumb.width * 2, thumb.height * 2)
                        captureSource: card.modelData.toplevel
                    }
                }

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: thumb.bottom
                        bottom: parent.bottom
                        margins: 12
                    }
                    spacing: 10

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 32
                        source: root.iconSource(card.modelData.appId)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 42
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: card.selected ? Colors.md3.on_primary_container : Colors.md3.on_surface
                        text: card.modelData.title
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!root.controller)
                            return;
                        root.controller.index = card.index;
                        root.controller.commit();
                    }
                }
            }
        }
    }
}
