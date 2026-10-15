import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.icons
import qs.components

Item {
    id: root

    property bool forceOff: false

    readonly property var segmentOrder: [1, 0, 2]

    readonly property int profileIndex: forceOff ? -1 : PowerProfileService.profileIndex

    readonly property color bgColor: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
    readonly property real bgRadius: 32

    anchors.fill: parent

    Item {
        id: track
        anchors.fill: parent
        anchors.margins: 6
        readonly property real segW: (width - 4 * (root.segmentOrder.length - 1)) / root.segmentOrder.length

        SlidingIndicator {
            id: profileInd
            index: root.segmentOrder.indexOf(root.profileIndex)
            step: track.segW + 4
            inset: 0
            size: track.segW
            color: Colors.md3.primary
        }

        RowLayout {
            anchors.fill: parent
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

                    readonly property real segAlpha: !selected && segMouse.containsMouse && !root.forceOff ? Config.blurOpacity : 0

                    readonly property real outerRadius: parent.height / 2
                    readonly property real innerRadius: 8

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.alpha(Colors.md3.surface_container_highest, segment.segAlpha)

                        readonly property real leftRadius: segment.isLeft ? segment.outerRadius : segment.innerRadius
                        readonly property real rightRadius: segment.isRight ? segment.outerRadius : segment.innerRadius

                        topLeftRadius: leftRadius
                        bottomLeftRadius: leftRadius
                        topRightRadius: rightRadius
                        bottomRightRadius: rightRadius

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    PowerProfileIcon {
                        anchors.centerIn: parent
                        iconSize: 18
                        profileMode: segment.profileIdx
                        color: profileInd.covers(segment.x + segment.width / 2) ? Colors.md3.on_primary : Colors.md3.on_surface_variant
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
}
