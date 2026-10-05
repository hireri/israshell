import QtQuick
import qs.icons

Item {
    id: root

    property string text
    property string shape: "none"
    property color  fill
    property color  onFill
    property color  plainColor
    property bool   immediate: false
    property var    spinKey: null

    property string clockFont
    property real   fontSize
    property int    fontWeight
    property bool   isGoogleSansFlex
    property var    axes
    property int    measureWeight: root.fontWeight

    readonly property bool shaped: root.shape !== "none"

    FontMetrics {
        id: measure
        font.family:       root.clockFont
        font.pixelSize:    root.fontSize
        font.weight:       root.isGoogleSansFlex ? Font.Normal : root.measureWeight
        font.features:     { "tnum": 1 }
        font.variableAxes: root.isGoogleSansFlex ? Object.assign({}, root.axes, { "wght": root.measureWeight }) : ({})
    }

    readonly property real size: {
        measure.ascent;
        return Math.max(measure.advanceWidth("00") * 1.8, root.fontSize * 2);
    }

    implicitWidth:  root.shaped ? root.size : label.implicitWidth
    implicitHeight: root.shaped ? root.size : label.implicitHeight
    width:  implicitWidth
    height: implicitHeight

    property bool _armed: false
    Component.onCompleted: root._armed = true

    onSpinKeyChanged: {
        if (root._armed && root.shaped && shapeItem.symmetryStep > 0)
            shapeItem.rotationDegrees += shapeItem.symmetryStep;
    }

    MaterialShape {
        id: shapeItem
        anchors.centerIn: parent
        visible: root.shaped
        name: root.shaped ? root.shape : "circle"
        shapeSize: root.size
        color: root.fill
        immediate: root.immediate
    }

    Text {
        id: label
        anchors.centerIn: parent
        text:  root.text
        color: root.shaped ? root.onFill : root.plainColor

        font.family:       root.clockFont
        font.pixelSize:    root.fontSize
        font.weight:       root.isGoogleSansFlex ? Font.Normal : root.fontWeight
        font.features:     { "tnum": 1 }
        font.variableAxes: root.isGoogleSansFlex ? root.axes : ({})
    }
}
