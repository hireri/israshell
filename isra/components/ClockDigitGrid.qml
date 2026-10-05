import QtQuick
import qs.services

Item {
    id: root

    property int  columns: 2
    property real columnSpacing: 0
    property real rowSpacing: 0
    property real outline: 0

    property color  hourColor
    property color  minuteColor
    property string clockFont
    property real   fontSize
    property int    hourWeight
    property int    minuteWeight
    property bool   isGoogleSansFlex
    property var    hourAxes
    property var    minuteAxes

    implicitWidth:  grid.width
    implicitHeight: grid.height
    width:  implicitWidth
    height: implicitHeight

    FontMetrics {
        id: fm
        font.family:       root.clockFont
        font.pixelSize:    root.fontSize
        font.weight:       root.isGoogleSansFlex ? Font.Normal : Math.max(root.hourWeight, root.minuteWeight)
        font.features:     { "tnum": 1 }
        font.variableAxes: root.isGoogleSansFlex ? Object.assign({}, root.hourAxes, { "wght": Math.max(root.hourWeight, root.minuteWeight) }) : ({})
    }

    readonly property var _cell: {
        const ascent = fm.ascent;
        let w = 0, top = 0, bottom = 0;
        for (let i = 0; i < 10; i++) {
            const s = String(i);
            const r = fm.tightBoundingRect(s);
            w = Math.max(w, fm.advanceWidth(s));
            top = Math.min(top, r.y);
            bottom = Math.max(bottom, r.y + r.height);
        }
        return { w: w, h: bottom - top, textY: -(ascent + top) };
    }

    Grid {
        id: grid
        columns: root.columns
        columnSpacing: root.columnSpacing
        rowSpacing: root.rowSpacing

        Repeater {
            id: digits
            model: 4

            Item {
                readonly property bool isHour: index < 2

                width:  root._cell.w
                height: root._cell.h

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root._cell.textY
                    color: parent.isHour ? root.hourColor : root.minuteColor
                    text:  LocaleService.liveTime.charAt(index < 2 ? index : index + 1)

                    font.family:       root.clockFont
                    font.pixelSize:    root.fontSize
                    font.weight:       root.isGoogleSansFlex ? Font.Normal : (parent.isHour ? root.hourWeight : root.minuteWeight)
                    font.features:     { "tnum": 1 }
                    font.variableAxes: root.isGoogleSansFlex ? (parent.isHour ? root.hourAxes : root.minuteAxes) : ({})
                }
            }
        }
    }

    Loader {
        id: knockLoader
        active: root.outline > 0
        readonly property real pad: root.outline + fm.height * 0.15
        x: -pad
        y: -pad
        z: 1

        sourceComponent: ShaderEffect {
            id: knock
            width:  root.width  + 2 * knockLoader.pad
            height: root.height + 2 * knockLoader.pad

            property real radius: root.outline
            property vector2d texel: Qt.vector2d(1 / Math.max(1, width), 1 / Math.max(1, height))
            property variant d0: layer0
            property variant d1: layer1
            property variant d2: layer2
            property variant d3: layer3
            fragmentShader: Qt.resolvedUrl("../shaders/digitKnockout.frag.qsb")

            ShaderEffectSource { id: layer0; sourceItem: digits.count > 3 ? digits.itemAt(0) : null; sourceRect: root._frame(sourceItem, knock.width, knock.height, knockLoader.pad); hideSource: true; visible: false }
            ShaderEffectSource { id: layer1; sourceItem: digits.count > 3 ? digits.itemAt(1) : null; sourceRect: root._frame(sourceItem, knock.width, knock.height, knockLoader.pad); hideSource: true; visible: false }
            ShaderEffectSource { id: layer2; sourceItem: digits.count > 3 ? digits.itemAt(2) : null; sourceRect: root._frame(sourceItem, knock.width, knock.height, knockLoader.pad); hideSource: true; visible: false }
            ShaderEffectSource { id: layer3; sourceItem: digits.count > 3 ? digits.itemAt(3) : null; sourceRect: root._frame(sourceItem, knock.width, knock.height, knockLoader.pad); hideSource: true; visible: false }
        }
    }

    function _frame(item, w, h, pad) {
        return item ? Qt.rect(-item.x - pad, -item.y - pad, w, h) : Qt.rect(0, 0, 0, 0);
    }
}
