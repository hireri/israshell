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

    property bool offSecondary: false
    signal toggled
    signal rightClicked

    readonly property bool _on: active && !forceOff
    readonly property bool _hovered: (bodyMouse.containsMouse || iconMouse.containsMouse) && !forceOff
    readonly property string _effectiveSublabel: sublabelForOn ? sublabelForOn(_on) : sublabel

    readonly property color bgColor: _hovered
        ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
        : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
    readonly property real bgRadius: _on ? 24 : 32

    property color iconColor: root._on
        ? Colors.md3.on_primary
        : (root.offSecondary ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant)

    Behavior on iconColor { ColorAnimation { duration: 150 } }

    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        Rectangle {
            id: iconContainer
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            radius: root._on ? 16 : 24
            color: root._on
                ? Colors.md3.primary
                : (root.offSecondary ? Colors.md3.secondary_container : Qt.alpha(Colors.md3.surface_container, Config.blurOpacity))

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Loader {
                id: wideIconLoader
                anchors.centerIn: parent
                sourceComponent: root.iconComponent

                Binding {
                    target: wideIconLoader.item
                    property: "color"
                    value: root.iconColor
                    when: wideIconLoader.status === Loader.Ready && wideIconLoader.item && wideIconLoader.item.hasOwnProperty("color")
                }
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.toggled()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.label
                font.pixelSize: 13
                font.weight: Font.Medium
                font.family: Config.fontFamily
                color: Colors.md3.on_surface
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }

            Text {
                Layout.fillWidth: true
                text: root._effectiveSublabel
                font.pixelSize: 11
                font.family: Config.fontFamily
                color: Colors.md3.on_surface_variant
                elide: Text.ElideRight
                visible: root._effectiveSublabel !== ""
                renderType: Text.NativeRendering
            }
        }
    }

    MouseArea {
        id: bodyMouse
        anchors.fill: parent
        anchors.leftMargin: 56
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: root.rightClicked()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.rightClicked()
    }
}
