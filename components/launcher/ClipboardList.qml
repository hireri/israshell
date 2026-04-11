import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    property bool active: false
    signal selected

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
            imgCopyProc.command = ["sh", "-c", "clipvault get " + entry.id + " | wl-copy --type image/png"];
            imgCopyProc.running = true;
        } else {
            copyProc.command = ["wl-copy", entry.content];
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
                    parsed.push({
                        id,
                        content,
                        isImage: root._looksLikeBinary(content)
                    });
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
            radius: 10
            color: Colors.md3.secondary_container
        }

        delegate: Item {
            id: del
            required property var modelData
            required property int index

            width: list.width
            height: del.modelData.isImage ? 80 : 48

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
                    spacing: 12

                    Item {
                        implicitWidth: del.modelData.isImage ? 56 : 24
                        implicitHeight: del.modelData.isImage ? 56 : 24
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            visible: !del.modelData.isImage
                            text: "󰅍"
                            color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                            font.pixelSize: 18
                            font.family: Config.fontFamily
                            opacity: 0.7
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: del.modelData.isImage
                            radius: 8
                            color: Colors.md3.surface_container_high
                            clip: true

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: (thumbLoader.item?.b64 ?? "") !== "" ? "data:image/png;base64," + thumbLoader.item.b64 : ""
                                visible: source !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰋩"
                                color: Colors.md3.on_surface_variant
                                font.pixelSize: 22
                                font.family: Config.fontFamily
                                visible: (thumbLoader.item?.b64 ?? "") === ""
                                opacity: 0.45
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            visible: !del.modelData.isImage
                            text: del.modelData.content.replace(/[\n\r]+/g, " ").replace(/\s+/g, " ").trim()
                            color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: del.modelData.isImage
                            text: "Image"
                            color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            font.bold: root.selectedIndex === del.index
                        }

                        Text {
                            visible: del.modelData.isImage
                            text: "#" + del.modelData.id
                            color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                            font.pixelSize: 10
                            font.family: Config.fontFamily
                            opacity: 0.6
                        }
                    }

                    Text {
                        visible: !del.modelData.isImage
                        text: "#" + del.modelData.id
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 10
                        font.family: Config.fontFamily
                        Layout.alignment: Qt.AlignVCenter
                        opacity: 0.4
                    }
                }

                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._copy(del.modelData)
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
