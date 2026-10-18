pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.components

Item {
    id: root

    property var model
    property string mode: "apps"
    readonly property real listContentHeight: list.contentHeight
    readonly property int selectedIndex: current
    readonly property int count: list.count
    property int skinToneIndex: 0
    property bool busy: false
    property int current: -1
    property Item currentItem: null

    signal itemActivated(var entry)
    signal actionActivated
    signal clipDeleteRequested(string id)

    function _entry(i) {
        return root.model?.values[i] ?? null;
    }

    function _selectable(i) {
        const e = _entry(i);
        return e !== null && e.type !== "header";
    }

    function _step(from, dir, n) {
        let found = from;
        let i = from;
        for (let k = 0; k < n; k++) {
            i += dir;
            while (i >= 0 && i < list.count && !_selectable(i))
                i += dir;
            if (i < 0 || i >= list.count)
                break;
            found = i;
        }
        return found;
    }

    function _select(i) {
        if (i < 0)
            return;
        current = i;
        ensureVisible(i);
    }

    function _stopScroll() {
        scroller.stop();
        _followSel = false;
    }

    function _scrollBase() {
        return scroller.running ? scroller.target : list.contentY;
    }

    function _scrollTo(y) {
        const top = -(list.headerItem?.height ?? 0);
        const bottom = Math.max(top, list.contentHeight + top - list.height);
        const t = Math.max(top, Math.min(bottom, y));
        _followSel = false;
        scroller.target = t;
        if (!scroller.running)
            scroller.start();
    }

    FrameAnimation {
        id: scroller
        property real target: 0
        onTriggered: {
            const d = target - list.contentY;
            if (Math.abs(d) < 0.5) {
                list.contentY = target;
                stop();
                return;
            }
            list.contentY += d * (1 - Math.exp(-Math.min(frameTime, 0.05) * 16));
        }
    }

    function _estH(i) {
        const e = _entry(i);
        if (!e)
            return 56;
        if (e.type === "header")
            return 32;
        if (e.type === "clip")
            return e.isImage ? 170 : 52;
        return 56;
    }

    function _geom(i) {
        const gap = list.spacing;
        for (let d = 0; d < list.count; d++) {
            const below = list.itemAtIndex(i + d);
            if (below) {
                let y = below.y;
                for (let k = i + d - 1; k >= i; k--)
                    y -= _estH(k) + gap;
                return { y: y, h: d === 0 ? below.height : _estH(i) };
            }
            const above = list.itemAtIndex(i - d);
            if (above) {
                let y = above.y + above.height + gap;
                for (let k = i - d + 1; k < i; k++)
                    y += _estH(k) + gap;
                return { y: y, h: _estH(i) };
            }
        }
        return null;
    }

    property bool _followSel: false

    function _headerAbove() {
        return current > 0 && !_selectable(current - 1) ? _estH(current - 1) + list.spacing : 0;
    }

    function ensureVisible(i) {
        if (!_geom(i)) {
            _stopScroll();
            list.positionViewAtIndex(i, ListView.Contain);
            return;
        }
        scroller.stop();
        _followSel = true;
        indicator.place();
        _keepVisible();
    }

    function _keepVisible() {
        if (!_followSel)
            return;
        const top = indicator._e - 6;
        const bottom = indicator._b + 6;
        let y = list.contentY;
        if (top < y)
            y = top;
        else if (bottom > y + list.height)
            y = bottom - list.height;
        const min = -(list.headerItem?.height ?? 0);
        const max = Math.max(min, list.contentHeight + min - list.height);
        list.contentY = Math.max(min, Math.min(max, y));
    }

    function resetToTop() {
        _stopScroll();
        _lastHover = Qt.point(-1, -1);
        current = _step(-1, 1, 1);
        list.positionViewAtBeginning();
        Qt.callLater(indicator.snap);
    }
    function moveUp() {
        _select(_step(current, -1, 1));
    }
    function moveDown() {
        _select(_step(current, 1, 1));
    }
    function pageUp() {
        _select(_step(current, -1, 5));
    }
    function pageDown() {
        _select(_step(current, 1, 5));
    }
    function deleteCurrent() {
        const e = _entry(current);
        if (e && e.type === "clip")
            root.clipDeleteRequested(e.id);
    }

    property point _lastHover: Qt.point(-1, -1)
    function _hoverSelect(item, x, y, i) {
        const p = item.mapToItem(list, x, y);
        const fresh = _lastHover.x < 0;
        if (!fresh && Math.abs(p.x - _lastHover.x) < 1 && Math.abs(p.y - _lastHover.y) < 1)
            return;
        _lastHover = p;
        if (fresh)
            return;
        if (_selectable(i) && i !== current) {
            current = i;
            ensureVisible(i);
        }
    }

    Connections {
        target: root.model || null
        ignoreUnknownSignals: true
        function onValuesChanged() {
            Qt.callLater(root.resetToTop);
        }
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
        const e = _entry(current);
        if (e && e.type !== "header")
            root.itemActivated(_applyTone(e));
    }

    readonly property var _emptyText: ({
            "apps": Localization.t("launcher.no_apps_found"),
            "clipboard": Localization.t("launcher.nothing_here"),
            "emoji": Localization.t("launcher.no_emoji_found"),
            "translate": Localization.t("launcher.no_apps_found")
        })

    readonly property string _clipCache: Quickshell.env("HOME") + "/.cache/israshell/clipboard"

    ListView {
        id: list
        anchors.fill: parent
        model: root.model?.values ?? []
        clip: true
        spacing: 2
        cacheBuffer: 800
        onMovementStarted: root._stopScroll()
        currentIndex: -1
        highlightFollowsCurrentItem: false

        flickDeceleration: 4000
        maximumFlickVelocity: 2200
        boundsBehavior: Flickable.DragAndOvershootBounds

        header: Item {
            height: 6
        }
        footer: Item {
            height: 6
        }

        onCountChanged: root.resetToTop()

        Rectangle {
            id: indicator

            parent: list.contentItem
            z: -1

            readonly property Item cur: root.currentItem
            property real _t: 0
            property real _b: 0
            property real _tt: 0
            property real _tb: 0
            property bool _pendingSnap: true
            property real _e: 0
            property real _te: 0

            function place() {
                const g = root._geom(root.current);
                if (!g)
                    return;
                if (_pendingSnap) {
                    snap();
                    return;
                }
                _tt = g.y;
                _tb = g.y + g.h;
                _te = g.y - root._headerAbove();
                if (!follow.running)
                    follow.start();
            }
            function snap() {
                follow.stop();
                if (!cur) {
                    _pendingSnap = true;
                    return;
                }
                _pendingSnap = false;
                const g = root._geom(root.current) ?? { y: cur.y, h: cur.height };
                _tt = _t = g.y;
                _tb = _b = g.y + g.h;
                _te = _e = g.y - root._headerAbove();
            }

            FrameAnimation {
                id: follow
                onTriggered: {
                    const dt = Math.min(frameTime, 0.05);
                    const down = indicator._tt > indicator._t;
                    const lead = 1 - Math.exp(-dt * 18);
                    const trail = 1 - Math.exp(-dt * 11);
                    const dTop = indicator._tt - indicator._t;
                    const dBot = indicator._tb - indicator._b;
                    const dE = indicator._te - indicator._e;
                    if (Math.abs(dTop) < 0.5 && Math.abs(dBot) < 0.5 && Math.abs(dE) < 0.5) {
                        indicator._t = indicator._tt;
                        indicator._b = indicator._tb;
                        indicator._e = indicator._te;
                        stop();
                    } else {
                        indicator._t += dTop * (down ? trail : lead);
                        indicator._b += dBot * (down ? lead : trail);
                        indicator._e += dE * (down ? trail : lead);
                    }
                    root._keepVisible();
                }
            }

            onCurChanged: place()
            Connections {
                target: root
                function onCurrentChanged() {
                    indicator.place();
                }
            }
            Connections {
                target: indicator.cur
                function onYChanged() {
                    indicator.place();
                }
                function onHeightChanged() {
                    indicator.place();
                }
            }

            x: 6
            width: list.width - 12
            y: _t
            height: Math.max(_b - _t, 8)
            radius: Math.min(height / 2, 22)
            color: Colors.md3.secondary_container
            visible: root.current >= 0 && (cur !== null || !_pendingSnap)
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            onWheel: event => {
                const step = 56 * 3;
                const delta = event.angleDelta.y > 0 ? -step : step;
                root._scrollTo(root._scrollBase() + delta);
                event.accepted = true;
            }
        }

        delegate: Item {
            id: del
            required property var modelData
            required property int index

            readonly property string kind: modelData.type
            readonly property bool sel: index === root.current
            onSelChanged: if (sel)
                root.currentItem = del
            Component.onCompleted: if (sel)
                root.currentItem = del
            Component.onDestruction: if (root.currentItem === del)
                root.currentItem = null
            readonly property color fg: sel ? Colors.md3.on_secondary_container : Colors.md3.on_surface
            readonly property color fgDim: sel ? Qt.alpha(Colors.md3.on_secondary_container, 0.75) : Colors.md3.on_surface_variant

            width: list.width
            height: kind === "header" ? 32 : ((body.item as Item)?.implicitHeight ?? 56)

            MouseArea {
                id: rowMa
                anchors.fill: parent
                enabled: del.kind !== "header"
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: mouse => root._hoverSelect(rowMa, mouse.x, mouse.y, del.index)
                onClicked: root.itemActivated(root._applyTone(del.modelData))
            }

            Loader {
                id: body
                anchors.fill: parent
                scale: rowMa.pressed ? 0.98 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
                sourceComponent: del.kind === "header" ? headerRow : del.kind === "clip" ? (del.modelData.isImage ? imageRow : clipRow) : del.kind === "emoji" ? emojiRow : appRow
            }

            Component {
                id: headerRow
                Item {
                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 20
                            bottom: parent.bottom
                            bottomMargin: 6
                        }
                        text: del.modelData.label ?? ""
                        color: Colors.md3.primary
                        font.pixelSize: 12
                        font.family: Config.fontFamily
                        font.weight: Font.Medium
                    }
                }
            }

            Component {
                id: appRow
                Item {
                    implicitHeight: 56

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: 10
                        }
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            Layout.alignment: Qt.AlignVCenter
                            readonly property string iconName: del.modelData.entry?.icon ?? ""
                            IconImage {
                                anchors.fill: parent
                                visible: parent.iconName !== ""
                                source: Quickshell.iconPath(parent.iconName, true)
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: parent.iconName === ""
                                name: "grid-view"
                                iconSize: 24
                                color: Colors.md3.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: del.modelData.entry?.name ?? ""
                                color: del.fg
                                font.pixelSize: 14
                                font.family: Config.fontFamily
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: del.modelData.entry?.genericName || del.modelData.entry?.comment || ""
                                visible: text !== ""
                                color: del.fgDim
                                font.pixelSize: 12
                                font.family: Config.fontFamily
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Repeater {
                                model: (del.modelData.entry?.actions ?? []).slice(0, 3)

                                LauncherIconBtn {
                                    required property var modelData
                                    size: 32
                                    iconSize: 18
                                    tint: del.sel ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                                    tip: modelData.name ?? ""
                                    source: {
                                        const own = Quickshell.iconPath(modelData.icon ?? "", true);
                                        return own !== "" ? own : Quickshell.iconPath(del.modelData.entry?.icon ?? "", true);
                                    }
                                    onClicked: {
                                        modelData.execute();
                                        root.actionActivated();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: clipRow
                Item {
                    implicitHeight: Math.max(52, clipText.contentHeight + 28)

                    Text {
                        id: clipText
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: 20
                            rightMargin: 20
                            verticalCenter: parent.verticalCenter
                        }
                        text: (del.modelData.content ?? "").trim()
                        color: del.fg
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        lineHeight: 1.3
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }
                }
            }

            Component {
                id: imageRow
                Item {
                    id: imgRow
                    implicitHeight: thumb.height + 46

                    property string path: ""
                    readonly property string key: del.modelData.id + "_" + (del.modelData.meta ?? "").replace(/[^\w]/g, "_")
                    readonly property var dims: /(\d+)x(\d+)/.exec(del.modelData.meta ?? "")
                    readonly property real aspect: dims ? Number(dims[1]) / Math.max(1, Number(dims[2])) : 1.6

                    Process {
                        running: true
                        command: ["sh", "-c", "f=\"$1/$2\"; [ -s \"$f\" ] || { mkdir -p \"$1\" && clipvault get \"$3\" > \"$f.tmp\" && mv \"$f.tmp\" \"$f\"; }; [ -s \"$f\" ] && printf %s \"$f\"", "sh", root._clipCache, imgRow.key, del.modelData.id]
                        stdout: StdioCollector {
                            onStreamFinished: imgRow.path = this.text.trim()
                        }
                    }

                    ClippingRectangle {
                        id: thumb
                        anchors {
                            left: parent.left
                            leftMargin: 16
                            top: parent.top
                            topMargin: 12
                        }
                        readonly property real maxW: parent.width - 32
                        readonly property real maxH: 124
                        width: Math.round(Math.min(maxW, maxH * imgRow.aspect))
                        height: Math.round(Math.min(maxH, width / imgRow.aspect))
                        radius: 12
                        color: Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)

                        Image {
                            anchors.fill: parent
                            source: imgRow.path !== "" ? "file://" + imgRow.path : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            sourceSize: Qt.size(thumb.width * 2, thumb.height * 2)
                        }
                    }

                    Text {
                        anchors {
                            left: thumb.left
                            top: thumb.bottom
                            topMargin: 6
                        }
                        text: {
                            const m = /^(\S+)\s+\S+\s+(\d+)x(\d+)/.exec(del.modelData.meta ?? "");
                            return m ? m[2] + " × " + m[3] + "  ·  " + m[1] : (del.modelData.meta ?? "");
                        }
                        color: del.fgDim
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                    }
                }
            }

            Component {
                id: emojiRow
                Item {
                    implicitHeight: 56

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: 14
                        }
                        spacing: 14

                        Text {
                            Layout.preferredWidth: 36
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: root.applySkinTone(del.modelData.emoji ?? "", root.skinToneIndex)
                            font.pixelSize: 26
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: del.modelData.name ?? ""
                                color: del.fg
                                font.pixelSize: 14
                                font.family: Config.fontFamily
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: (del.modelData.keywords ?? []).slice(0, 5).join("  ·  ")
                                visible: text !== ""
                                color: del.fgDim
                                font.pixelSize: 11
                                font.family: Config.fontFamily
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 12
            visible: list.count === 0 && !root.busy

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
                    color: Colors.md3.on_primary_container
                    font.pixelSize: 22
                    font.family: Config.fontFamily
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root._emptyText[root.mode] ?? Localization.t("launcher.no_results")
                color: Colors.md3.on_surface_variant
                font.pixelSize: 13
                font.family: Config.fontFamily
                opacity: 0.6
            }
        }
    }
}
