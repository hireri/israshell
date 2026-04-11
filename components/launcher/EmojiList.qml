import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    signal selected

    property var _emojis: []
    property bool _loaded: false
    property int selectedIndex: 0

    onQueryChanged: selectedIndex = 0
    Component.onCompleted: loadProc.running = true

    function moveUp() {
        if (selectedIndex > 0)
            selectedIndex--;
    }
    function moveDown() {
        if (selectedIndex < list.count - 1)
            selectedIndex++;
    }
    function activateCurrent() {
        const item = emojiModel.values[selectedIndex];
        if (item)
            _copy(item.emoji);
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
            if (!root._loaded)
                return [];
            const q = root.query.trim().toLowerCase();
            if (q === "")
                return root._emojis.slice(0, 200);
            return root._emojis.filter(e => e.name.toLowerCase().includes(q) || e.keywords.some(k => k.includes(q))).slice(0, 100);
        }
    }

    Process {
        id: loadProc
        command: ["cat", "/usr/lib/python3.14/site-packages/picker/data/emojis_smileys_emotion.csv", "/usr/lib/python3.14/site-packages/picker/data/emojis_people_body.csv", "/usr/lib/python3.14/site-packages/picker/data/emojis_activities.csv", "/usr/lib/python3.14/site-packages/picker/data/emojis_animals_nature.csv", "/usr/lib/python3.14/site-packages/picker/data/emojis_food_drink.csv", "/usr/lib/python3.14/site-packages/picker/data/emojis_objects.csv", "/usr/lib/python3.14/site-packages/picker/data/emojis_travel_places.csv", "/usr/lib/python3.14/site-packages/picker/data/emojis_symbols.csv", "/usr/lib/python3.14/site-packages/picker/data/emojis_flags.csv"]
        stdout: StdioCollector {
            onStreamFinished: {
                const re = /^(\S+)\s+(.*?)\s*(?:<small>\(([^)]*)\)<\/small>)?\s*$/;
                const parsed = [];
                for (const line of this.text.split("\n")) {
                    if (!line.trim())
                        continue;
                    const m = line.match(re);
                    if (!m)
                        continue;
                    parsed.push({
                        emoji: m[1],
                        name: m[2].trim(),
                        keywords: m[3] ? m[3].split(",").map(k => k.trim().toLowerCase()) : []
                    });
                }
                root._emojis = parsed;
                root._loaded = true;
            }
        }
    }

    Process {
        id: copyProc
        running: false
    }

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

        highlight: Rectangle {
            radius: 10
            color: Colors.md3.secondary_container
        }

        delegate: Item {
            id: del
            required property var modelData
            required property int index

            width: list.width
            height: 48

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.md3.on_surface
                    opacity: hov.pressed ? 0.12 : hov.containsMouse ? 0.06 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 80
                        }
                    }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
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
                            color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                            font.pixelSize: 10
                            font.family: Config.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: text !== ""
                            opacity: 0.65
                        }
                    }
                }

                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._copy(del.modelData.emoji)
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
