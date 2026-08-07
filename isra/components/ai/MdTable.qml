pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string body: ""
    property real maxWidth: 600
    property real fontSize: 14

    readonly property var _data: {
        try {
            const d = JSON.parse(root.body);
            return {
                header: d.header ?? [],
                align: d.align ?? [],
                rows: d.rows ?? []
            };
        } catch (e) {
            return {
                header: [],
                align: [],
                rows: []
            };
        }
    }
    readonly property var _rows: root._data.rows
    readonly property int _colCount: Math.max(1, root._data.header.length, ...root._rows.map(r => r.length))

    function _alignFor(col: int): int {
        const a = root._data.align[col];
        if (a === "right")
            return Text.AlignRight;
        if (a === "center")
            return Text.AlignHCenter;
        return Text.AlignLeft;
    }

    readonly property bool _scrolls: grid.implicitWidth > root.maxWidth

    implicitWidth: Math.min(grid.implicitWidth, root.maxWidth)
    implicitHeight: viewport.height + (root._scrolls ? scrollbar.height + 8 : 0)

    Flickable {
        id: viewport
        width: parent.width
        height: grid.implicitHeight
        contentWidth: grid.implicitWidth
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        GridLayout {
            id: grid
            columns: root._colCount
            rowSpacing: 10
            columnSpacing: 28

            Repeater {
                model: root._data.header

                delegate: Text {
                    id: headerText
                    required property string modelData
                    required property int index

                    Layout.row: 0
                    Layout.column: headerText.index
                    Layout.minimumWidth: 40
                    Layout.fillWidth: true
                    horizontalAlignment: root._alignFor(headerText.index)
                    text: headerText.modelData
                    textFormat: Text.MarkdownText
                    elide: Text.ElideRight
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: root.fontSize
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                }
            }

            Rectangle {
                Layout.row: 1
                Layout.column: 0
                Layout.columnSpan: root._colCount
                Layout.fillWidth: true
                height: 1
                color: Colors.md3.outline_variant
            }

            Repeater {
                model: root._rows.length * root._colCount

                delegate: Text {
                    id: bodyText
                    required property int index
                    readonly property int rowIndex: Math.floor(bodyText.index / root._colCount)
                    readonly property int colIndex: bodyText.index % root._colCount

                    Layout.row: 2 + bodyText.rowIndex
                    Layout.column: bodyText.colIndex
                    Layout.minimumWidth: 40
                    Layout.fillWidth: true
                    horizontalAlignment: root._alignFor(bodyText.colIndex)
                    text: root._rows[bodyText.rowIndex]?.[bodyText.colIndex] ?? ""
                    textFormat: Text.MarkdownText
                    elide: Text.ElideRight
                    color: Colors.md3.on_surface
                    font.pixelSize: root.fontSize
                    font.family: Config.fontFamily
                }
            }
        }
    }

    HScrollBar {
        id: scrollbar
        visible: root._scrolls
        anchors.top: viewport.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        contentX: viewport.contentX
        contentWidth: viewport.contentWidth
        viewWidth: viewport.width
        onSeek: newContentX => viewport.contentX = newContentX
    }
}
