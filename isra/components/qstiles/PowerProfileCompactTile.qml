import QtQuick
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property bool forceOff: false

    readonly property var profileColors: [Colors.md3.secondary_container, Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity), Colors.md3.primary]
    readonly property var profileColorsHover: [Qt.lighter(Colors.md3.secondary_container, 1.12), Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity), Colors.md3.primary]
    readonly property var profileTextColors: [Colors.md3.on_secondary_container, Colors.md3.on_surface_variant, Colors.md3.on_primary]

    readonly property int profileIndex: forceOff ? 1 : PowerProfileService.profileIndex

    readonly property color bgColor: (ppMouse.containsMouse && !forceOff) ? root.profileColorsHover[profileIndex] : root.profileColors[profileIndex]
    readonly property real bgRadius: profileIndex === 2 ? 14 : (profileIndex === 0 ? 23 : 32)

    anchors.fill: parent

    PowerProfileIcon {
        anchors.centerIn: parent
        iconSize: 20
        profileMode: root.profileIndex
        color: root.profileTextColors[root.profileIndex]

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: ppMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton
            ? PowerProfileService.cycle(-1)
            : PowerProfileService.cycle(1)
    }
}
