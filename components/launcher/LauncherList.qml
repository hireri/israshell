import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.style

Item {
    id: root

    property var model
    property string mode: "apps"
    readonly property real listContentHeight: list.contentHeight
    readonly property int selectedIndex: list.currentIndex

    signal itemActivated(var entry)
    signal actionActivated

    function resetToTop() {
        list.currentIndex = 0;
        list.positionViewAtBeginning();
    }
    function moveUp() {
        if (list.currentIndex > 0)
            list.currentIndex--;
    }
    function moveDown() {
        if (list.currentIndex < list.count - 1)
            list.currentIndex++;
    }
    function activateCurrent() {
        const e = root.model.values[list.currentIndex];
        if (e)
            root.itemActivated(e);
    }

    readonly property var _emptyText: ({
            "apps": "No apps found.",
            "clipboard": "Nothing here.",
            "emoji": "No emoji found.",
            "translate": "No apps found."
        })

    ListView {
        id: list
        anchors.fill: parent
        model: root.model
        clip: true
        spacing: 2

        flickDeceleration: 4000
        maximumFlickVelocity: 2200
        boundsBehavior: Flickable.DragAndOvershootBounds

        header: Item {
            height: 6
        }
        footer: Item {
            height: 6
        }

        onCountChanged: {
            list.highlightMoveDuration = 0;
            list.highlightResizeDuration = 0;
            list.currentIndex = 0;
            list.positionViewAtBeginning();
            Qt.callLater(() => {
                list.highlightMoveDuration = 160;
                list.highlightResizeDuration = 160;
            });
        }

        highlightMoveDuration: 160
        highlightMoveVelocity: -1
        highlightResizeDuration: 160
        highlightResizeVelocity: -1
        highlightFollowsCurrentItem: true

        highlight: Item {
            Rectangle {
                anchors {
                    fill: parent
                    leftMargin: 6
                    rightMargin: 6
                }
                radius: 14
                color: Colors.md3.secondary_container
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            onWheel: event => {
                const step = 52 * 3;
                const delta = event.angleDelta.y > 0 ? -step : step;
                const headerH = list.headerItem?.height ?? 6;
                const footerH = list.footerItem?.height ?? 6;
                list.contentY = Math.max(-headerH, Math.min(list.contentHeight - list.height + footerH, list.contentY + delta));
                event.accepted = true;
            }
        }

        delegate: Item {
            id: del
            required property var modelData
            required property int index

            width: list.width

            readonly property bool _isApp: modelData.type === "app"
            readonly property bool _isClip: modelData.type === "clip"
            readonly property bool _isEmoji: modelData.type === "emoji"
            readonly property bool _selected: list.currentIndex === del.index

            property string _hoveredAction: ""
            property string _nextAction: ""
            readonly property bool _rowHovered: rowHov.containsMouse || del._hoveredAction !== ""

            Timer {
                id: clearActionTimer
                interval: 40
                onTriggered: del._hoveredAction = del._nextAction
            }

            readonly property int _imgAreaH: 160
            readonly property int _imgDelegateH: 40 + _imgAreaH

            height: {
                if (_isClip && modelData.isImage)
                    return _imgDelegateH;
                if (_isClip)
                    return Math.max(52, clipText.contentHeight + 24);
                return 52;
            }

            Rectangle {
                anchors {
                    fill: parent
                    leftMargin: 6
                    rightMargin: 6
                }
                radius: 14
                color: Colors.md3.surface_container_high
                opacity: (!del._selected && del._rowHovered) ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutExpo
                    }
                }
            }

            MouseArea {
                id: rowHov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.itemActivated(del.modelData)
            }

            RowLayout {
                visible: del._isApp
                anchors {
                    fill: parent
                    leftMargin: 14
                    rightMargin: 14
                }
                spacing: 12

                Item {
                    width: 36
                    height: 36
                    Layout.alignment: Qt.AlignVCenter
                    IconImage {
                        anchors.fill: parent
                        source: del._isApp ? Quickshell.iconPath(del.modelData.entry.icon ?? "", true) : ""
                        visible: del._isApp && (del.modelData.entry.icon ?? "") !== ""
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰘔"
                        color: Colors.md3.primary
                        font.pixelSize: 24
                        font.family: Config.fontFamily
                        visible: del._isApp && (del.modelData.entry.icon ?? "") === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: nameNormal.implicitHeight

                        Text {
                            id: nameNormal
                            anchors.fill: parent
                            text: del._isApp ? (del.modelData.entry.name ?? "") : ""
                            color: Colors.md3.on_surface
                            font.pixelSize: 14
                            font.family: Config.fontFamily
                            font.weight: Font.Normal
                            elide: Text.ElideRight
                            opacity: del._selected ? 0.0 : 1.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 130
                                    easing.type: Easing.OutExpo
                                }
                            }
                        }
                        Text {
                            anchors.fill: parent
                            text: del._isApp ? (del.modelData.entry.name ?? "") : ""
                            color: Colors.md3.on_secondary_container
                            font.pixelSize: 14
                            font.family: Config.fontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            opacity: del._selected ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 130
                                    easing.type: Easing.OutExpo
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: subNormal.implicitHeight
                        height: Math.max(implicitHeight, 14)

                        Text {
                            id: subNormal
                            anchors.fill: parent
                            text: del._isApp ? (del.modelData.entry.genericName ?? del.modelData.entry.comment ?? "") : ""
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 12
                            font.family: Config.fontFamily
                            elide: Text.ElideRight
                            opacity: del._hoveredAction === "" ? 0.6 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutExpo
                                }
                            }
                        }
                        Text {
                            anchors.fill: parent
                            text: del._hoveredAction
                            color: Colors.md3.primary
                            font.pixelSize: 12
                            font.family: Config.fontFamily
                            elide: Text.ElideRight
                            opacity: del._hoveredAction !== "" ? 0.9 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutExpo
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    visible: del._isApp && (del.modelData.entry.actions?.length ?? 0) > 0

                    Repeater {
                        model: del._isApp ? (del.modelData.entry.actions ?? []).slice(0, 3) : []

                        Rectangle {
                            id: actionBtn
                            width: 30
                            height: 30
                            radius: 10

                            readonly property string _aIcon: {
                                const own = Quickshell.iconPath(modelData.icon ?? "", true);
                                return own !== "" ? own : Quickshell.iconPath(del.modelData.entry.icon ?? "", true);
                            }

                            color: aHov.containsMouse ? (del._selected ? Colors.md3.surface_container_highest : Colors.md3.secondary_container) : del._selected ? Colors.md3.secondary_container : Colors.md3.surface_container
                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }

                            IconImage {
                                anchors {
                                    fill: parent
                                    margins: 5
                                }
                                source: actionBtn._aIcon
                            }

                            MouseArea {
                                id: aHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    clearActionTimer.stop();
                                    del._hoveredAction = modelData.name ?? "";
                                    del._nextAction = modelData.name ?? "";
                                }
                                onExited: {
                                    del._nextAction = "";
                                    clearActionTimer.restart();
                                }
                                onClicked: mouse => {
                                    mouse.accepted = true;
                                    modelData.execute();
                                    root.actionActivated();
                                }
                            }
                        }
                    }
                }
            }

            Item {
                visible: del._isClip
                anchors {
                    fill: parent
                    topMargin: 12
                    leftMargin: 18
                    rightMargin: 18
                    bottomMargin: 12
                }

                Text {
                    id: clipId
                    anchors.top: parent.top
                    anchors.left: parent.left
                    text: del._isClip ? ("#" + del.modelData.id) : ""
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 11
                    font.family: Config.fontFamily
                    opacity: 0.45
                }

                Text {
                    id: clipText
                    visible: del._isClip && !del.modelData.isImage
                    anchors {
                        top: clipId.bottom
                        topMargin: 2
                        left: parent.left
                        right: parent.right
                    }
                    text: (del._isClip && !del.modelData.isImage) ? del.modelData.content.trim() : ""
                    color: del._selected ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignTop
                    lineHeight: 1.4
                }

                Loader {
                    id: imgLoader
                    property string entryId: del._isClip ? del.modelData.id : ""
                    property string entryMime: (del._isClip && del.modelData.isImage) ? (del.modelData.mime ?? "image/png") : "image/png"
                    active: del._isClip && del.modelData.isImage
                    visible: active
                    anchors {
                        top: clipId.bottom
                        topMargin: 6
                        left: parent.left
                        right: parent.right
                    }
                    height: del._imgAreaH

                    sourceComponent: Component {
                        Item {
                            id: imgItem
                            property string b64: ""
                            Process {
                                command: ["sh", "-c", "clipvault get " + imgLoader.entryId + " | base64 -w0"]
                                running: true
                                stdout: StdioCollector {
                                    onStreamFinished: imgItem.b64 = this.text.trim()
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: Colors.md3.surface_container_high
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    source: imgItem.b64 !== "" ? ("data:" + imgLoader.entryMime + ";base64," + imgItem.b64) : ""
                                    visible: source !== ""
                                    smooth: true
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰋩"
                                    color: Colors.md3.on_surface_variant
                                    font.pixelSize: 22
                                    font.family: Config.fontFamily
                                    visible: imgItem.b64 === ""
                                    opacity: 0.35
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                visible: del._isEmoji
                anchors {
                    fill: parent
                    leftMargin: 14
                    rightMargin: 14
                }
                spacing: 14

                Text {
                    text: del._isEmoji ? del.modelData.emoji : ""
                    font.pixelSize: 26
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: emojiNormal.implicitHeight

                        Text {
                            id: emojiNormal
                            anchors.fill: parent
                            text: del._isEmoji ? del.modelData.name : ""
                            color: Colors.md3.on_surface
                            font.pixelSize: 14
                            font.family: Config.fontFamily
                            font.weight: Font.Normal
                            elide: Text.ElideRight
                            opacity: del._selected ? 0.0 : 1.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 130
                                    easing.type: Easing.OutExpo
                                }
                            }
                        }
                        Text {
                            anchors.fill: parent
                            text: del._isEmoji ? del.modelData.name : ""
                            color: Colors.md3.on_secondary_container
                            font.pixelSize: 14
                            font.family: Config.fontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            opacity: del._selected ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 130
                                    easing.type: Easing.OutExpo
                                }
                            }
                        }
                    }

                    Text {
                        text: del._isEmoji ? del.modelData.keywords.slice(0, 5).join("  ·  ") : ""
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: text !== ""
                        opacity: 0.7
                    }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 12
            visible: list.count === 0

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: kaoLbl.implicitWidth + 28
                height: 44
                radius: 22
                color: Colors.md3.primary_container

                Text {
                    id: kaoLbl
                    anchors.centerIn: parent
                    text: "(ᵕ—ᴗ—)?"
                    color: Colors.md3.primary
                    font.pixelSize: 22
                    font.family: Config.fontFamily
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root._emptyText[root.mode] ?? "No results."
                color: Colors.md3.on_surface_variant
                font.pixelSize: 13
                font.family: Config.fontFamily
                opacity: 0.4
            }
        }
    }
}
