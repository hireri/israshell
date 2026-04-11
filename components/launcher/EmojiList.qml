import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    signal selected

    readonly property real listContentHeight: list.contentHeight

    property var _emojis: []
    property bool _loaded: false
    property int selectedIndex: 0

    onQueryChanged: selectedIndex = 0
    Component.onCompleted: loadProc.running = true

    function moveUp()   { if (selectedIndex > 0) selectedIndex--; }
    function moveDown() { if (selectedIndex < list.count - 1) selectedIndex++; }
    function activateCurrent() {
        const item = emojiModel.values[selectedIndex];
        if (item) _copy(item.emoji);
    }

    function _copy(emoji) {
        copyProc.command = ["wl-copy", emoji];
        copyProc.running = true;
        root.selected();
    }

    ScriptModel {
        id: emojiModel
        objectProp: "emoji"
        values: {
            if (!root._loaded) return [];
            const q = root.query.trim().toLowerCase();
            if (q === "") return root._emojis.slice(0, 150);
            const words = q.split(/\s+/).filter(Boolean);
            return root._emojis.filter(e => {
                const searchable = (e.name + " " + e.keywords.join(" ")).toLowerCase();
                return words.every(w => searchable.includes(w));
            }).slice(0, 100);
        }
    }

    Process {
        id: loadProc
        command: ["sh", "-c", [
            "dir=\"$HOME/.config/quickshell/components/emojis\"",
            "files=\"emojis_smileys_emotion.csv emojis_people_body.csv emojis_activities.csv emojis_animals_nature.csv emojis_food_drink.csv emojis_objects.csv emojis_travel_places.csv emojis_symbols.csv emojis_flags.csv\"",
            "for f in $files; do cat \"$dir/$f\" 2>/dev/null; done"
        ].join("\n")]
        stdout: StdioCollector {
            onStreamFinished: {
                const re = /^(\S+)\s+(.*?)\s*(?:<small>\(([^)]*)\)<\/small>)?\s*$/;
                const parsed = [];
                for (const line of this.text.split("\n")) {
                    if (!line.trim()) continue;
                    const m = line.match(re);
                    if (!m) continue;
                    parsed.push({
                        emoji:    m[1],
                        name:     m[2].trim(),
                        keywords: m[3] ? m[3].split(",").map(k => k.trim().toLowerCase()) : []
                    });
                }
                root._emojis = parsed;
                root._loaded = true;
            }
        }
    }

    Process { id: copyProc; running: false }

    ListView {
        id: list
        anchors.fill: parent
        model: emojiModel
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selectedIndex
        highlightMoveDuration: 150
        highlightMoveVelocity: -1
        highlightFollowsCurrentItem: true

        highlight: Rectangle { radius: 14; color: Colors.md3.secondary_container }

        delegate: Item {
            id: del
            required property var modelData
            required property int index
            width: list.width
            height: 48

            MouseArea {
                id: hov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root._copy(del.modelData.emoji)
            }

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Colors.md3.on_surface
                opacity: hov.pressed ? 0.12 : hov.containsMouse ? 0.08 : 0
                Behavior on opacity { NumberAnimation { duration: 80 } }
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 14

                Text {
                    text: del.modelData.emoji
                    font.pixelSize: 26
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        text: del.modelData.name
                        color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: del.modelData.keywords.slice(0, 4).join(", ")
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: text !== ""
                        opacity: 0.65
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            color: Colors.md3.on_surface_variant
            font.pixelSize: 13
            font.family: Config.fontFamily
            visible: list.count === 0
            opacity: 0.5
            text: root._loaded ? "No emoji found" : "Loading emoji..."
        }
    }
}
