import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property Component iconComponent: null
    property string label: ""
    property string sublabel: ""
    property var sublabelForOn: null
    property string peekSublabel: ""
    property bool active: false
    property bool forceOff: false
    property color accentColor: Colors.md3.primary
    property color accentContentColor: Colors.md3.on_primary
    signal toggled
    signal rightClicked
    signal wheelStep(int steps)

    readonly property bool _on: active && !forceOff
    readonly property string _effectiveSublabel: sublabelForOn ? sublabelForOn(_on) : sublabel

    readonly property color bgColor: _on
        ? root.accentColor
        : ((mouseArea.containsMouse && !forceOff)
            ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
            : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity))
    readonly property real bgRadius: _on ? 24 : 32

    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.leftMargin: 21
        spacing: 12

        Loader {
            id: iconLoader
            sourceComponent: root.iconComponent

            Binding {
                target: iconLoader.item
                property: "color"
                value: root._on ? root.accentContentColor : Colors.md3.on_surface_variant
                when: iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("color")
            }
            Binding {
                target: iconLoader.item
                property: "filled"
                value: false
                when: root.forceOff && iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("filled")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.label
                font.family: Config.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                color: root._on ? root.accentContentColor : Colors.md3.on_surface
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }

            Text {
                id: subText
                property string _shown: root._effectiveSublabel
                Layout.fillWidth: true
                text: _shown
                font.pixelSize: 11
                font.family: Config.fontFamily
                font.features: ({ "tnum": 1 })
                color: root._on ? Qt.alpha(root.accentContentColor, 0.85) : Colors.md3.on_surface_variant
                elide: Text.ElideRight
                visible: text !== ""
                renderType: Text.NativeRendering

                Binding {
                    target: subText
                    property: "_shown"
                    value: root._effectiveSublabel
                    when: root.peekSublabel === "" && !subFade.running
                }

                SequentialAnimation {
                    id: subFade
                    NumberAnimation {
                        target: subText
                        property: "opacity"
                        to: 0
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    ScriptAction {
                        script: subText._shown = root._effectiveSublabel
                    }
                    NumberAnimation {
                        target: subText
                        property: "opacity"
                        to: 1
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    onPeekSublabelChanged: {
        if (peekSublabel !== "") {
            subFade.stop();
            subText._shown = peekSublabel;
            subText.opacity = 1;
        } else if (subText._shown !== root._effectiveSublabel) {
            subFade.restart();
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.toggled()

        property real _wheelAccum: 0
        onWheel: wheel => {
            _wheelAccum += wheel.angleDelta.y;
            let steps = 0;
            while (_wheelAccum >= 120) {
                _wheelAccum -= 120;
                steps++;
            }
            while (_wheelAccum <= -120) {
                _wheelAccum += 120;
                steps--;
            }
            if (steps !== 0)
                root.wheelStep(steps);
        }
    }
}
