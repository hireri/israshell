import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property bool forceOff: false

    readonly property var segmentOrder: [1, 0, 2]

    readonly property int profileIndex: forceOff ? -1 : PowerProfileService.profileIndex

    readonly property color bgColor: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
    readonly property real bgRadius: 32

    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        Repeater {
            model: root.segmentOrder

            delegate: Item {
                id: segment

                required property int index
                required property int modelData

                readonly property int profileIdx: segment.modelData
                readonly property bool selected: segment.profileIdx === root.profileIndex
                readonly property bool isOuter: segment.index === 0 || segment.index === root.segmentOrder.length - 1
                readonly property bool isLeft: segment.index === 0
                readonly property bool isRight: segment.index === root.segmentOrder.length - 1

                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property color segBaseColor: selected
                    ? Colors.md3.primary
                    : Colors.md3.surface_container_highest
                readonly property real segAlpha: selected
                    ? 1
                    : (segMouse.containsMouse && !root.forceOff ? Config.blurOpacity : 0)
                readonly property color segTextColor: selected
                    ? Colors.md3.on_primary
                    : Colors.md3.on_surface_variant

                readonly property real outerRadius: parent.height / 2
                readonly property real innerRadius: 8

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(segment.segBaseColor, segment.segAlpha)

                    readonly property real leftRadius: (segment.selected || segment.isLeft) ? segment.outerRadius : segment.innerRadius
                    readonly property real rightRadius: (segment.selected || segment.isRight) ? segment.outerRadius : segment.innerRadius

                    topLeftRadius: leftRadius
                    bottomLeftRadius: leftRadius
                    topRightRadius: rightRadius
                    bottomRightRadius: rightRadius

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on topLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on topRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on bottomLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }

                PowerProfileIcon {
                    anchors.centerIn: parent
                    iconSize: 18
                    profileMode: segment.profileIdx
                    color: segment.segTextColor

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: segMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !root.forceOff
                    onClicked: PowerProfileService.setProfile(segment.profileIdx)
                }
            }
        }
    }
}
