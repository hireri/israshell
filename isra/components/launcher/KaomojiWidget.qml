import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    signal copyResult(string result)
    signal categoryRequested(string tag)

    readonly property bool hasResult: _filtered.length > 0

    property var entries: []
    readonly property var _defaultTags: ["happy", "love", "sad", "angry", "confused", "sleepy", "disapproval", "wave", "cat", "bear", "cool", "music"]

    readonly property var _sections: [
        {
            title: "happy",
            tags: ["happy", "joy", "yay", "excited", "smile", "giddy", "giggle", "chuckle", "snicker", "laugh", "lol", "dance", "party", "groove", "cheer"]
        },
        {
            title: "love",
            tags: ["love", "heart", "heart-eyes", "adore", "hug", "blush", "shy", "cute", "kiss", "sweet"]
        },
        {
            title: "sad & sleepy",
            tags: ["sad", "cry", "weep", "tears", "despair", "disappointed", "pout", "sleepy", "tired", "zzz", "bedtime", "rub", "yawn", "exhausted", "dead", "ghost"]
        },
        {
            title: "angry & unimpressed",
            tags: ["angry", "mad", "rage", "table", "flip", "punch", "rude", "disapproval", "unimpressed", "side-eye", "sigh", "bored", "annoyed"]
        },
        {
            title: "confused & surprised",
            tags: ["confused", "unsure", "skeptical", "huh", "shrug", "whatever", "idk", "sweat", "tilt", "think", "hmm", "pondering", "surprised", "shock", "gasp", "panic", "scared", "nervous", "wow", "amazed"]
        },
        {
            title: "actions & animals",
            tags: ["cat", "bear", "dog", "animal", "wave", "hi", "hello", "greeting", "bye", "bow", "respect", "salute", "food", "ok", "peace", "fight", "strut", "cool", "music", "pointing", "toast", "cheers"]
        }
    ]

    property string _copiedFace: ""
    readonly property int _tileHeight: 52
    readonly property int _maxGridHeight: 260

    readonly property var _uniqueEntries: {
        const seen = {};
        return entries.filter(e => {
            if (!e.face || seen[e.face]) return false;
            seen[e.face] = true;
            return true;
        });
    }

    readonly property var _filtered: {
        const q = query.trim().toLowerCase();
        if (!q) return _uniqueEntries;
        return _uniqueEntries.filter(e => 
            e.tags && e.tags.some(t => t.toLowerCase().includes(q))
        );
    }

    readonly property var _categorizedData: {
        if (query.trim() !== "") return [];
        
        const assigned = new Set();
        const groups = [];

        for (const sec of _sections) {
            const items = _uniqueEntries.filter(e => {
                if (assigned.has(e.face)) return false;
                const match = e.tags && e.tags.some(t => sec.tags.includes(t));
                if (match) {
                    assigned.add(e.face);
                    return true;
                }
                return false;
            });
            if (items.length > 0) {
                groups.push({ title: sec.title, items: items });
            }
        }

        const remaining = _uniqueEntries.filter(e => !assigned.has(e.face));
        if (remaining.length > 0) {
            groups.push({ title: "other", items: remaining });
        }
        return groups;
    }

    implicitHeight: content.implicitHeight

    Column {
        id: content
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 8

        Text {
            visible: root.entries.length > 0 && root.query.trim() !== "" && root._filtered.length === 0
            width: parent.width
            text: "no kaomoji found for \"" + root.query.trim() + "\""
            color: Colors.md3.on_surface_variant
            font.pixelSize: 14
            font.family: Config.fontFamily
            opacity: 0.85
        }

        Flickable {
            id: scrollArea
            width: parent.width
            visible: root._filtered.length > 0
            implicitHeight: Math.min(contentCol.implicitHeight, root._maxGridHeight)
            contentHeight: contentCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentCol
                width: scrollArea.width
                spacing: 12

                Flow {
                    width: parent.width
                    visible: root.query.trim() !== ""
                    spacing: 6

                    Repeater {
                        model: root._filtered
                        delegate: kaomojiTileDelegate
                    }
                }

                Repeater {
                    model: root.query.trim() === "" ? root._categorizedData : []
                    delegate: Column {
                        width: contentCol.width
                        spacing: 6
                        required property var modelData

                        Text {
                            text: modelData.title.toUpperCase()
                            color: Colors.md3.primary
                            font.pixelSize: 11
                            font.letterSpacing: 1.0
                            font.weight: Font.Bold
                            font.family: Config.fontFamily
                        }

                        Flow {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: modelData.items
                                delegate: kaomojiTileDelegate
                            }
                        }
                    }
                }
            }
        }

        Flow {
            width: parent.width
            visible: root.query.trim() === ""
            spacing: 6

            Repeater {
                model: root._defaultTags

                Rectangle {
                    id: chip
                    required property string modelData

                    implicitWidth: catLbl.implicitWidth + 18
                    implicitHeight: 26
                    radius: height / 2
                    color: catMa.containsMouse ? Colors.md3.secondary_container : Colors.md3.surface_container_high
                    border.width: catMa.containsMouse ? 0 : 1
                    border.color: Colors.md3.outline_variant
                    scale: catMa.pressed ? 0.95 : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }

                    Text {
                        id: catLbl
                        anchors.centerIn: parent
                        text: chip.modelData
                        color: catMa.containsMouse ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                        font.pixelSize: 11
                        font.letterSpacing: 0.3
                        font.family: Config.fontFamily
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: catMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.categoryRequested(chip.modelData);
                        }
                    }
                }
            }
        }
    }

    Component {
        id: kaomojiTileDelegate

        Rectangle {
            id: tile
            required property var modelData
            readonly property bool _copied: root._copiedFace === modelData.face

            width: Math.max(64, faceLbl.implicitWidth + 18)
            height: root._tileHeight
            radius: 12
            color: tile._copied ? Colors.md3.primary_container : (tileMa.containsMouse ? Colors.md3.secondary_container : Colors.md3.surface_container_high)
            scale: tileMa.pressed ? 0.94 : 1.0

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.6
                }
            }

            Text {
                id: faceLbl
                anchors.centerIn: parent
                text: tile._copied ? "copied!" : tile.modelData.face
                color: tile._copied ? Colors.md3.on_primary_container : (tileMa.containsMouse ? Colors.md3.on_secondary_container : Colors.md3.on_surface)
                font.pixelSize: tile._copied ? 12 : 17
                font.family: Config.fontFamily
                font.weight: tile._copied ? Font.Medium : Font.Normal
            }

            MouseArea {
                id: tileMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.copyResult(tile.modelData.face);
                    root._copiedFace = tile.modelData.face;
                    copiedResetTimer.restart();
                }
            }
        }
    }

    Timer {
        id: copiedResetTimer
        interval: 900
        onTriggered: root._copiedFace = ""
    }
}