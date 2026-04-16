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
    readonly property int count: list.count
    property int skinToneIndex: 0

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

    // Unicode 17.0 Emoji_Modifier_Base characters
    // Source: https://www.unicode.org/Public/17.0.0/ucd/emoji/emoji-data.txt
    // Also this: https://github.com/sindresorhus/skin-tone
    readonly property var _toneSupported: new Set([0x261D, 0x26F9, 0x270A, 0x270B, 0x270C, 0x270D, 0x1F385, 0x1F3C2, 0x1F3C3, 0x1F3C4, 0x1F3C7, 0x1F3CA, 0x1F3CB, 0x1F3CC, 0x1F442, 0x1F443, 0x1F446, 0x1F447, 0x1F448, 0x1F449, 0x1F44A, 0x1F44B, 0x1F44C, 0x1F44D, 0x1F44E, 0x1F44F, 0x1F450, 0x1F466, 0x1F467, 0x1F468, 0x1F469, 0x1F46A, 0x1F46B, 0x1F46C, 0x1F46D, 0x1F46E, 0x1F46F, 0x1F470, 0x1F471, 0x1F472, 0x1F473, 0x1F474, 0x1F475, 0x1F476, 0x1F477, 0x1F478, 0x1F47C, 0x1F481, 0x1F482, 0x1F483, 0x1F485, 0x1F486, 0x1F487, 0x1F48F, 0x1F491, 0x1F4AA, 0x1F574, 0x1F575, 0x1F57A, 0x1F590, 0x1F595, 0x1F596, 0x1F645, 0x1F646, 0x1F647, 0x1F64B, 0x1F64C, 0x1F64D, 0x1F64E, 0x1F64F, 0x1F6A3, 0x1F6B4, 0x1F6B5, 0x1F6B6, 0x1F6C0, 0x1F6CC, 0x1F90C, 0x1F90F, 0x1F918, 0x1F919, 0x1F91A, 0x1F91B, 0x1F91C, 0x1F91D, 0x1F91E, 0x1F91F, 0x1F926, 0x1F930, 0x1F931, 0x1F932, 0x1F933, 0x1F934, 0x1F935, 0x1F936, 0x1F937, 0x1F938, 0x1F939, 0x1F93C, 0x1F93D, 0x1F93E, 0x1F977, 0x1F9B5, 0x1F9B6, 0x1F9B8, 0x1F9B9, 0x1F9BB, 0x1F9CD, 0x1F9CE, 0x1F9CF, 0x1F9D1, 0x1F9D2, 0x1F9D3, 0x1F9D4, 0x1F9D5, 0x1F9D6, 0x1F9D7, 0x1F9D8, 0x1F9D9, 0x1F9DA, 0x1F9DB, 0x1F9DC, 0x1F9DD, 0x1FAC3, 0x1FAC4, 0x1FAC5, 0x1FAF0, 0x1FAF1, 0x1FAF2, 0x1FAF3, 0x1FAF4, 0x1FAF5, 0x1FAF6, 0x1FAF7, 0x1FAF8])
    readonly property var _modifiers: ["", "\uD83C\uDFFB", "\uD83C\uDFFC", "\uD83C\uDFFD", "\uD83C\uDFFE", "\uD83C\uDFFF"]

    readonly property var _skinToneRegex: /[\uD83C\uDFFB-\uD83C\uDFFF]/g
    readonly property string _emojiPresentationSelector: "\uFE0F"
    readonly property var _twoFamilyEmojis: new Set(["\uD83D\uDC69\u200D\uD83D\uDC66", "\uD83D\uDC69\u200D\uD83D\uDC67", "\uD83D\uDC68\u200D\uD83D\uDC67", "\uD83D\uDC68\u200D\uD83D\uDC66"])

    function supportsTone(emoji) {
        const cleaned = emoji.replace(_skinToneRegex, "");
        let i = 0;
        while (i < cleaned.length) {
            const cp = cleaned.codePointAt(i);
            if (_toneSupported.has(cp)) {
                return true;
            }
            i += (cp > 0xFFFF) ? 2 : 1;
        }
        return false;
    }

    function _applyTone(entry) {
        if (entry.type !== "emoji")
            return entry;

        const newEmoji = applySkinTone(entry.emoji, root.skinToneIndex);

        if (newEmoji === entry.emoji)
            return entry;

        return Object.assign({}, entry, {
            emoji: newEmoji
        });
    }

    function applySkinTone(emoji, toneIndex) {
        const cleaned = emoji.replace(_skinToneRegex, "");

        if (toneIndex === 0) {
            return cleaned;
        }

        const hasModifierBase = supportsTone(cleaned);
        if (!hasModifierBase) {
            return cleaned;
        }

        const baseCount = countModifierBases(cleaned);
        if (baseCount > 2 || (baseCount === 2 && _twoFamilyEmojis.has(cleaned))) {
            return cleaned;
        }

        const modifier = _modifiers[toneIndex];
        let result = "";
        let i = 0;

        while (i < cleaned.length) {
            const cp = cleaned.codePointAt(i);
            const char = String.fromCodePoint(cp);

            if (cp === 0xFE0F) {
                i += 1;
                continue;
            }

            result += char;

            if (_toneSupported.has(cp)) {
                result += modifier;
            }

            i += (cp > 0xFFFF) ? 2 : 1;
        }

        return result;
    }

    function countModifierBases(emoji) {
        let count = 0;
        let i = 0;
        while (i < emoji.length) {
            const cp = emoji.codePointAt(i);
            if (_toneSupported.has(cp)) {
                count++;
            }
            i += (cp > 0xFFFF) ? 2 : 1;
        }
        return count;
    }

    function activateCurrent() {
        const e = root.model.values[list.currentIndex];
        if (e)
            root.itemActivated(_applyTone(e));
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
                list.highlightResizeDuration = 0;
            });
        }

        onModelChanged: {
            resetToTop();
        }

        highlightMoveDuration: 160
        highlightMoveVelocity: -1
        highlightResizeDuration: 0
        highlightResizeVelocity: -1
        highlightFollowsCurrentItem: true

        highlight: Item {
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                height: parent.height

                Behavior on height {
                    SmoothedAnimation {
                        velocity: 400
                        duration: 160
                    }
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
                onClicked: root.itemActivated(root._applyTone(del.modelData))
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
                    text: {
                        if (!del._isEmoji)
                            return "";
                        return applySkinTone(del.modelData.emoji, root.skinToneIndex);
                    }
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

        Item {
            id: emptyState
            anchors.centerIn: parent
            visible: list.count === 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
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
}
