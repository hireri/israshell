import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property Component iconComponent: null
    property string label: ""
    property bool active: false
    property bool forceOff: false
    property bool offSecondary: false
    signal toggled
    signal rightClicked

    readonly property bool _on: active && !forceOff

    readonly property color bgColor: (bodyMouse.containsMouse && !forceOff)
        ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
        : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
    readonly property real bgRadius: _on ? 24 : 32

    readonly property string sublabel: Config.nightLight.scheduleEnabled
        ? ((root._on ? "Off at " : "On at ") + _formatTime(root._on ? Config.nightLight.sunrise : Config.nightLight.sunset))
        : ""

    function _formatTime(timeStr) {
        const parts = timeStr.split(":");
        const h = parseInt(parts[0], 10);
        const m = parts[1];
        if (Config.hourFormat === 0)
            return String(h).padStart(2, '0') + ":" + m;
        const hDisp = h % 12 || 12;
        const ap = h >= 12 ? "PM" : "AM";
        return hDisp + ":" + m + " " + (Config.hourFormat === 2 ? ap : ap.toLowerCase());
    }

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
                id: iconLoader
                anchors.centerIn: parent
                sourceComponent: root.iconComponent

                Binding {
                    target: iconLoader.item
                    property: "color"
                    value: root._on
                        ? Colors.md3.on_primary
                        : (root.offSecondary ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant)
                    when: iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("color")
                }
            }

            MouseArea {
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
                text: root.sublabel
                font.pixelSize: 11
                font.family: Config.fontFamily
                color: Colors.md3.on_surface_variant
                elide: Text.ElideRight
                visible: root.sublabel !== ""
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
