pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services

MouseArea {
    id: group

    property string appName: ""
    property bool showAll: false
    property bool inPanel: false
    property bool popup: false
    property var listRef: null
    property int groupIdx: 0

    property int dragIndex: -1
    property real dragDistance: 0

    function resetDrag() {
        dragIndex = -1;
        dragDistance = 0;
    }

    readonly property var notifs: {
        const _ = NotificationService.listCount;
        return NotificationService.list.filter(w => w.appName === group.appName && (group.showAll || w.popup)).reverse();
    }
    readonly property int count: notifs.length

    readonly property string groupIcon: {
        if (notifs.length === 0)
            return Quickshell.iconPath("", "application-x-executable");
        return Quickshell.iconPath(notifs[0].appIcon, "application-x-executable");
    }
    readonly property string groupImage: notifs.length > 0 ? (notifs[0].image ?? "") : ""
    readonly property bool groupHasBadge: groupImage.length > 0 && (notifs.length > 0 && (notifs[0].appIcon?.length ?? 0) > 0)

    property bool expandedState: false
    property bool isDragging: false

    onNotifsChanged: if (count > 0 && !containsMouse)
        groupTimer.restart()

    Timer {
        id: groupTimer
        interval: {
            if (group.notifs.length === 0)
                return 5000;
            const t = group.notifs[0].notification?.expireTimeout ?? 0;
            return t > 0 ? t : 5000;
        }
        running: false
        onTriggered: NotificationService.sendGroupToPanel(group.appName)
    }

    hoverEnabled: true
    onContainsMouseChanged: {
        if (!group.popup)
            return;
        if (containsMouse)
            groupTimer.stop();
        else if (group.count > 0)
            groupTimer.restart();
    }

    acceptedButtons: Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            group.expandedState = !group.expandedState;
    }

    property real cardX: 0
    property bool dismissing: false
    readonly property real dismissThreshold: 70

    Behavior on cardX {
        enabled: !group.isDragging && !group.dismissing
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: group.listRef
        enabled: group.listRef !== null

        function onDragDistanceChanged() {
            if (group.isDragging)
                return;
            if (group.dismissing)
                return;
            const idx = group.listRef.dragIndex;
            if (idx < 0)
                return;
            const d = group.listRef.dragDistance;
            const diff = Math.abs(idx - group.groupIdx);
            if (Math.abs(d) > group.dismissThreshold && diff !== 0) {
                group.cardX = 0;
                return;
            }
            if (diff === 1)
                group.cardX = d * 0.3;
            else if (diff === 2)
                group.cardX = d * 0.1;
            else if (diff > 2)
                group.cardX = 0;
        }

        function onDragIndexChanged() {
            if (group.isDragging)
                return;
            if (group.listRef.dragIndex < 0 && !group.dismissing)
                group.cardX = 0;
        }
    }

    function _handleRelease(diffX, velocityX) {
        group.isDragging = false;
        const fling = Math.abs(velocityX) > 0.5;
        const pastThresh = Math.abs(diffX) > group.dismissThreshold;

        if (pastThresh || fling) {
            const dir = diffX !== 0 ? Math.sign(diffX) : Math.sign(velocityX);
            group.dismissing = true;
            if (group.listRef)
                group.listRef.resetDrag();
            _dismissAnim.toX = dir * (group.implicitWidth + 60);
            _dismissAnim.start();
        } else {
            if (group.listRef)
                group.listRef.resetDrag();
            group.cardX = 0;
        }
    }

    SequentialAnimation {
        id: _dismissAnim
        property real toX: 0

        NumberAnimation {
            target: group
            property: "cardX"
            to: _dismissAnim.toX
            duration: 220
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: {
                NotificationService.sendGroupToPanel(group.appName);
                Qt.callLater(() => group.notifs.slice().forEach(w => w.notification?.dismiss()));
            }
        }
    }

    DragManager {
        id: mainDrag
        anchors.fill: parent
        interactive: !group.expandedState || group.count <= 1
        automaticallyReset: false

        onDraggingChanged: {
            if (dragging) {
                group.isDragging = true;
                if (group.listRef) {
                    group.listRef.dragIndex = group.groupIdx;
                    group.listRef.dragDistance = 0;
                }
            }
        }
        onDragDiffXChanged: {
            if (!dragging)
                return;

            group.cardX = dragDiffX;

            if (group.listRef)
                group.listRef.dragDistance = dragDiffX;
        }
        onDragReleased: (diffX, diffY, velocityX) => {
            group._handleRelease(diffX, velocityX);
        }
    }

    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight

    Rectangle {
        id: background
        anchors.left: parent.left
        anchors.top: parent.top
        width: parent.width

        implicitWidth: 320
        implicitHeight: cardContent.implicitHeight + 24

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        color: Colors.md3.surface_container_high
        radius: 8
        border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)
        border.width: 1
        clip: true

        transform: Translate {
            x: group.cardX
        }

        ColumnLayout {
            id: cardContent
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 8

            Item {
                id: headerRow
                Layout.fillWidth: true
                implicitHeight: headerLayout.implicitHeight

                RowLayout {
                    id: headerLayout
                    anchors.fill: parent
                    spacing: 8

                    Text {
                        text: group.appName
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: group.count > 1
                        implicitWidth: cntLbl.implicitWidth + 10
                        implicitHeight: 18
                        radius: 9
                        color: Colors.md3.primary_container

                        Text {
                            id: cntLbl
                            anchors.centerIn: parent
                            text: group.count
                            color: Colors.md3.on_primary_container
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        text: "Dismiss all"
                        color: Colors.md3.primary
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        visible: group.expandedState && group.count > 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                mouse.accepted = true;
                                group.notifs.slice().forEach(w => w.notification?.dismiss());
                            }
                        }
                    }

                    Rectangle {
                        id: expandPill
                        implicitWidth: 28
                        implicitHeight: 18
                        radius: 9
                        color: Colors.md3.surface_container_highest

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 11
                            rotation: group.expandedState ? 180 : 0
                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                mouse.accepted = true;
                                group.expandedState = !group.expandedState;
                            }
                        }
                    }
                }

                DragManager {
                    id: headerDrag
                    anchors.left: parent.left
                    anchors.right: expandPill.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    interactive: group.expandedState && group.count > 1
                    automaticallyReset: false

                    onDraggingChanged: {
                        if (dragging) {
                            group.isDragging = true;
                            if (group.listRef) {
                                group.listRef.dragIndex = group.groupIdx;
                                group.listRef.dragDistance = 0;
                            }
                        }
                    }
                    onDragDiffXChanged: {
                        if (!dragging)
                            return;
                        group.cardX = dragDiffX;
                        if (group.listRef)
                            group.listRef.dragDistance = dragDiffX;
                    }
                    onDragReleased: (diffX, diffY, velocityX) => {
                        group._handleRelease(diffX, velocityX);
                    }
                }
            }

            RowLayout {
                visible: !group.expandedState
                Layout.fillWidth: true
                spacing: 10

                Item {
                    implicitWidth: 44
                    implicitHeight: 44
                    visible: group.notifs.length > 0

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 10
                        color: Colors.md3.surface_container
                        clip: true
                        visible: group.groupImage.length > 0

                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: group.groupImage
                            asynchronous: true
                        }
                    }

                    ClippingRectangle {
                        visible: group.groupImage.length === 0 || group.groupHasBadge
                        implicitWidth: group.groupHasBadge ? 18 : 44
                        implicitHeight: group.groupHasBadge ? 18 : 44
                        radius: group.groupHasBadge ? 5 : 10
                        clip: true
                        color: Colors.md3.surface_container_high
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: group.groupHasBadge ? -2 : 0
                        anchors.bottomMargin: group.groupHasBadge ? -2 : 0

                        IconImage {
                            anchors.fill: parent
                            anchors.margins: 3
                            source: group.groupIcon
                            asynchronous: true
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: ScriptModel {
                            values: group.notifs.slice(0, 2)
                        }
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.summary
                                color: Colors.md3.on_surface
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: modelData.summary !== group.appName
                            }

                            Text {
                                color: Colors.md3.on_surface_variant
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                textFormat: Text.PlainText
                                text: modelData.body.length > 0 ? modelData.body : modelData.summary
                                visible: modelData.body.length > 0 || modelData.summary === group.appName
                            }
                        }
                    }

                    Item {
                        id: collapsedActsContainer
                        readonly property var acts: {
                            if (group.notifs.length === 0)
                                return [];
                            return group.notifs[0]?.notification?.actions || [];
                        }
                        visible: acts.length > 0
                        Layout.fillWidth: true
                        implicitHeight: cActFlick.implicitHeight

                        Flickable {
                            id: cActFlick
                            anchors.fill: parent
                            contentWidth: cActRow.implicitWidth
                            implicitHeight: cActRow.implicitHeight
                            clip: true
                            flickableDirection: Flickable.HorizontalFlick
                            ScrollBar.horizontal: ScrollBar {
                                policy: ScrollBar.AlwaysOff
                            }

                            RowLayout {
                                id: cActRow
                                spacing: 6

                                Repeater {
                                    model: ScriptModel {
                                        values: collapsedActsContainer.acts
                                    }
                                    delegate: Rectangle {
                                        required property var modelData
                                        implicitWidth: caLbl.implicitWidth + 24
                                        implicitHeight: 32
                                        radius: 8
                                        color: caHov.containsMouse ? Colors.md3.secondary_container : Colors.md3.surface_container

                                        Text {
                                            id: caLbl
                                            anchors.centerIn: parent
                                            text: modelData.text || ""
                                            color: Colors.md3.on_surface
                                            font.family: Config.fontFamily
                                            font.pixelSize: 12
                                        }
                                        MouseArea {
                                            id: caHov
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: mouse => {
                                                mouse.accepted = true;
                                                modelData.invoke();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                visible: group.expandedState
                Layout.fillWidth: true
                implicitHeight: group.inPanel ? expandedCol.implicitHeight : Math.min(expandedCol.implicitHeight, 480)

                Flickable {
                    anchors.fill: parent
                    contentHeight: expandedCol.implicitHeight
                    interactive: !group.inPanel && group.count > 1
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    Column {
                        id: expandedCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: ScriptModel {
                                values: group.notifs
                            }
                            delegate: NotificationItem {
                                required property var modelData
                                required property int index
                                wrapper: modelData
                                groupRef: group
                                itemIndex: index
                                implicitWidth: expandedCol.width
                            }
                        }
                    }
                }
            }
        }
    }
}
