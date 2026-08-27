pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import Qt5Compat.GraphicalEffects

import qs.style

Item {
    id: root

    required property Item dockRoot

    readonly property int cellSize: dockRoot.itemCellSize ?? 28
    readonly property int glyphSize: dockRoot.itemGlyphSize ?? 18

    property bool fileHovering: false
    readonly property bool highlighted: fileHovering

    property bool full: false
    property bool busy: false

    implicitWidth: cellSize
    implicitHeight: cellSize
    width: implicitWidth
    height: implicitHeight

    function urlToPath(url: string): string {
        if (!url.startsWith("file://")) return "";
        return decodeURIComponent(url.slice(7));
    }

    function trashFiles(urls: var): void {
        const paths = [];
        for (const u of urls) {
            const p = root.urlToPath(String(u));
            if (p !== "") paths.push(p);
        }
        if (paths.length === 0) return;
        root.busy = true;
        trashProc.command = ["gio", "trash"].concat(paths);
        trashProc.running = true;
    }

    Process {
        id: trashProc
        onExited: (code) => {
            if (code !== 0)
                console.log("[dock] gio trash failed with exit code", code);
            root.busy = false;
            checkFullProc.running = true;
        }
    }

    function openTrash(): void {
        Quickshell.execDetached(["gio", "open", "trash:///"]);
    }

    Process {
        id: checkFullProc
        command: ["sh", "-c", "ls -A \"${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files\" 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.full = text.trim() !== ""
        }
    }

    Component.onCompleted: checkFullProc.running = true

    readonly property string iconPath: Quickshell.iconPath(full ? "user-trash-full" : "user-trash", "user-trash")

    scale: highlighted ? 1.15 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.highlighted
            ? Colors.md3.error_container
            : (hover.hovered ? Qt.alpha(Colors.md3.on_surface, 0.08) : Qt.alpha(Colors.md3.secondary_container, 0))

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        IconImage {
            id: trashIcon
            anchors.centerIn: parent
            implicitSize: root.glyphSize
            source: root.iconPath
            asynchronous: true
            visible: !Config.tintIcons
        }

        Loader {
            active: Config.tintIcons
            anchors.fill: trashIcon
            sourceComponent: Colorize {
                source: trashIcon
                hue: Qt.color(Colors.md3.on_surface).hslHue
                saturation: Qt.color(Colors.md3.on_surface).hslSaturation
                lightness: 0.0
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.openTrash()
    }

    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]

        onEntered: root.fileHovering = true
        onExited: root.fileHovering = false
        onDropped: drop => {
            root.fileHovering = false;
            if (drop.hasUrls) {
                root.trashFiles(drop.urls);
                drop.acceptProposedAction();
            }
        }
    }
}
