import Quickshell
import Quickshell.Io
import QtQuick
import qs.style

Item {
    id: root

    property string query: ""
    property bool active: false
    signal selected

    readonly property real listContentHeight: list.contentHeight

    property var _rawEntries: []
    property int selectedIndex: 0

    onActiveChanged: {
        if (active) {
            _rawEntries = [];
            clipProc.running = false;
            clipProc.running = true;
        }
    }
    onQueryChanged: selectedIndex = 0

    function moveUp() {
        if (selectedIndex > 0)
            selectedIndex--;
    }
    function moveDown() {
        if (selectedIndex < list.count - 1)
            selectedIndex++;
    }
    function activateCurrent() {
        const item = clipModel.values[selectedIndex];
        if (item)
            _copy(item);
    }

    function _copy(entry) {
        if (entry.isImage) {
            imgCopyProc.running = false;
            imgCopyProc.command = ["sh", "-c", "clipvault get " + entry.id + " | wl-copy --type '" + entry.mime + "' &"];
            imgCopyProc.running = true;
        } else {
            copyProc.running = false;
            copyProc.command = ["sh", "-c", "clipvault get " + entry.id + " | wl-copy &"];
            copyProc.running = true;
        }
        root.selected();
    }

    function _looksLikeBinary(s) {
        if (s.startsWith("\x89PNG"))
            return true;
        if (s.charCodeAt(0) === 0xFF && s.charCodeAt(1) === 0xD8)
            return true;
        if (s.startsWith("GIF8"))
            return true;
        if (s.startsWith("RIFF"))
            return true;
        let n = 0;
        const len = Math.min(s.length, 32);
        for (let i = 0; i < len; i++) {
            const c = s.charCodeAt(i);
            if (c < 32 && c !== 9 && c !== 10 && c !== 13)
                n++;
        }
        return n > 4;
    }

    ScriptModel {
        id: clipModel
        objectProp: "id"
        values: {
            const q = root.query.trim().toLowerCase();
            if (q === "")
                return root._rawEntries;
            return root._rawEntries.filter(e => e.isImage ? "image".includes(q) : e.content.toLowerCase().includes(q));
        }
    }

    Process {
        id: clipProc
        command: ["clipvault", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = [];
                for (const line of this.text.trim().split("\n")) {
                    if (!line.trim())
                        continue;
                    const tab = line.indexOf("\t");
                    if (tab === -1)
                        continue;
                    const id = line.slice(0, tab).trim();
                    const content = line.slice(tab + 1);
                    const trimmed = content.trim();
                    if (trimmed.startsWith("[[ binary data ")) {
                        const mm = /\[\[ binary data ([^\]]+?)\s*\]\]/.exec(trimmed);
                        parsed.push({
                            id,
                            isImage: true,
                            content: "",
                            mime: mm ? mm[1].trim() : "image/png"
                        });
                    } else {
                        parsed.push({
                            id,
                            isImage: false,
                            content: trimmed,
                            mime: "text/plain"
                        });
                    }
                }
                root._rawEntries = parsed;
                root.selectedIndex = 0;
            }
        }
    }

    Process {
        id: copyProc
        running: false
    }
    Process {
        id: imgCopyProc
        running: false
    }

    ListView {
        id: list
        anchors.fill: parent
        model: clipModel
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selectedIndex
        highlightMoveDuration: 150
        highlightMoveVelocity: -1
        highlightFollowsCurrentItem: true

        highlight: Rectangle {
            radius: 14
            color: Colors.md3.secondary_container
        }

        delegate: Item {
            id: del
            required property var modelData
            required property int index
            width: list.width
            height: del.modelData.isImage ? 72 : Math.max(52, contentText.contentHeight + 24)

            MouseArea {
                id: hov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root._copy(del.modelData)
            }

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Colors.md3.on_surface
                opacity: hov.pressed ? 0.12 : hov.containsMouse ? 0.08 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 80
                    }
                }
            }

            Text {
                id: idLabel
                anchors {
                    left: parent.left
                    leftMargin: 14
                    top: parent.top
                    topMargin: 14
                }
                text: "#" + del.modelData.id
                color: Colors.md3.on_surface_variant
                font.pixelSize: 11
                font.family: Config.fontFamily
                opacity: 0.5
            }

            Text {
                id: contentText
                visible: !del.modelData.isImage
                anchors {
                    left: idLabel.right
                    leftMargin: 8
                    right: parent.right
                    rightMargin: 14
                    top: parent.top
                    topMargin: 12
                }
                text: del.modelData.content.trim()
                color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                font.pixelSize: 13
                font.family: Config.fontFamily
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                lineHeight: 1.3
            }

            Item {
                visible: del.modelData.isImage
                anchors {
                    fill: parent
                    leftMargin: 14
                    rightMargin: 14
                }

                Loader {
                    id: thumbLoader
                    active: del.modelData.isImage
                    sourceComponent: Component {
                        Item {
                            id: thumbItem
                            property string b64: ""
                            Process {
                                command: ["sh", "-c", "clipvault get " + del.modelData.id + " | base64 -w0"]
                                running: true
                                stdout: StdioCollector {
                                    onStreamFinished: thumbItem.b64 = this.text.trim()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: thumb
                    width: 48
                    height: 48
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colors.md3.surface_container_high
                    clip: true

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: (thumbLoader.item?.b64 ?? "") !== "" ? ("data:" + del.modelData.mime + ";base64," + thumbLoader.item.b64) : ""
                        visible: source !== ""
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "󰋩"
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 20
                        font.family: Config.fontFamily
                        visible: (thumbLoader.item?.b64 ?? "") === ""
                        opacity: 0.4
                    }
                }

                Text {
                    anchors {
                        left: thumb.right
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Image"
                    color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                    font.bold: root.selectedIndex === del.index
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
            text: root._rawEntries.length === 0 ? "Loading clipboard..." : "No matches"
        }
    }
}
