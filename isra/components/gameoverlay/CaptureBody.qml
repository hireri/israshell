pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Qt.labs.platform as Labs
import qs.components
import qs.components.qstiles
import qs.icons
import qs.services
import qs.style
import "../videoPreview.js" as Jobs

Item {
    id: root

    readonly property string shotsDir: Labs.StandardPaths.writableLocation(Labs.StandardPaths.PicturesLocation).toString().replace(/^file:\/\//, "") + "/Screenshots"
    readonly property string videosDir: Labs.StandardPaths.writableLocation(Labs.StandardPaths.MoviesLocation).toString().replace(/^file:\/\//, "") + "/Recordings"

    readonly property var tools: [
        { verb: "ocr", icon: "ocr", tipKey: "qsTileService.ocr_text" },
        { verb: "cts", icon: "image-search", tipKey: "qsTileService.circle_to_search" },
        { verb: "colorpicker", icon: "colorize", tipKey: "qsTileService.color_picker" }
    ].filter(t => ScreencapService.toolEnabled(t.verb))

    implicitWidth: 340
    implicitHeight: column.implicitHeight

    function stamp(ms) {
        const d = new Date(ms);
        return Qt.formatDate(d, "MMM d") + " · " + Qt.formatTime(d, Config.hourFormat === 0 ? "HH:mm" : "h:mm ap");
    }

    function runTool(verb) {
        if (verb === "colorpicker")
            QsTileService.runColorPicker();
        else
            QsTileService.runScreencap(verb, true);
    }

    function open(path) {
        Qt.openUrlExternally("file://" + path);
    }

    component Recent: Item {
        id: recent

        property string dir
        property int limit: 12
        property var files: []

        function refresh() {
            proc.running = false;
            proc.running = true;
        }

        Component.onCompleted: recent.refresh()

        Process {
            id: proc
            command: ["sh", "-c", "find \"$1\" -maxdepth 1 -type f -printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -n \"$2\"", "--", recent.dir, String(recent.limit)]
            stdout: StdioCollector {
                onStreamFinished: recent.files = text.split("\n").filter(l => l !== "").map(l => {
                    const tab = l.indexOf("\t");
                    const path = l.slice(tab + 1);
                    return { path: path, name: path.split("/").pop(), time: parseFloat(l.slice(0, tab)) * 1000 };
                })
            }
        }
    }

    component Heading: RowLayout {
        id: heading

        property string text
        property string dir

        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: heading.text
            font.family: Config.fontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
            font.letterSpacing: 0.7
            color: Colors.md3.primary
        }

        OverlayButton {
            icon: "folder"
            size: 28
            tip: Localization.t("gameOverlay.open_folder")
            onClicked: Qt.openUrlExternally("file://" + heading.dir)
        }
    }

    component Caption: Rectangle {
        id: caption

        property string text
        property string trailing

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 30
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: Qt.alpha("black", 0.6)
            }
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: 10
                bottom: parent.bottom
                bottomMargin: 6
            }
            text: caption.text
            font.family: Config.fontFamily
            font.pixelSize: 10
            color: "white"
            renderType: Text.NativeRendering
        }

        Text {
            anchors {
                right: parent.right
                rightMargin: 10
                bottom: parent.bottom
                bottomMargin: 6
            }
            text: caption.trailing
            font.family: Config.fontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
            color: "white"
            renderType: Text.NativeRendering
        }
    }

    component ActionTile: ClippingRectangle {
        id: tile

        property string icon
        property string label
        property bool on: false
        property color accent: Colors.md3.primary
        property color accentContent: Colors.md3.on_primary
        property alias sublabelForOn: content.sublabelForOn

        signal clicked

        Layout.fillWidth: true
        implicitHeight: 64
        color: content.bgColor
        radius: content.bgRadius

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        SimpleIconLabelTile {
            id: content
            active: tile.on
            label: tile.label
            accentColor: tile.accent
            accentContentColor: tile.accentContent
            iconComponent: MaterialIcon {
                name: tile.icon
                iconSize: 22
                transitionType: "none"
            }
            onToggled: tile.clicked()
        }
    }

    component CompactTile: ClippingRectangle {
        id: compact

        property bool on: false
        property string icon

        signal clicked

        implicitWidth: 64
        implicitHeight: 64
        color: content.bgColor
        radius: content.bgRadius

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        CompactToggleTile {
            id: content
            active: compact.on
            iconComponent: MaterialIcon {
                name: compact.icon
                iconSize: 22
                filled: compact.on
                transitionType: "wipe-up"
            }
            onToggled: compact.clicked()
        }
    }

    Recent {
        id: shots
        dir: root.shotsDir
    }

    Recent {
        id: videos
        dir: root.videosDir
    }

    Connections {
        target: ScreencapService
        function onIsRecordingChanged() {
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 2500
        onTriggered: {
            shots.refresh();
            videos.refresh();
        }
    }

    Component {
        id: shotTile

        Item {
            id: shot

            property var modelData
            property int index
            property real visibleWidth: width

            Rectangle {
                anchors.fill: parent
                color: Colors.md3.surface_container_high
            }

            Image {
                anchors.fill: parent
                source: shot.modelData ? "file://" + shot.modelData.path : ""
                sourceSize.width: 320
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            Caption {
                text: shot.modelData ? root.stamp(shot.modelData.time) : ""
            }

            OverlayButton {
                x: (shot.width + shot.visibleWidth) / 2 - width - 6
                y: 6
                readonly property bool shown: (hover.hovered || hovered) && shot.visibleWidth > 90
                opacity: shown ? 1 : 0
                enabled: shown

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                icon: "copy"
                size: 26
                tip: Localization.t("gameOverlay.copy")
                onClicked: Quickshell.execDetached(["sh", "-c", "wl-copy < \"$1\"", "--", shot.modelData.path])
            }

            HoverHandler {
                id: hover
            }
        }
    }

    Component {
        id: videoTile

        Item {
            id: clip

            property var modelData
            property int index

            VideoPreview {
                id: preview
                path: clip.modelData ? clip.modelData.path : ""
            }

            Rectangle {
                anchors.fill: parent
                color: Colors.md3.surface_container_high
            }

            Image {
                anchors.fill: parent
                source: preview.frame ? "file://" + preview.frame : ""
                sourceSize.width: 320
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            Rectangle {
                anchors.centerIn: parent
                width: 36
                height: 36
                radius: 18
                color: Qt.alpha("black", 0.45)

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "play-pause"
                    iconSize: 18
                    color: "white"
                    transitionType: "none"
                }
            }

            Caption {
                text: clip.modelData ? root.stamp(clip.modelData.time) : ""
                trailing: Jobs.formatDuration(preview.duration)
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            CompactTile {
                icon: "screenshot"
                onClicked: QsTileService.runScreencap("activate", true)
            }

            ActionTile {
                on: ScreencapService.isRecording
                accent: Colors.md3.error
                accentContent: Colors.md3.on_error
                icon: "record"
                label: Localization.t("qsTileService.record")
                sublabelForOn: on => on ? ScreencapService.recordingTime : null
                onClicked: QsTileService.runScreencap("record", !ScreencapService.isRecording)
            }

            CompactTile {
                on: !AudioService.sourceMuted
                icon: "mic"
                onClicked: AudioService.toggleSourceMute()
            }
        }

        RowLayout {
            visible: root.tools.length > 0
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.tools

                delegate: OverlayButton {
                    required property var modelData
                    icon: modelData.icon
                    tip: Localization.t(modelData.tipKey)
                    onClicked: root.runTool(modelData.verb)
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Heading {
            text: Localization.t("gameOverlay.screenshots")
            dir: root.shotsDir
        }

        Carousel {
            visible: shots.files.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 104
            model: shots.files
            delegate: shotTile
            itemSize: 150
            leadingPadding: 0
            trailingPadding: 0
            verticalPadding: 0
            onActivated: i => root.open(shots.files[i].path)
        }

        Text {
            visible: shots.files.length === 0
            text: Localization.t("gameOverlay.nothing_yet")
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.outline
        }

        Heading {
            text: Localization.t("gameOverlay.recordings")
            dir: root.videosDir
        }

        Carousel {
            visible: videos.files.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 104
            model: videos.files
            delegate: videoTile
            itemSize: 150
            leadingPadding: 0
            trailingPadding: 0
            verticalPadding: 0
            onActivated: i => root.open(videos.files[i].path)
        }

        Text {
            visible: videos.files.length === 0
            text: Localization.t("gameOverlay.nothing_yet")
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.outline
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
