pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.style
import qs.services

Item {
    id: root

    property var categories: ({})
    property real thickness: 26
    property real corner: 4
    property real gap: 2
    default property alias center: centerSlot.data

    readonly property var order: ["work", "web", "fun", "other"]

    property real wWork: root.categories["work"] ?? 0
    property real wWeb: root.categories["web"] ?? 0
    property real wFun: root.categories["fun"] ?? 0
    property real wOther: root.categories["other"] ?? 0

    Behavior on wWork {
        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
    }

    Behavior on wWeb {
        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
    }

    Behavior on wFun {
        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
    }

    Behavior on wOther {
        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
    }

    readonly property var shown: [root.wWork, root.wWeb, root.wFun, root.wOther]
    readonly property real total: root.wWork + root.wWeb + root.wFun + root.wOther

    function startOf(i: int): real {
        return root.total > 0 ? root.shown.slice(0, i).reduce((a, v) => a + v, 0) / root.total * 360 : 0;
    }

    function endOf(i: int): real {
        return root.total > 0 ? root.startOf(i) + root.shown[i] / root.total * 360 : 0;
    }

    implicitWidth: 200
    implicitHeight: 200

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        DonutSeg {
            cx: root.width / 2
            cy: root.height / 2
            outer: root.width / 2
            inner: root.width / 2 - root.thickness
            start: 0
            end: 360
            color: Config.dim(Colors.md3.surface_container_highest)
        }

        DonutSeg {
            cx: root.width / 2
            cy: root.height / 2
            outer: root.width / 2
            inner: root.width / 2 - root.thickness
            corner: root.corner
            gap: root.gap
            start: root.startOf(0)
            end: root.endOf(0)
            color: ScreenTimeService.categoryColor("work")
        }

        DonutSeg {
            cx: root.width / 2
            cy: root.height / 2
            outer: root.width / 2
            inner: root.width / 2 - root.thickness
            corner: root.corner
            gap: root.gap
            start: root.startOf(1)
            end: root.endOf(1)
            color: ScreenTimeService.categoryColor("web")
        }

        DonutSeg {
            cx: root.width / 2
            cy: root.height / 2
            outer: root.width / 2
            inner: root.width / 2 - root.thickness
            corner: root.corner
            gap: root.gap
            start: root.startOf(2)
            end: root.endOf(2)
            color: ScreenTimeService.categoryColor("fun")
        }

        DonutSeg {
            cx: root.width / 2
            cy: root.height / 2
            outer: root.width / 2
            inner: root.width / 2 - root.thickness
            corner: root.corner
            gap: root.gap
            start: root.startOf(3)
            end: root.endOf(3)
            color: ScreenTimeService.categoryColor("other")
        }
    }

    Item {
        id: centerSlot
        anchors.fill: parent
    }
}
