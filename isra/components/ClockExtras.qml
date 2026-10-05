import QtQuick
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    required property var face
    property real unit: 64

    readonly property bool hasSeconds: root.face.showSeconds
    readonly property bool hasPeriod:  root.face.showPeriod

    visible: root.hasSeconds || root.hasPeriod

    implicitWidth:  root.face.tiled ? tiles.implicitWidth : stack.implicitWidth
    implicitHeight: root.face.tiled ? root.unit : stack.implicitHeight

    readonly property real  _secSize: root.unit * 0.62
    readonly property real  _badge:   root.hasSeconds ? root._secSize * 0.55 : root.unit * 0.5
    readonly property color _tint:    Colors.md3.tertiary_container
    readonly property color _onTint:  Colors.md3.on_tertiary_container

    component Label: Text {
        font.family:       root.face.clockFont
        font.weight:       root.face.isGoogleSansFlex ? Font.Normal : root.face.subWeight
        font.features:     { "tnum": 1 }
        font.variableAxes: root.face.isGoogleSansFlex ? root.face.subAxes : ({})
    }

    Item {
        id: tiles
        visible: root.face.tiled
        implicitWidth:  root.hasSeconds ? root._secSize + root._badge * 0.5 : root._badge
        implicitHeight: root.unit

        Item {
            visible: root.hasSeconds
            width:  root._secSize
            height: root._secSize
            y: (root.unit - height) / 2

            MaterialShape {
                anchors.centerIn: parent
                name: "sunny"
                shapeSize: parent.width
                color: root._tint
                immediate: root.face.immediateShapes
            }
            Label {
                anchors.centerIn: parent
                text: LocaleService.liveSecs
                color: root._onTint
                font.pixelSize: parent.width * 0.4
            }
        }

        Item {
            visible: root.hasPeriod
            width:  root._badge
            height: root._badge
            x: root.hasSeconds ? root._secSize - width * 0.5 : 0
            y: root.hasSeconds ? (root.unit - root._secSize) / 2 - height * 0.45 : (root.unit - height) / 2

            MaterialShape {
                anchors.centerIn: parent
                name: root.hasSeconds ? "circle" : "cookie12"
                shapeSize: parent.width
                color: root.hasSeconds ? root.face.tileFill(root.face.cfg.colorRole ?? "primary") : root._tint
                immediate: root.face.immediateShapes
            }
            Label {
                anchors.centerIn: parent
                text: root.face.periodWord(root.face.pm)
                color: root.hasSeconds ? root.face.tileOnFill(root.face.cfg.colorRole ?? "primary") : root._onTint
                font.pixelSize: parent.width * 0.36
            }
        }
    }

    ColumnLayout {
        id: stack
        visible: !root.face.tiled
        spacing: root.unit * 0.08

        Label {
            visible: root.hasSeconds
            Layout.alignment: Qt.AlignHCenter
            text: ":" + LocaleService.liveSecs
            color: root.face.subColor
            font.pixelSize: root.unit * 0.38
        }

        ClockPeriod {
            visible: root.hasPeriod
            Layout.alignment: Qt.AlignHCenter
            pm:    root.face.pm
            color: root.face.subColor

            clockFont:        root.face.clockFont
            fontSize:         root.unit * 0.3
            fontWeight:       root.face.subWeight
            isGoogleSansFlex: root.face.isGoogleSansFlex
            axes:             root.face.subAxes
        }
    }
}
