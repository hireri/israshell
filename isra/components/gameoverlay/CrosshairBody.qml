import QtQuick
import qs.services
import qs.style
import "crosshair.js" as Crosshair

Item {
    id: root

    readonly property var cfg: GameOverlayService.crosshair
    readonly property int reach: Crosshair.reach(root.cfg)
    readonly property int outline: root.cfg.outline.on ? root.cfg.outline.thickness : 0

    implicitWidth: root.reach * 2
    implicitHeight: root.reach * 2

    component Mark: Rectangle {
        id: mark

        property bool ring: false
        property real fillOpacity: 1
        property real ox
        property real oy
        property real ow
        property real oh
        readonly property int inset: mark.ring ? 0 : root.outline

        x: mark.ox + mark.inset
        y: mark.oy + mark.inset
        width: mark.ow - mark.inset * 2
        height: mark.oh - mark.inset * 2
        color: mark.ring ? "transparent" : Qt.alpha(root.cfg.color, mark.fillOpacity)
        border.width: mark.ring ? root.outline : 0
        border.color: Qt.alpha("black", root.cfg.outline.opacity)
    }

    component Elements: Item {
        id: elements

        property bool ring: false

        anchors.fill: parent

        Mark {
            ring: elements.ring
            visible: root.cfg.dot.on && root.cfg.dot.size > 0
            fillOpacity: root.cfg.dot.opacity
            ow: root.cfg.dot.size + root.outline * 2
            oh: ow
            ox: Math.floor((elements.width - ow) / 2)
            oy: Math.floor((elements.height - oh) / 2)
        }

        Repeater {
            model: ["inner", "outer"]

            delegate: Item {
                id: lines
                required property string modelData
                readonly property var line: root.cfg[modelData]

                anchors.fill: parent
                visible: line.on && line.thickness > 0

                Repeater {
                    model: 4

                    delegate: Mark {
                        required property int index
                        readonly property var ln: lines.line
                        readonly property bool horizontal: index % 2 === 0
                        readonly property real length: horizontal ? ln.length : ln.vlength
                        readonly property real thick: ln.thickness
                        readonly property real cx: elements.width / 2
                        readonly property real cy: elements.height / 2

                        ring: elements.ring
                        fillOpacity: ln.opacity
                        visible: length > 0
                        ow: (horizontal ? length : thick) + root.outline * 2
                        oh: (horizontal ? thick : length) + root.outline * 2
                        ox: Math.floor(index === 0 ? cx + ln.offset - root.outline : index === 2 ? cx - ln.offset - length - root.outline : cx - thick / 2 - root.outline)
                        oy: Math.floor(index === 1 ? cy + ln.offset - root.outline : index === 3 ? cy - ln.offset - length - root.outline : cy - thick / 2 - root.outline)
                    }
                }
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: root.reach * 2
        height: root.reach * 2

        Elements {
            ring: true
            visible: root.outline > 0
        }

        Elements {}
    }
}
