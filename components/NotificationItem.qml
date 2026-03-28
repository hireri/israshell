pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services

Item {
    id: item

    property var wrapper: null
    property var historyData: null
    property var groupRef: null
    property int itemIndex: 0

    readonly property bool isLive: wrapper !== null
    readonly property string summary: isLive ? wrapper.summary : (historyData?.summary ?? "")
    readonly property string body: isLive ? wrapper.body : (historyData?.body ?? "")
    readonly property string appIcon: isLive ? wrapper.appIcon : (historyData?.appIcon ?? "")
    readonly property string imgUrl: isLive ? wrapper.image : (historyData?.image ?? "")
    readonly property var actions: (isLive && wrapper?.notification) ? wrapper.notification.actions : []

    readonly property string resolvedIcon: Quickshell.iconPath(appIcon, "application-x-executable")
    readonly property bool hasBadge: imgUrl.length > 0 && appIcon.length > 0

    readonly property bool showExpanded: groupRef === null || (groupRef?.expandedState ?? false)

    readonly property bool canDrag: isLive && !item.localDismissing && (groupRef === null || ((groupRef?.expandedState ?? false) && (groupRef?.count ?? 0) > 1))
    readonly property real dismissThreshold: 70

    property bool localDismissing: false
    property bool isDragging: false

    property real visibleHeight: col.implicitHeight
    Behavior on visibleHeight {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    implicitHeight: item.visibleHeight
    height: item.visibleHeight

    property real translateX: 0

    Behavior on translateX {
        enabled: !item.isDragging && !item.localDismissing
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: parent ? parent.width : 296
    transform: Translate {
        x: item.translateX
    }

    Connections {
        target: item.groupRef
        enabled: item.groupRef !== null

        function onDragDistanceChanged() {
            if (item.isDragging)
                return;
            if (item.localDismissing || !item.canDrag)
                return;

            const idx = item.groupRef.dragIndex;
            const d = item.groupRef.dragDistance;
            const diff = Math.abs(idx - item.itemIndex);

            if (idx < 0)
                return;

            if (Math.abs(d) > item.dismissThreshold && diff !== 0) {
                item.translateX = 0;
                return;
            }

            if (diff === 1)
                item.translateX = d * 0.3;
            else if (diff === 2)
                item.translateX = d * 0.1;
            else if (diff > 2)
                item.translateX = 0;
        }

        function onDragIndexChanged() {
            if (item.isDragging)
                return;
            if (item.groupRef.dragIndex < 0 && !item.localDismissing)
                item.translateX = 0;
        }
    }

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 10
            spacing: 10

            Item {
                implicitWidth: 40
                implicitHeight: 40

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Colors.md3.surface_container
                    clip: true
                    visible: item.imgUrl.length > 0

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: item.imgUrl
                        asynchronous: true
                    }
                }

                ClippingRectangle {
                    visible: item.imgUrl.length === 0 || item.hasBadge
                    implicitWidth: item.hasBadge ? 16 : 40
                    implicitHeight: item.hasBadge ? 16 : 40
                    radius: item.hasBadge ? 4 : 8
                    color: Colors.md3.surface_container_high
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: item.hasBadge ? -2 : 0
                    anchors.bottomMargin: item.hasBadge ? -2 : 0

                    IconImage {
                        anchors.fill: parent
                        anchors.margins: 3
                        source: item.resolvedIcon
                        asynchronous: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: item.summary
                    color: Colors.md3.on_surface
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: item.body
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    textFormat: Text.PlainText
                    visible: !item.showExpanded && item.body.length > 0
                }
            }
        }

        ColumnLayout {
            visible: item.showExpanded
            opacity: item.showExpanded ? 1 : 0
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 6
            Layout.bottomMargin: 10
            spacing: 8

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                text: item.body
                color: Colors.md3.on_surface_variant
                font.family: Config.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                visible: item.body.length > 0
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Item {
                visible: item.isLive && item.actions.length > 0
                Layout.fillWidth: true
                implicitHeight: actionsFlick.implicitHeight

                Flickable {
                    id: actionsFlick
                    anchors.fill: parent
                    contentWidth: actionsRow.implicitWidth
                    implicitHeight: actionsRow.implicitHeight
                    clip: true
                    flickableDirection: Flickable.HorizontalFlick
                    ScrollBar.horizontal: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    RowLayout {
                        id: actionsRow
                        spacing: 6

                        Repeater {
                            model: ScriptModel {
                                values: item.actions
                            }
                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: lbl.implicitWidth + 24
                                implicitHeight: 32
                                radius: 8
                                color: ah.containsMouse ? Colors.md3.secondary_container : Colors.md3.surface_container

                                Text {
                                    id: lbl
                                    anchors.centerIn: parent
                                    text: modelData.text || ""
                                    color: Colors.md3.on_surface
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: ah
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

    DragHandler {
        id: itemDrag
        enabled: item.canDrag
        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        grabPermissions: PointerHandler.CanTakeOverFromAnything

        property real _velX: 0
        property real _lastX: 0
        property real _lastTime: 0

        onActiveChanged: {
            if (active) {
                item.isDragging = true;
                if (item.groupRef)
                    item.groupRef.dragIndex = item.itemIndex;
                _velX = 0;
                _lastX = translation.x;
                _lastTime = Date.now();
            } else {
                item.isDragging = false;
                const d = item.translateX;
                const vx = _velX;
                const fling = Math.abs(vx) > 0.5;

                if (Math.abs(d) > item.dismissThreshold || fling) {
                    item._startDismiss(d !== 0 ? d : vx, vx);
                } else {
                    item.groupRef?.resetDrag();

                    item.translateX = 0;
                }
            }
        }

        onTranslationChanged: {
            if (!active)
                return;
            const now = Date.now();
            const dt = now - _lastTime;
            if (dt > 0) {
                const instant = (translation.x - _lastX) / dt;
                _velX = _velX * 0.6 + instant * 0.4;
            }
            _lastX = translation.x;
            _lastTime = now;

            item.translateX = translation.x;
            if (item.groupRef)
                item.groupRef.dragDistance = translation.x;
        }
    }

    function _startDismiss(distance, velocityX) {
        item.localDismissing = true;
        if (item.wrapper)
            item.wrapper.dismissing = true;

        const dir = distance !== 0 ? Math.sign(distance) : Math.sign(velocityX);
        const speed = Math.abs(velocityX);
        const dur = speed > 0.5 ? Math.max(100, 240 - speed * 100) : 220;

        _dismissAnim.toX = dir * (item.implicitWidth + 60);
        _dismissAnim.dur = dur;
        _dismissAnim.start();
    }

    SequentialAnimation {
        id: _dismissAnim
        property real toX: 0
        property int dur: 220

        NumberAnimation {
            target: item
            property: "translateX"
            to: _dismissAnim.toX
            duration: _dismissAnim.dur
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: item
            property: "visibleHeight"
            to: 0
            duration: 180
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: {
                item.wrapper?.notification?.dismiss();
                item.groupRef?.resetDrag();
            }
        }
    }
}
