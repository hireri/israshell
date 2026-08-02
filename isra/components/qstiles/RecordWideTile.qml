import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services

Item {
    id: root

    property Component iconComponent: null
    property string label: ""
    property bool active: false
    property bool forceOff: false
    signal toggled
    signal rightClicked

    readonly property bool _on: active && !forceOff

    readonly property color bgColor: _on
        ? Colors.md3.error
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
                value: root._on ? Colors.md3.on_error : Colors.md3.on_surface_variant
                when: iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("color")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.label
                font.pixelSize: 13
                font.weight: Font.Medium
                font.family: Config.fontFamily
                color: root._on ? Colors.md3.on_error : Colors.md3.on_surface
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }

            Text {
                Layout.fillWidth: true
                text: root._on ? ScreencapService.recordingTime : "Not Recording"
                font.pixelSize: 11
                font.family: Config.fontFamily
                font.features: ({ "tnum": 1 })
                color: root._on ? Qt.alpha(Colors.md3.on_error, 0.85) : Colors.md3.on_surface_variant
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.toggled()
    }
}
