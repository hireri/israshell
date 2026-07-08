pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services
import qs.settings.components
import qs.icons

PageBase {
    title: "Overview"
    subtitle: "Wallpaper and appearance"

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            id: topLayout
            Layout.fillWidth: true
            spacing: 8

            readonly property real _previewHeight: width * 0.58 * 9 / 16

            Item {
                Layout.preferredWidth: parent.width * 0.58
                Layout.preferredHeight: Layout.preferredWidth * 9 / 16
                Layout.alignment: Qt.AlignTop

                ClippingRectangle {
                    id: previewClip
                    anchors.fill: parent
                    radius: 18
                    color: Colors.md3.surface_container_high

                    Image {
                        anchors.fill: parent
                        source: WallpaperService.currentWall !== "" ? "file://" + WallpaperService.currentWall : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready
                        sourceSize: Qt.size(840, 472)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No wallpaper"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Colors.md3.outline
                        visible: WallpaperService.currentWall === ""
                    }

                    Item {
                        id: colorPickerContainer
                        readonly property int pillCount: WallpaperService.sourceColorCandidates.length
                        property int heldIndex: -1

                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 10
                        
                        width: {
                            if (pillCount === 0) return 0;
                            let innerWidth = 60 + (pillCount - 1) * 24;
                            let spacingWidth = Math.max(0, pillCount - 1) * 4;
                            return innerWidth + spacingWidth + 8;
                        }
                        height: 32
                        visible: pillCount > 0

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            id: containerBg
                            anchors.fill: parent

                            readonly property int lastIndex: WallpaperService.sourceColorCandidates.length - 1
                            readonly property bool firstSelected: WallpaperService.currentSourceIndex === 0 || colorPickerContainer.heldIndex === 0
                            readonly property bool lastSelected: WallpaperService.currentSourceIndex === lastIndex || colorPickerContainer.heldIndex === lastIndex

                            topLeftRadius: firstSelected ? 20 : 18
                            topRightRadius: lastSelected ? 20 : 18
                            bottomLeftRadius: firstSelected ? 20 : 18
                            bottomRightRadius: lastSelected ? 20 : 18

                            color: Colors.md3.surface_container_high

                            Behavior on topLeftRadius { NumberAnimation { duration: 120 } }
                            Behavior on topRightRadius { NumberAnimation { duration: 120 } }
                            Behavior on bottomLeftRadius { NumberAnimation { duration: 120 } }
                            Behavior on bottomRightRadius { NumberAnimation { duration: 120 } }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Repeater {
                                model: WallpaperService.sourceColorCandidates

                                ClippingRectangle {
                                    id: chip
                                    required property var modelData
                                    required property int index

                                    readonly property bool active: WallpaperService.currentSourceIndex === index
                                    readonly property bool isFirst: index === 0
                                    readonly property bool isLastChip: index === WallpaperService.sourceColorCandidates.length - 1

                                    readonly property string pillColor: modelData ?? "transparent"

                                    readonly property real baseWidth: active ? 60 : 24
                                    readonly property real growDelta: 20
                                    readonly property real shrinkDelta: WallpaperService.sourceColorCandidates.length > 1 ? (growDelta / (WallpaperService.sourceColorCandidates.length - 1)) : 0

                                    readonly property real targetWidth: {
                                        if (colorPickerContainer.heldIndex === -1) {
                                            return baseWidth;
                                        } else if (colorPickerContainer.heldIndex === index) {
                                            return baseWidth + growDelta;
                                        } else {
                                            return Math.max(16, baseWidth - shrinkDelta);
                                        }
                                    }

                                    height: 24
                                    width: targetWidth
                                    anchors.verticalCenter: parent.verticalCenter

                                    color: pillColor === "transparent" ? Colors.md3.surface_container_highest : pillColor

                                    topLeftRadius: (active || isFirst) ? 20 : 6
                                    bottomLeftRadius: (active || isFirst) ? 20 : 6
                                    topRightRadius: (active || isLastChip) ? 20 : 6
                                    bottomRightRadius: (active || isLastChip) ? 20 : 6

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 120
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on topLeftRadius { NumberAnimation { duration: 120 } }
                                    Behavior on bottomLeftRadius { NumberAnimation { duration: 120 } }
                                    Behavior on topRightRadius { NumberAnimation { duration: 120 } }
                                    Behavior on bottomRightRadius { NumberAnimation { duration: 120 } }

                                    function isColorDark(colorString) {
                                        let c = Qt.color(colorString);
                                        let luminance = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
                                        return luminance < 0.5;
                                    }

                                    Text {
                                        id: chipLabel
                                        anchors.centerIn: parent
                                        text: active ? "󰄬" : (pillColor === "transparent" ? (index + 1).toString() : "")
                                        font.family: Config.fontFamily
                                        font.pixelSize: active ? 12 : 11
                                        font.weight: active ? Font.Medium : Font.Normal
                                        color: {
                                            if (active) {
                                                if (pillColor === "transparent") return Colors.md3.primary;
                                                return isColorDark(pillColor) ? "#ffffff" : "#000000";
                                            }
                                            return Colors.md3.on_surface_variant;
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true

                                        readonly property bool isHeld: pressed && containsMouse

                                        onIsHeldChanged: {
                                            if (isHeld) {
                                                colorPickerContainer.heldIndex = index;
                                            } else if (colorPickerContainer.heldIndex === index) {
                                                colorPickerContainer.heldIndex = -1;
                                            }
                                        }

                                        onClicked: {
                                            WallpaperService.selectSourceColor(index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: topLayout._previewHeight
                Layout.alignment: Qt.AlignTop
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    SchemeButton {
                        Layout.fillWidth: true
                        label: "Light"
                        active: !WallpaperService.isDark
                        onClicked: WallpaperService.isDark = false

                        LightModeIcon {
                            color: WallpaperService.isDark ? Colors.md3.on_surface : Colors.md3.on_primary
                            iconSize: 26
                            filled: !WallpaperService.isDark
                        }
                    }

                    SchemeButton {
                        Layout.fillWidth: true
                        label: "Dark"
                        active: WallpaperService.isDark
                        onClicked: WallpaperService.isDark = true

                        DarkModeIcon {
                            color: !WallpaperService.isDark ? Colors.md3.on_surface : Colors.md3.on_primary
                            iconSize: 26
                            filled: WallpaperService.isDark
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    readonly property int cols: 3
                    readonly property int rows: 2
                    readonly property real hGap: 6
                    readonly property real vGap: 6
                    readonly property real swatchWidth: (width - hGap * (cols - 1)) / cols
                    readonly property real swatchHeight: (height - vGap * (rows - 1)) / rows

                    readonly property var schemes: ["scheme-tonal-spot", "scheme-rainbow", "scheme-vibrant", "scheme-expressive", "scheme-fruit-salad", "scheme-monochrome"]

                    Repeater {
                        model: parent.schemes

                        delegate: Item {
                            required property string modelData
                            required property int index

                            readonly property int col: index % 3
                            readonly property int row: Math.floor(index / 3)

                            x: col * (parent.swatchWidth + parent.hGap)
                            y: row * (parent.swatchHeight + parent.vGap)
                            width: parent.swatchWidth
                            height: parent.swatchHeight

                            readonly property bool isSelected: WallpaperService.currentScheme === modelData
                            readonly property var preview: WallpaperService.schemePreviews[modelData] ?? null
                            readonly property string primaryColor: preview ? preview.primary : Colors.md3.surface_container_highest
                            readonly property string secondaryColor: preview ? preview.secondary : Colors.md3.surface_container_high
                            readonly property string tertiaryColor: preview ? preview.tertiary : Colors.md3.surface_variant

                            opacity: WallpaperService.previewsLoading ? 0.5 : 1.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: isSelected ? (swatch.containsMouse ? Qt.lighter(Colors.md3.secondary_container, WallpaperService.isDark ? 1.12 : 0.88) : Colors.md3.secondary_container) : (swatch.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            ClippingRectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) * 0.7
                                height: width
                                radius: width / 2
                                color: Colors.md3.surface_container_high

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: parent.height / 2
                                    color: primaryColor
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    width: parent.width / 2
                                    height: parent.height / 2
                                    color: secondaryColor
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    width: parent.width / 2
                                    height: parent.height / 2
                                    color: tertiaryColor
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: swatch
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                enabled: !WallpaperService.applying && !WallpaperService.previewsLoading && WallpaperService.currentWall !== ""
                                onClicked: WallpaperService.selectScheme(modelData)
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 17
                topRightRadius: 8
                bottomRightRadius: 8
                color: Colors.md3.primary

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    topRightRadius: parent.topRightRadius
                    bottomRightRadius: parent.bottomRightRadius
                    color: folderMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Text {
                        text: "󰇎"
                        font.pixelSize: 14
                        color: Colors.md3.on_primary
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Shuffle from folder"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.md3.on_primary
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: folderMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: WallpaperService.randomize()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 8
                color: konachanMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Text {
                        text: "󰒝"
                        font.pixelSize: 14
                        color: konachanMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "from Konachan"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: konachanMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: konachanMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: WallpaperService.randomizeKonachan()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 8
                color: wallhavenMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Text {
                        text: "󰒝"
                        font.pixelSize: 14
                        color: wallhavenMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "from Wallhaven"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: wallhavenMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: wallhavenMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: WallpaperService.randomizeWallhaven()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 17
                topLeftRadius: 8
                bottomLeftRadius: 8
                color: redditMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    Text {
                        text: "󰒝"
                        font.pixelSize: 14
                        color: redditMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "from Reddit"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: redditMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: redditMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: WallpaperService.randomizeReddit()
                }
            }
        }
    }

    SectionCard {
        label: "Appearance"
        Layout.fillWidth: true

        SettingChips {
            label: "Clock format"
            options: [
                {
                    label: "24h",
                    value: 0
                },
                {
                    label: "12h",
                    value: 1
                }
            ]
            currentValue: Config.hourFormat
            onSelected: v => Config.update({
                    hourFormat: v
                })
        }

        SettingSwitch {
            label: "Screen corners"
            sublabel: "Rounded corner overlay"
            checked: Config.screenCorners
            onToggled: v => Config.update({
                    screenCorners: v
                })
        }

        SettingSwitch {
            label: "Desktop clock"
            sublabel: "Clock widget on wallpaper"
            checked: Config.desktopClock
            onToggled: v => Config.update({
                    desktopClock: v
                })
        }

        SettingRow {
            id: editRow
            isLast: true
            label: "Edit config.json"
            sublabel: "Open in default editor"

            Text {
                text: "󰬪"
                font.pixelSize: 18
                color: editMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.outline
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            MouseArea {
                id: editMouse
                parent: editRow
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: Qt.openUrlExternally("file://" + Quickshell.env("HOME") + "/.config/quickshell/isra/config.json")
            }
        }
    }
}
