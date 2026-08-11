import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property Component iconComponent: null
    property string label: ""
    property string sublabel: ""
    property var sublabelForOn: null
    property bool active: false
    property bool forceOff: false
    property color accentColor: Colors.md3.primary
    property color onAccentColor: Colors.md3.on_primary
    signal toggled
    signal rightClicked

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
                value: root._on ? root.onAccentColor : Colors.md3.on_surface_variant
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
                color: root._on ? root.onAccentColor : Colors.md3.on_surface
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }

            Text {
                Layout.fillWidth: true
                text: root._effectiveSublabel
                font.pixelSize: 11
                font.family: Config.fontFamily
                font.features: ({ "tnum": 1 })
                color: root._on ? Qt.alpha(root.onAccentColor, 0.85) : Colors.md3.on_surface_variant
                elide: Text.ElideRight
                visible: root._effectiveSublabel !== ""
                renderType: Text.NativeRendering
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.toggled()
    }
}
