pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.style
import qs.components

Item {
    id: root

    property var  cfg: Config.clock
    property var  time: new Date()
    property real maxScale: 1
    property bool shadow: false
    property bool live: true

    readonly property string _font: (root.cfg.fontFamily ?? "") !== "" ? root.cfg.fontFamily : Config.fontFamily
    readonly property color  _text: Colors.md3[root.cfg.colorRole] ?? Colors.md3.on_surface
    readonly property color  _sub:  Colors.md3[root.cfg.subColorRole] ?? Colors.md3.on_surface_variant
    readonly property int    _halign: root.cfg.align === "left" ? Text.AlignLeft : root.cfg.align === "right" ? Text.AlignRight : Text.AlignHCenter
    readonly property int    _analog: (root.cfg.size ?? 100) * 2

    Component {
        id: verticalComp
        ClockVertical {
            cfg: root.cfg; currentTime: root.time; clockFont: root._font; textColor: root._text; subColor: root._sub
            halign: root._halign; showSeconds: root.cfg.showSeconds ?? false; is12h: Config.hourFormat !== 0
            analogSize: root._analog; immediateShapes: true
        }
    }
    Component {
        id: horizontalComp
        ClockHorizontal {
            cfg: root.cfg; currentTime: root.time; clockFont: root._font; textColor: root._text; subColor: root._sub
            halign: root._halign; showSeconds: root.cfg.showSeconds ?? false; is12h: Config.hourFormat !== 0
            analogSize: root._analog; immediateShapes: true
        }
    }
    Component {
        id: wordComp
        ClockWord {
            cfg: root.cfg; currentTime: root.time; clockFont: root._font; textColor: root._text; subColor: root._sub
            halign: root._halign; showSeconds: root.cfg.showSeconds ?? false; is12h: Config.hourFormat !== 0
            analogSize: root._analog
        }
    }
    Component {
        id: analogComp
        ClockAnalog {
            cfg: root.cfg; currentTime: root.time; clockFont: root._font; textColor: root._text; subColor: root._sub
            halign: root._halign; showSeconds: root.cfg.showSeconds ?? false; is12h: Config.hourFormat !== 0
            analogSize: root._analog; immediateShapes: true
        }
    }

    Item {
        id: box
        anchors.centerIn: parent
        width: loader.item?.implicitWidth ?? 0
        height: loader.item?.implicitHeight ?? 0
        scale: Math.min(root.maxScale, root.width / Math.max(1, box.width), root.height / Math.max(1, box.height))

        layer.enabled: root.shadow
        layer.effect: MultiEffect {
            shadowEnabled: root.cfg.showShadow ?? true
            shadowBlur: (root.cfg.shadowBlur ?? 16) / 32
            shadowColor: Qt.alpha("black", root.cfg.shadowOpacity ?? 0.2)
            shadowHorizontalOffset: root.cfg.shadowX ?? 0
            shadowVerticalOffset: root.cfg.shadowY ?? 0
        }

        Loader {
            id: loader
            active: root.live

            property var activeComponent: null
            readonly property var targetComponent: ({
                "horizontal": horizontalComp,
                "word": wordComp,
                "analog": analogComp
            })[root.cfg.layout] ?? verticalComp

            onTargetComponentChanged: if (root.live && activeComponent !== null) swap.restart(); else activeComponent = targetComponent
            sourceComponent: activeComponent
            Component.onCompleted: activeComponent = targetComponent

            SequentialAnimation {
                id: swap
                ParallelAnimation {
                    NumberAnimation { target: loader; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                    NumberAnimation { target: loader; property: "scale"; to: 0.9; duration: 150; easing.type: Easing.OutCubic }
                }
                ScriptAction { script: loader.activeComponent = loader.targetComponent }
                ParallelAnimation {
                    NumberAnimation { target: loader; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                    NumberAnimation { target: loader; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
