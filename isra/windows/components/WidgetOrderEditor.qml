pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    property var leftIds: []
    property var centerData: ({
        mode: "auto",
        anchor: "",
        items: []
    })
    property var rightIds: []
    property var disabledIds: []
    property bool isLast: false

    property var allWidgetIds: []
    property var widgetLabels: ({})

    signal orderChanged(var newLeft, var newCenter, var newRight, var newDisabled)

    readonly property int rowHeight: 36
    readonly property int rowGap: 4
    readonly property int sepHeight: 22

    implicitHeight: listArea.height + 16
    implicitWidth: 350
    width: parent ? parent.width : implicitWidth

    property int draggingIndex: -1

    ListModel { id: widgetModel }

    Component.onCompleted: {
        root._loadFromProp();
        root._layout();
    }

    function _displayName(id) {
        const known = WidgetService.labelMap[id];
        if (known)
            return known;
        return id.replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/^./, c => c.toUpperCase());
    }

    function _loadFromProp() {
        widgetModel.clear();
        const rightItems = Array.isArray(root.rightIds) ? root.rightIds : [];
        const centerItems = (root.centerData && Array.isArray(root.centerData.items)) ? root.centerData.items : [];
        const leftItems = Array.isArray(root.leftIds) ? root.leftIds : [];
        const anchor = (root.centerData && typeof root.centerData.anchor === "string") ? root.centerData.anchor : "";
        const disabledSet = new Set(Array.isArray(root.disabledIds) ? root.disabledIds : []);

        const positioned = new Set([...leftItems, ...centerItems, ...rightItems]);
        
        const fallbackLeft = [];
        const fallbackCenter = [];
        const fallbackRight = [];

        const defaultZoneMap = {};
        if (Array.isArray(WidgetService.definitions)) {
            for (const def of WidgetService.definitions) {
                defaultZoneMap[def.id] = def.defaultZone;
            }
        }

        const allPossibleIds = new Set([...WidgetService.allIds, ...disabledSet]);
        for (const id of allPossibleIds) {
            if (!positioned.has(id)) {
                disabledSet.add(id);
                
                const targetZone = defaultZoneMap[id] || "left";
                if (targetZone === "center") {
                    fallbackCenter.push(id);
                } else if (targetZone === "right") {
                    fallbackRight.push(id);
                } else {
                    fallbackLeft.push(id);
                }
            }
        }

        widgetModel.append({ kind: "sep", zone: "left", widgetId: "", pivot: false, hidden: false });
        for (const id of leftItems)
            widgetModel.append({ kind: "item", zone: "left", widgetId: id, pivot: false, hidden: disabledSet.has(id) });
        for (const id of fallbackLeft)
            widgetModel.append({ kind: "item", zone: "left", widgetId: id, pivot: false, hidden: true });

        widgetModel.append({ kind: "sep", zone: "center", widgetId: "", pivot: false, hidden: false });
        for (const id of centerItems)
            widgetModel.append({ kind: "item", zone: "center", widgetId: id, pivot: id === anchor, hidden: disabledSet.has(id) });
        for (const id of fallbackCenter)
            widgetModel.append({ kind: "item", zone: "center", widgetId: id, pivot: false, hidden: true });

        widgetModel.append({ kind: "sep", zone: "right", widgetId: "", pivot: false, hidden: false });
        for (const id of rightItems)
            widgetModel.append({ kind: "item", zone: "right", widgetId: id, pivot: false, hidden: disabledSet.has(id) });
        for (const id of fallbackRight)
            widgetModel.append({ kind: "item", zone: "right", widgetId: id, pivot: false, hidden: true });

        const totalUnassigned = fallbackLeft.length + fallbackCenter.length + fallbackRight.length;
        if (totalUnassigned > 0)
            root._emit();
    }

    function _emit() {
        const left = [], right = [], centerItems = [], disabled = [];
        let anchor = root.centerData?.anchor || "";
        let anchorStillPresent = false;

        for (let i = 0; i < widgetModel.count; i++) {
            const it = widgetModel.get(i);
            if (it.kind !== "item")
                continue;

            if (it.hidden)
                disabled.push(it.widgetId);

            if (it.zone === "right") {
                right.push(it.widgetId);
            } else if (it.zone === "left") {
                left.push(it.widgetId);
            } else if (it.zone === "center") {
                centerItems.push(it.widgetId);
                if (it.pivot) {
                    anchor = it.widgetId;
                    anchorStillPresent = true;
                }
            }
        }

        if (!anchorStillPresent)
            anchor = centerItems.length > 0 ? "" : anchor;

        const newCenter = {
            mode: root.centerData?.mode || "auto",
            anchor: anchor,
            items: centerItems
        };

        root.leftIds = left;
        root.centerData = newCenter;
        root.rightIds = right;
        root.disabledIds = disabled;
        root.orderChanged(left, newCenter, right, disabled);
    }

    function _setPivot(index) {
        const entry = widgetModel.get(index);
        if (entry.kind !== "item" || entry.zone !== "center")
            return;

        const unpinning = entry.pivot;

        for (let i = 0; i < widgetModel.count; i++) {
            const it = widgetModel.get(i);
            if (it.kind === "item" && it.zone === "center") {
                widgetModel.setProperty(i, "pivot", !unpinning && i === index);
            }
        }
        root._emit();
    }

    function _toggleHidden(index) {
        const entry = widgetModel.get(index);
        if (entry.kind !== "item")
            return;

        widgetModel.setProperty(index, "hidden", !entry.hidden);
        root._emit();
    }

    function _slotY(index) {
        let y = 0;
        for (let i = 0; i < index; i++) {
            const it = widgetModel.get(i);
            y += (it.kind === "sep" ? root.sepHeight : root.rowHeight) + root.rowGap;
        }
        return y;
    }

    function _totalHeight() {
        return root._slotY(widgetModel.count);
    }

    function _layout() {
        for (let i = 0; i < widgetModel.count; i++) {
            const del = rowRepeater.itemAt(i);
            if (!del) continue;
            if (i === root.draggingIndex) continue;
            del.targetY = root._slotY(i);
        }
        listArea.height = root._totalHeight();
    }

    function _startDrag(index, pressSceneY) {
        root.draggingIndex = index;
        const del = rowRepeater.itemAt(index);
        del.grabOffsetY = pressSceneY - del.y;
        del.z = 100;
    }

    function _zoneForInsertionPoint(i) {
        for (let k = i - 1; k >= 0; k--) {
            if (widgetModel.get(k).kind === "sep")
                return widgetModel.get(k).zone;
        }
        return "left";
    }

    function _dragMove(sceneY) {
        if (root.draggingIndex === -1) return;
        const del = rowRepeater.itemAt(root.draggingIndex);
        const y = sceneY - del.grabOffsetY;
        const movingDown = y > del.y;
        del.y = y;
        del.targetY = y;

        const idx = root.draggingIndex;

        if (movingDown) {
            const nextPoint = idx + 2;
            if (nextPoint <= widgetModel.count) {
                const nextRowTop = root._slotY(idx + 1);
                const nextRowCenter = nextRowTop + root.rowHeight / 2;
                const bottomEdge = y + root.rowHeight;
                if (bottomEdge > nextRowCenter) {
                    root._applyMove(nextPoint);
                    return;
                }
            }
        } else {
            const prevPoint = idx - 1;
            if (prevPoint >= 1) {
                const prevRowTop = root._slotY(idx - 1);
                const prevRowCenter = prevRowTop + root.rowHeight / 2;
                if (y < prevRowCenter) {
                    root._applyMove(prevPoint);
                    return;
                }
            }
        }
    }

    function _applyMove(bestPoint) {
        const bestZone = root._zoneForInsertionPoint(bestPoint);

        let dest = bestPoint;
        if (root.draggingIndex < bestPoint)
            dest -= 1;
        dest = Math.max(1, Math.min(dest, widgetModel.count - 1));

        if (dest === root.draggingIndex)
            return;

        widgetModel.move(root.draggingIndex, dest, 1);
        widgetModel.setProperty(dest, "zone", bestZone);
        if (bestZone !== "center")
            widgetModel.setProperty(dest, "pivot", false);

        root.draggingIndex = dest;
        root._layout();
    }

    function _endDrag() {
        if (root.draggingIndex === -1) return;
        const del = rowRepeater.itemAt(root.draggingIndex);
        if (del) del.z = 0;
        root.draggingIndex = -1;
        root._layout();
        root._emit();
    }

    Item {
        id: listArea
        width: parent.width
        anchors.top: parent.top
        anchors.topMargin: 10
        height: 0

        Repeater {
            id: rowRepeater
            model: widgetModel

            delegate: Item {
                id: rowRoot
                required property int index
                required property string kind
                required property string widgetId
                required property string zone
                required property bool pivot
                required property bool hidden

                readonly property string name: root._displayName(widgetId)
                readonly property bool isDragging: root.draggingIndex === index

                property real targetY: root._slotY(index)
                property real grabOffsetY: 0

                width: listArea.width
                height: kind === "sep" ? root.sepHeight : root.rowHeight
                y: targetY

                Behavior on y {
                    enabled: !rowRoot.isDragging
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    id: sepRect
                    visible: rowRoot.kind === "sep"
                    width: parent.width - 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: root.sepHeight
                    radius: 12
                    color: Colors.md3.secondary_container

                    Text {
                        anchors.centerIn: parent
                        text: rowRoot.zone === "right" ? "Right" : rowRoot.zone === "center" ? "Center" : "Left"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.letterSpacing: 0.5
                        color: Colors.md3.on_secondary_container
                    }
                }

                Rectangle {
                    id: row
                    visible: rowRoot.kind === "item"
                    width: parent.width - 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: root.rowHeight
                    radius: 9
                    color: rowRoot.isDragging ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                    opacity: rowRoot.hidden ? 0.45 : 1.0
                    border.width: 0
                    border.color: Colors.md3.primary

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    HoverHandler { id: rowHover }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 10
                        spacing: 2

                        Item {
                            id: dragHandle
                            width: 28
                            height: parent.height

                            MaterialIcon {
                                name: "drag-indicator"
                                anchors.centerIn: parent
                                iconSize: 15
                                color: Colors.md3.on_surface_variant
                                opacity: dragArea.pressed ? 1.0 : (rowHover.hovered ? 0.85 : 0.5)
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                preventStealing: true

                                onPressed: mouse => {
                                    const scenePos = dragArea.mapToItem(listArea, mouse.x, mouse.y);
                                    root._startDrag(rowRoot.index, scenePos.y);
                                }

                                onPositionChanged: mouse => {
                                    if (!pressed) return;
                                    const scenePos = dragArea.mapToItem(listArea, mouse.x, mouse.y);
                                    root._dragMove(scenePos.y);
                                }

                                onReleased: root._endDrag()
                            }
                        }

                        Text {
                            text: rowRoot.name
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.strikeout: rowRoot.hidden
                            color: rowRoot.hidden ? Colors.md3.on_surface_variant : Colors.md3.on_surface
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - dragHandle.width - actionsRow.width - 8
                            elide: Text.ElideRight
                        }

                        Row {
                            id: actionsRow
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            spacing: 0

                            IconToggleButton {
                                visible: rowRoot.zone === "center" && root.centerData.mode === "anchor"
                                width: visible ? 28 : 0
                                active: rowRoot.pivot
                                enabled: !rowRoot.hidden
                                opacity: rowRoot.hidden ? 0.35 : 1.0
                                onClicked: root._setPivot(rowRoot.index)

                                MaterialIcon {
                                    name: "keep"
                                    anchors.centerIn: parent
                                    iconSize: 15
                                    filled: rowRoot.pivot
                                    color: rowRoot.pivot ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                                }
                            }

                            IconToggleButton {
                                id: eyeBtn
                                width: 28
                                onClicked: root._toggleHidden(rowRoot.index)

                                MaterialIcon {
                                    name: "visibility-off"
                                    anchors.centerIn: parent
                                    iconSize: 15
                                    visible: rowRoot.hidden
                                    color: Colors.md3.on_surface_variant
                                }
                                MaterialIcon {
                                    name: "visibility"
                                    anchors.centerIn: parent
                                    iconSize: 15
                                    visible: !rowRoot.hidden
                                    color: Colors.md3.on_surface_variant
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component IconToggleButton: Item {
        id: btn
        property bool active: false
        signal clicked

        height: parent.height

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: height / 2
            color: btn.active ? Colors.md3.primary_container : area.containsMouse ? Colors.md3.surface_container_highest : Qt.alpha(Colors.md3.surface_container_highest, 0)
            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
