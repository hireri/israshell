import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services

MouseArea {
    id: group

    property string appName: ""
    property string groupSummary: ""
    property bool showAll: false
    property bool inPanel: false
    property bool popup: false
    property var listRef: null
    property int groupIdx: 0

    readonly property string groupKey: appName + "|" + groupSummary

    property int dragIndex: -1
    property real dragDistance: 0
    function resetDrag() {
        dragIndex = -1;
        dragDistance = 0;
    }

    readonly property var notifs: {
        const _ = NotificationService.listCount;
        return NotificationService.list.filter(w => w.groupKey === group.groupKey && (group.showAll || w.popup)).reverse();
    }
    readonly property int count: notifs.length
    readonly property var latest: notifs.length > 0 ? notifs[0] : null
    readonly property var latestActions: latest?.notification?.actions ?? []

    property string _image: ""
    property string _icon: Quickshell.iconPath("", "application-x-executable")
    property bool _hasBadge: false
    property string _summary: groupSummary
    property string _appName: appName

    onNotifsChanged: {
        if (notifs.length > 0) {
            const n = notifs[0];
            _image = n.image ?? "";
            _icon = Quickshell.iconPath(n.appIcon ?? "", "application-x-executable");
            _hasBadge = _image.length > 0 && (n.appIcon?.length ?? 0) > 0;
            _summary = groupSummary;
            _appName = appName;
            if (group.popup && !containsMouse && n.notification !== null)
                groupTimer.restart();
        }
    }

    function _cap(s) {
        return s.replace(/\b\w/g, c => c.toUpperCase());
    }

    property bool expandedState: false
    property bool isDragging: false
    property bool dismissing: false
    property bool timerExpiry: false
    property real cardX: 0
    property real cardOpacity: 1.0

    Component.onCompleted: {
        if (group.popup) {
            card.implicitHeight = 0;
            Qt.callLater(() => {
                card.implicitHeight = Qt.binding(() => cardCol.implicitHeight + 24);
            });
        }
    }

    onCountChanged: {
        if (count === 0 && !group.dismissing) {
            group.dismissing = true;
            _shrinkAnim.start();
        }
    }

    Timer {
        id: groupTimer
        interval: {
            if (group.notifs.length === 0)
                return 5000;
            const t = group.notifs[0].notification?.expireTimeout ?? 0;
            return t > 0 ? t : 5000;
        }
        running: false
        onTriggered: {
            if (group.notifs.length > 0 && !group.notifs[0].notification) {
                groupTimer.stop();
                return;
            }
            group.timerExpiry = true;
            group.dismissing = true;
            _dismissAnim.toX = 0;
            _dismissAnim.start();
        }
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
            if (group.isDragging || group.dismissing)
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
            if (group.isDragging || group.dismissing)
                return;
            if (group.listRef.dragIndex < 0)
                group.cardX = 0;
        }
    }

    function _handleRelease(diffX, velocityX) {
        group.isDragging = false;
        const fling = Math.abs(velocityX) > 0.5;
        const past = Math.abs(diffX) > group.dismissThreshold;
        if (past || fling) {
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
        ParallelAnimation {
            NumberAnimation {
                target: group
                property: "cardX"
                to: _dismissAnim.toX
                duration: 240
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: group
                property: "cardOpacity"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        ScriptAction {
            script: {
                if (group.inPanel)
                    group.notifs.slice().forEach(w => w.notification?.dismiss());
                else
                    NotificationService.sendGroupToPanel(group.appName, group.groupSummary);
                group.timerExpiry = false;
            }
        }
    }

    SequentialAnimation {
        id: _shrinkAnim
        ParallelAnimation {
            NumberAnimation {
                target: group
                property: "cardOpacity"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: card
                property: "implicitHeight"
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }

    DragManager {
        id: mainDrag
        anchors.fill: parent
        interactive: true
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

    implicitWidth: shadow.implicitWidth
    implicitHeight: shadow.implicitHeight

    Item {
        id: shadow
        anchors.left: parent.left
        anchors.top: parent.top
        width: parent.width
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight + 10

        transform: Translate {
            x: group.cardX
        }
        opacity: group.cardOpacity

        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            blur: 20
            color: Qt.rgba(0, 0, 0, 0.25)
            offset: Qt.vector2d(0, 4)
            antialiasing: true
        }

        Rectangle {
            id: card
            anchors.left: parent.left
            anchors.top: parent.top
            width: parent.width
            implicitWidth: group.width > 0 ? group.width : 320
            implicitHeight: cardCol.implicitHeight + 24

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.2
                }
            }

            radius: 18
            color: Colors.md3.surface_container_high
            clip: true

            ColumnLayout {
                id: cardCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        Layout.alignment: Qt.AlignTop

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Colors.md3.surface_container
                            visible: group._image.length > 0

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: group._image
                                asynchronous: true
                            }
                        }

                        ClippingRectangle {
                            visible: group._image.length === 0 || group._hasBadge
                            implicitWidth: group._hasBadge ? 22 : 44
                            implicitHeight: group._hasBadge ? 22 : 44
                            radius: group._hasBadge ? 7 : 14
                            color: Colors.md3.surface_container
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: group._hasBadge ? -3 : 0
                            anchors.bottomMargin: group._hasBadge ? -3 : 0

                            IconImage {
                                anchors.fill: parent
                                anchors.margins: group._hasBadge ? 2 : 6
                                source: group._icon
                                asynchronous: true
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        Text {
                            visible: group._summary.length > 0 && group._summary !== group._appName
                            text: group._cap(group._appName)
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: group._summary.length > 0 ? group._summary : group._cap(group._appName)
                            color: Colors.md3.on_surface
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        visible: group.count > 1 || bodyItem.latestOverflows
                        implicitWidth: pillRow.implicitWidth + 14
                        implicitHeight: 22
                        radius: 11
                        color: pillHov.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        RowLayout {
                            id: pillRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                visible: group.count > 1
                                text: group.count
                                color: Colors.md3.on_surface_variant
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: ""
                                color: Colors.md3.on_surface_variant
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                rotation: group.expandedState ? 180 : 0
                                Behavior on rotation {
                                    NumberAnimation {
                                        duration: 220
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: pillHov
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: mouse => {
                                mouse.accepted = true;
                                group.expandedState = !group.expandedState;
                            }
                        }
                    }
                }

                Item {
                    id: bodyItem
                    Layout.fillWidth: true
                    clip: true

                    readonly property real lineH: Math.round(13 * 1.45)
                    readonly property real maxH: lineH * 3
                    readonly property bool latestOverflows: latestText.implicitHeight > maxH
                    readonly property bool hasHidden: group.count > 1 && !latestOverflows

                    implicitHeight: group.expandedState ? expandedBody.implicitHeight : (latestOverflows ? maxH : Math.min(latestText.implicitHeight + (hasHidden ? (group.count - 1) * (lineH + 2) : 0), maxH))

                    Behavior on implicitHeight {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }

                    Column {
                        id: collapsedBody
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        visible: !group.expandedState
                        spacing: 2
                        padding: 4
                        bottomPadding: 8

                        Repeater {
                            model: ScriptModel {
                                values: !bodyItem.latestOverflows ? group.notifs.slice(1).reverse() : []
                            }
                            delegate: Text {
                                required property var modelData
                                width: collapsedBody.width
                                text: modelData.body.length > 0 ? modelData.body : modelData.summary
                                color: Colors.md3.on_surface_variant
                                opacity: 0.6
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                textFormat: Text.RichText
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: latestText
                            width: collapsedBody.width
                            text: group.latest ? (group.latest.body.length > 0 ? group.latest.body : group.latest.summary) : ""
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    Column {
                        id: expandedBody
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        visible: group.expandedState
                        spacing: 6
                        bottomPadding: 10

                        Repeater {
                            model: ScriptModel {
                                values: {
                                    const arr = group.notifs.slice();
                                    arr.reverse();
                                    return arr;
                                }
                            }
                            delegate: NotificationItem {
                                required property var modelData
                                required property int index
                                wrapper: modelData
                                groupRef: group
                                itemIndex: index
                                width: expandedBody.width
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 20
                        visible: !group.expandedState && bodyItem.latestOverflows
                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: Qt.rgba(Colors.md3.surface_container_high.r, Colors.md3.surface_container_high.g, Colors.md3.surface_container_high.b, 0)
                            }
                            GradientStop {
                                position: 1.0
                                color: Colors.md3.surface_container_high
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: 20
                        visible: !group.expandedState && bodyItem.hasHidden
                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: Colors.md3.surface_container_high
                            }
                            GradientStop {
                                position: 1.0
                                color: Qt.rgba(Colors.md3.surface_container_high.r, Colors.md3.surface_container_high.g, Colors.md3.surface_container_high.b, 0)
                            }
                        }
                    }
                }

                Item {
                    visible: group.latestActions.length > 0
                    Layout.fillWidth: true
                    implicitHeight: actFlick.implicitHeight

                    Flickable {
                        id: actFlick
                        anchors.fill: parent
                        contentWidth: actRow.implicitWidth
                        implicitHeight: actRow.implicitHeight
                        interactive: actRow.implicitWidth > width
                        clip: actRow.implicitWidth > width
                        flickableDirection: Flickable.HorizontalFlick
                        ScrollBar.horizontal: ScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }

                        RowLayout {
                            id: actRow
                            spacing: 6

                            Repeater {
                                model: ScriptModel {
                                    values: group.latestActions
                                }
                                delegate: Rectangle {
                                    required property var modelData
                                    implicitWidth: aLbl.implicitWidth + 20
                                    implicitHeight: 30
                                    radius: 15
                                    color: aHov.containsMouse ? Colors.md3.secondary_container : Colors.md3.surface_container_highest

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }

                                    Text {
                                        id: aLbl
                                        anchors.centerIn: parent
                                        text: modelData.text || ""
                                        color: Colors.md3.on_surface
                                        font.family: Config.fontFamily
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: aHov
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
    }
}
