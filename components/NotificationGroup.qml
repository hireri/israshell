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

    readonly property var groupData: {
        const _ = NotificationService.version;
        return NotificationService.groups[group.groupKey] ?? null;
    }
    readonly property var messages: {
        const _ = NotificationService.version;
        const d = group.groupData;
        if (!d || d.messages.length === 0)
            return [];
        return d.messages.slice().reverse();
    }
    readonly property int count: messages.length
    readonly property var latest: messages.length > 0 ? messages[0] : null
    readonly property var liveNotif: groupData?.liveNotification ?? null
    readonly property bool isCritical: (groupData?.urgency ?? "normal") === "2"

    property string _icon: Quickshell.iconPath("", "application-x-executable")
    property string _appBadgeIcon: ""
    property bool _hasBadge: false
    property bool _isAvatarMode: false
    property string _summary: groupSummary
    property string _appName: appName
    property var _cachedActions: []

    function resolveIcon(source) {
        if (!source || source === "")
            return "";

        if (source.startsWith("/") || source.includes("://"))
            return source;

        return Quickshell.iconPath(source);
    }

    function _md(s) {
        if (!s)
            return "";

        let res = s.replace(/<img[^>]*>/g, "");

        res = res.replace(/&/g, "&amp;").replace(/\n/g, "<br/>");

        res = res.replace(/\*\*(.+?)\*\*/g, "<b>$1</b>").replace(/\*(.+?)\*/g, "<i>$1</i>").replace(/~~(.+?)~~/g, "<s>$1</s>").replace(/`(.+?)`/g, "<code>$1</code>");

        return res;
    }

    function getBodyImage(s) {
        if (!s)
            return "";
        const match = s.match(/<img\s+src=["']([^"']+)["'][^>]*\/?>/);
        return match ? match[1] : "";
    }

    readonly property string _mainIcon: {
        const m = group.latest;
        if (!m)
            return resolveIcon("");
        if (m.image !== "")
            return resolveIcon(m.image);
        if (m.appIcon !== "")
            return resolveIcon(m.appIcon);
        return resolveIcon(m.desktopEntry);
    }

    readonly property string _badgeIcon: {
        const m = group.latest;
        if (!m)
            return "";
        if (m.image !== "") {
            const icon = m.appIcon !== "" ? m.appIcon : m.desktopEntry;
            if (icon !== "" && resolveIcon(icon) !== resolveIcon(m.image)) {
                return resolveIcon(icon);
            }
        }
        return "";
    }

    readonly property var latestActions: liveNotif?.actions ?? []

    onMessagesChanged: {
        if (messages.length > 0) {
            if (group.popup && !containsMouse && group.liveNotif !== null)
                groupTimer.restart();
        }
    }

    onLatestActionsChanged: {
        if (latestActions.length > 0)
            _cachedActions = latestActions;
    }

    property int _tick: 0
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: group._tick++
    }
    readonly property string relativeTime: {
        const _ = group._tick;
        if (!group.latest)
            return "";
        const m = Math.floor((Date.now() - group.latest.time) / 60000);
        if (m < 1)
            return "just now";
        if (m < 60)
            return m + "m";
        const h = Math.floor(m / 60);
        if (h < 24)
            return h + "h";
        return Math.floor(h / 24) + "d";
    }

    function _cap(s) {
        return s.replace(/\b\w/g, c => c.toUpperCase());
    }

    readonly property real bodyLineH: 13 * 1.45

    readonly property bool canExpand: {
        if (count > 1)
            return true;
        if (measureText.implicitHeight > bodyLineH * 2)
            return true;
        if (latest && getBodyImage(latest.body) !== "")
            return true;
        return false;
    }

    Text {
        id: measureText
        visible: false
        width: group.width > 0 ? (group.width - 44 - 14 * 2 - 10) : 200
        text: group.latest ? group._md(group.latest.body.length > 0 ? group.latest.body : group.latest.summary) : ""
        font.family: Config.fontFamily
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        textFormat: Text.StyledText
    }

    property int dragIndex: -1
    property real dragDistance: 0
    function resetDrag() {
        dragIndex = -1;
        dragDistance = 0;
    }

    property bool expandedState: false
    property bool isDragging: false
    property bool dismissing: false
    property real cardX: 0
    property real cardOpacity: 1.0
    property real _cardHeight: -1

    onCountChanged: {
        if (count === 0 && !group.dismissing) {
            group.dismissing = true;
            _shrinkAnim.start();
        }
    }

    Timer {
        id: groupTimer
        interval: {
            const t = group.liveNotif?.expireTimeout ?? 0;
            return t > 0 ? t : 5000;
        }
        running: false
        onTriggered: {
            if (!group.liveNotif) {
                stop();
                return;
            }
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
        else if (group.liveNotif)
            groupTimer.restart();
    }

    acceptedButtons: Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton && group.canExpand)
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
                    NotificationService.dismissGroup(group.groupKey);
                else
                    NotificationService.sendGroupToPanel(group.groupKey);
            }
        }
    }

    SequentialAnimation {
        id: _shrinkAnim
        ScriptAction {
            script: {
                group._cardHeight = card.height;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: group
                property: "cardOpacity"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: group
                property: "_cardHeight"
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
        implicitHeight: card.height + 10
        transform: Translate {
            x: group.cardX
        }
        opacity: group.cardOpacity

        RectangularShadow {
            anchors.fill: card
            radius: card.radius
            blur: 20
            color: Qt.rgba(0, 0, 0, 0.22)
            offset: Qt.vector2d(0, 4)
            antialiasing: true
            visible: !group.inPanel
        }

        Rectangle {
            id: card
            anchors.left: parent.left
            anchors.top: parent.top
            width: parent.width
            implicitWidth: group.width > 0 ? group.width : 320
            height: group._cardHeight >= 0 ? group._cardHeight : cardCol.implicitHeight + 28

            radius: 18
            color: group.inPanel ? Colors.md3.surface_container_high : Colors.md3.surface_container
            border.color: group.isCritical ? Colors.md3.on_error_container : (group.inPanel ? "transparent" : Qt.alpha(Colors.md3.outline_variant, 0.5))
            clip: true

            Row {
                id: topRightRow
                anchors {
                    right: card.right
                    top: card.top
                    margins: 14
                }
                spacing: 6
                z: 2

                Text {
                    text: group.relativeTime
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    opacity: 0.65
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    visible: group.canExpand
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: pillRow.implicitWidth + 20
                    implicitHeight: 20
                    radius: 10
                    color: Colors.md3.surface_container_highest
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
                            font.pixelSize: 10
                            font.bold: true
                        }
                        Text {
                            text: ""
                            color: Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            rotation: group.expandedState ? 180 : 0
                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 300
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
                            if (group.canExpand)
                                group.expandedState = !group.expandedState;
                        }
                    }
                }
            }

            ColumnLayout {
                id: cardCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        Layout.alignment: Qt.AlignTop

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 14
                            color: group.inPanel ? Colors.md3.surface_container : Colors.md3.surface_container_high

                            Text {
                                text: "󰂚"
                                color: Colors.md3.on_surface_variant
                                anchors.centerIn: parent
                                font.pixelSize: 24
                                font.family: Config.fontFamily
                                visible: group._mainIcon === ""
                            }

                            Image {
                                anchors.fill: parent
                                source: group._mainIcon
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(88, 88)
                                asynchronous: true
                            }
                        }

                        ClippingRectangle {
                            visible: group._badgeIcon !== ""
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 12
                            color: Colors.md3.surface_container
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: -3
                            anchors.bottomMargin: -3

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: group._badgeIcon
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.rightMargin: topRightRow.implicitWidth + 6
                        spacing: 4

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: appNameText.implicitHeight * appNameReveal
                            clip: true
                            visible: group._summary.length > 0 && group._summary !== group._appName

                            property real appNameReveal: group.expandedState ? 1 : 0
                            Behavior on appNameReveal {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Text {
                                id: appNameText
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }
                                text: group._cap(group._appName)
                                color: Colors.md3.on_surface_variant
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                opacity: group.expandedState ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: group._summary.length > 0 ? group._summary : group._cap(group._appName)
                            color: Colors.md3.on_surface
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Item {
                            id: bodyContainer
                            Layout.fillWidth: true
                            Layout.rightMargin: -parent.Layout.rightMargin
                            clip: true

                            implicitHeight: group.expandedState ? expandedBody.implicitHeight : collapsedBody.implicitHeight
                            Behavior on implicitHeight {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Text {
                                id: collapsedBody
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }
                                text: group.latest ? group._md(group.latest.body.length > 0 ? group.latest.body : group.latest.summary) : ""
                                color: Colors.md3.on_surface_variant
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                textFormat: Text.StyledText
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                opacity: group.expandedState ? 0 : 1
                                visible: opacity > 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Column {
                                id: expandedBody
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                }
                                spacing: 6
                                opacity: group.expandedState ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Repeater {
                                    model: ScriptModel {
                                        values: {
                                            const arr = group.messages.slice();
                                            arr.reverse();
                                            return arr;
                                        }
                                    }
                                    delegate: NotificationItem {
                                        required property var modelData
                                        required property int index
                                        msgData: modelData
                                        groupRef: group
                                        itemIndex: index
                                        collapsed: false
                                        width: expandedBody.width
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    visible: group._cachedActions.length > 0
                    Layout.fillWidth: true
                    implicitHeight: actFlick.implicitHeight

                    Flickable {
                        id: actFlick
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        height: actRow.implicitHeight
                        contentWidth: actRow.implicitWidth
                        implicitHeight: actRow.implicitHeight
                        interactive: actRow.implicitWidth > width
                        clip: actRow.implicitWidth > width
                        flickableDirection: Flickable.HorizontalFlick
                        ScrollBar.horizontal: ScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }

                        Row {
                            id: actRow
                            spacing: 6
                            Repeater {
                                model: ScriptModel {
                                    values: group._cachedActions
                                }
                                delegate: Rectangle {
                                    required property var modelData
                                    implicitWidth: aLbl.implicitWidth + 20
                                    implicitHeight: 28
                                    radius: 14
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
                                            const live = group.liveNotif?.actions ?? [];
                                            const liveAct = live.find(a => a.identifier === modelData.identifier);
                                            const act = liveAct ?? modelData;
                                            if (typeof act.invoke === "function")
                                                act.invoke();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.fill: actFlick
                        visible: actRow.implicitWidth > actFlick.width
                        z: 1

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: 28
                            opacity: actFlick.contentX > 1 ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: Colors.md3.surface_container_high
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "transparent"
                                }
                            }
                        }

                        Rectangle {
                            anchors {
                                right: parent.right
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: 28
                            opacity: actFlick.contentX < actFlick.contentWidth - actFlick.width - 1 ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Colors.md3.surface_container_high
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: false
                        }
                    }
                }
            }
        }
    }
}
