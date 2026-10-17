pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import qs.style
import qs.services
import qs.components
import qs.windows.components
import "format.js" as Fmt
import "treemap.js" as TM

Panel {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property var nodes: TM.stored()?.nodes ?? ({})
    property real at: TM.stored()?.at ?? 0
    property string current: root.home
    property string scanning: ""
    property int rev: 0
    property int hovered: -1

    readonly property bool has: root.nodes[root.home] !== undefined
    readonly property var node: { root.rev; return root.nodes[root.current] ?? null; }
    readonly property var list: { root.rev; return TM.items(root.nodes, root.current); }
    readonly property var rects: TM.layout(root.list, map.width, map.height)
    readonly property var crumbs: {
        const out = [{ label: "~", path: root.home }];
        let acc = root.home;
        const rel = root.current.slice(root.home.length).split("/").filter(s => s !== "");
        for (const seg of rel) {
            acc += "/" + seg;
            out.push({ label: seg, path: acc });
        }
        return out;
    }
    readonly property var fills: [Colors.md3.primary_container, Colors.md3.secondary_container, Colors.md3.tertiary_container]
    readonly property var inks: [Colors.md3.on_primary_container, Colors.md3.on_secondary_container, Colors.md3.on_tertiary_container]

    function labelOf(it: var): string {
        return it.files ? Localization.t("systemApp.files_here") : it.other ? Localization.t("systemApp.disk_other") : it.name;
    }

    function start(path: string): void {
        if (root.scanning !== "")
            return;
        root.scanning = path;
        scan.command = ["sh", "-c", 'exec nice -n 19 ionice -c 3 du -x -B1 --max-depth=3 -- "$1" 2>/dev/null', "sh", path];
        scan.running = true;
    }

    function cancel(): void {
        root.scanning = "";
        scan.running = false;
    }

    function enter(path: string): void {
        const n = root.nodes[path];
        if (!n)
            return;
        if (n.scanned)
            root.current = path;
        else
            root.start(path);
    }

    function _done(text: string): void {
        const path = root.scanning;
        if (path === "")
            return;
        root.scanning = "";
        const nodes = TM.merge(TM.stored()?.nodes ?? ({}), text, path);
        if (!nodes[path])
            return;
        TM.store(nodes);
        root.nodes = nodes;
        root.at = TM.stored().at;
        root.current = path;
        root.rev++;
    }

    title: Localization.t("systemApp.disk_map")
    subtitle: root.has && root.node ? Fmt.bytes(root.node.size) + " · " + Localization.t("systemApp.scanned_ago").replace("%1", Fmt.ago(root.at)) : ""

    Component.onCompleted: {
        if (!root.has || Date.now() - root.at > 300000)
            root.start(root.home);
    }

    actions: [
        ActionButton {
            visible: root.has && root.scanning === ""
            icon: "arrow-forward"
            label: Localization.t("systemApp.open_folder")
            onClicked: Quickshell.execDetached(["xdg-open", root.current])
        },
        ActionButton {
            visible: root.scanning !== ""
            label: Localization.t("systemApp.cancel")
            onClicked: root.cancel()
        },
        ActionButton {
            visible: root.scanning === ""
            icon: root.has ? "restart" : "search"
            label: root.has ? Localization.t("systemApp.rescan") : Localization.t("systemApp.scan")
            onClicked: root.start(root.has ? root.current : root.home)
        }
    ]

    Process {
        id: scan
        stdout: StdioCollector {
            onStreamFinished: root._done(this.text)
        }
    }

    Loader {
        Layout.fillWidth: true
        active: root.scanning !== ""
        sourceComponent: Spinner {
            running: true
            implicitHeight: 3
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 4
        visible: !root.has && root.scanning === ""
        text: Localization.t("systemApp.disk_hint")
        wrapMode: Text.WordWrap
        font.family: Config.fontFamily
        font.pixelSize: 13
        color: Colors.md3.on_surface_variant
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 4
        visible: root.scanning !== ""
        text: Localization.t("systemApp.scanning").replace("%1", root.scanning.replace(root.home, "~"))
        elide: Text.ElideMiddle
        font.family: Config.fontFamily
        font.pixelSize: 12
        color: Colors.md3.outline
    }

    Flow {
        Layout.fillWidth: true
        Layout.topMargin: 6
        visible: root.has
        spacing: 6

        Repeater {
            model: root.crumbs

            Pill {
                id: crumb
                required property var modelData
                required property int index
                dot: false
                implicitHeight: 26
                text: crumb.modelData.label
                tone: crumb.index === root.crumbs.length - 1 ? "primary" : "neutral"
                clickable: crumb.index < root.crumbs.length - 1 && root.scanning === ""
                onClicked: root.current = crumb.modelData.path
            }
        }
    }

    GridLayout {
        id: body
        Layout.fillWidth: true
        Layout.topMargin: 10
        visible: root.has
        columns: width > 640 ? 2 : 1
        columnSpacing: 12
        rowSpacing: 12

        Item {
            id: map
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            clip: true
            opacity: root.scanning !== "" ? 0.5 : 1

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            Repeater {
                model: root.rects

                Rectangle {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property var it: cell.modelData.item
                    readonly property bool passive: cell.it.path === null
                    readonly property string name: root.labelOf(cell.it)

                    x: Math.round(cell.modelData.x) + 1
                    y: Math.round(cell.modelData.y) + 1
                    width: Math.max(0, Math.round(cell.modelData.w) - 2)
                    height: Math.max(0, Math.round(cell.modelData.h) - 2)
                    radius: 8
                    color: cell.passive ? Config.dim(Colors.md3.surface_container_high) : root.fills[cell.index % 3]

                    Column {
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        visible: cell.width > 70 && cell.height > 40
                        clip: true

                        Text {
                            width: parent.width
                            text: cell.name
                            elide: Text.ElideRight
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: cell.passive ? Colors.md3.on_surface_variant : root.inks[cell.index % 3]
                        }

                        Text {
                            width: parent.width
                            text: Fmt.bytes(cell.it.size)
                            elide: Text.ElideRight
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: cell.passive ? Colors.md3.outline : Qt.alpha(root.inks[cell.index % 3], 0.8)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: cell.radius
                        color: Colors.md3.on_surface
                        opacity: !cell.passive && root.hovered === cell.index ? 0.1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }
                    }

                    Tooltip {
                        text: cell.name + "\n" + Fmt.bytes(cell.it.size)
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !cell.passive && root.scanning === ""
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.hovered = cell.index;
                            else if (root.hovered === cell.index)
                                root.hovered = -1;
                        }
                        onClicked: root.enter(cell.it.path)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: body.columns === 1
            Layout.preferredWidth: 250
            Layout.preferredHeight: body.columns === 2 ? 320 : 200
            Layout.alignment: Qt.AlignTop
            radius: 16
            color: Config.dim(Colors.md3.surface_container_highest)

            ListView {
                id: kids
                anchors {
                    fill: parent
                    margins: 6
                }
                clip: true
                model: root.list
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: kids.contentHeight > kids.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool passive: row.modelData.path === null

                    width: ListView.view.width - 12
                    height: 34
                    radius: 10
                    color: Qt.alpha(Colors.md3.on_surface, !row.passive && root.hovered === row.index ? 0.08 : 0)

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            radius: 4
                            color: row.passive ? Config.dim(Colors.md3.surface_container_highest) : root.fills[row.index % 3]
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.labelOf(row.modelData)
                            elide: Text.ElideRight
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            color: row.passive ? Colors.md3.on_surface_variant : Colors.md3.on_surface
                        }

                        Text {
                            text: Fmt.bytes(row.modelData.size)
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: Colors.md3.outline
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !row.passive && root.scanning === ""
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.hovered = row.index;
                            else if (root.hovered === row.index)
                                root.hovered = -1;
                        }
                        onClicked: root.enter(row.modelData.path)
                    }
                }
            }
        }
    }
}
