pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.style
import qs.services
import qs.icons
import qs.windows.components
import qs.components
import Quickshell.Widgets

PageBase {
    title: "Background"
    subtitle: "Effects, wallpaper, widgets"

    function titleCase(str) {
        return str.split(/[-_ ]+/).map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
    }

    Component {
        id: spritePreviewIcon
        Image {
            property var modelData: null
            width: 32
            height: 32
            smooth: false
            mipmap: false
            fillMode: Image.Stretch
            source: modelData ? ("file://" + Quickshell.shellDir + "/sprites/" + modelData.value + ".gif") : ""
            sourceClipRect: Qt.rect(3 * 32, 3 * 32, 32, 32)
        }
    }

    SectionCard {
        label: "Wallpaper"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Use awww"
            sublabel: "Delegate wallpaper to awww instead of built in, WON'T SUPPORT VIDEOS"
            checked: Config.useAwww
            onToggled: v => Config.update({ useAwww: v })
        }

        SettingSelect {
            label: "Transition"
            sublabel: "Effect used when switching wallpapers"
            options: [
                { label: "Crossfade", value: "crossfade" },
                { label: "Directional wipe", value: "wipe" },
                { label: "Circle reveal", value: "circle" },
                { label: "Random", value: "random" }
            ]
            currentValue: Config.background.transitionType
            onSelected: v => Config.update({
                background: Object.assign({}, Config.background, { transitionType: v })
            })
        }

        SettingSlider {
            isLast: true
            label: "Transition duration"
            sublabel: "How long the wallpaper transition takes"
            from: 150
            to: 2000
            stepSize: 50
            unit: "ms"
            value: Config.background.transitionDuration
            onMoved: v => Config.update({
                background: Object.assign({}, Config.background, { transitionDuration: Math.round(v) })
            })
        }
    }

    Component {
        id: arrowUpwardComp
        MaterialIcon {
            name: "arrow-upward"
            iconSize: 16
        }
    }
    Component {
        id: arrowDownwardComp
        MaterialIcon {
            name: "arrow-downward"
            iconSize: 16
        }
    }

    HeroCard {
        Layout.fillWidth: true
        title: "Audio Visualizer"
        subtitle: Config.cava.enabled ? "Active · " + Config.cava.bars + " bars" : "Off"
        iconBg: Colors.md3.primary_container
        cardColor: Colors.md3.surface_container
        checked: Config.cava.enabled
        onToggled: v => Config.update({
                cava: Object.assign({}, Config.cava, {
                    enabled: v
                })
            })
        
        MaterialIcon {
            name: "equalizer"
            iconSize: 22
            color: Colors.md3.primary
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layoutInner.implicitHeight + 32
        radius: 20
        color: (Config.dim(Colors.md3.surface_container))

        ColumnLayout {
            id: layoutInner
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 16
            }
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    id: btnCurve
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    topRightRadius: active ? 17 : 8
                    bottomRightRadius: active ? 17 : 8

                    Behavior on topRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.cava.renderType === "curve"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (curveMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (curveMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        topRightRadius: parent.topRightRadius
                        bottomRightRadius: parent.bottomRightRadius
                        color: curveMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnCurve.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "earthquake"
                            iconSize: 14
                            color: btnCurve.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Curve"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnCurve.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: curveMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Config.update({
                                cava: Object.assign({}, Config.cava, { renderType: "curve" })
                            })
                    }
                }

                Rectangle {
                    id: btnBars
                    Layout.fillWidth: true
                    height: 34
                    radius: active ? 17 : 8

                    Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.cava.renderType === "bars"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (barsMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (barsMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: barsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnBars.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "bar-chart"
                            iconSize: 14
                            color: btnBars.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Bars"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnBars.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: barsMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Config.update({
                                cava: Object.assign({}, Config.cava, { renderType: "bars" })
                            })
                    }
                }

                Rectangle {
                    id: btnBlocks
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    topLeftRadius: active ? 17 : 8
                    bottomLeftRadius: active ? 17 : 8

                    Behavior on topLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on bottomLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.cava.renderType === "blocks"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (blocksMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (blocksMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        topLeftRadius: parent.topLeftRadius
                        bottomLeftRadius: parent.bottomLeftRadius
                        color: blocksMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnBlocks.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "grid-view"
                            iconSize: 14
                            color: btnBlocks.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Blocks"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnBlocks.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: blocksMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Config.update({
                                cava: Object.assign({}, Config.cava, { renderType: "blocks" })
                            })
                    }
                }
            }

            ClippingRectangle {
                id: singlePreview
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: (Config.dim(Colors.md3.surface_container_high))
                radius: 12

                Image {
                    id: wallView
                    source: WallpaperService.currentWall !== "" ? "file://" + WallpaperService.currentWallPreview : ""
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    anchors.fill: parent
                    visible: source !== ""
                    sourceSize: Qt.size(480, 270)
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colors.md3.surface, 0.4)
                    visible: wallView.visible
                }

                CavaVisualizer {
                    id: previewVisualizer
                    anchors.fill: parent
                    overrideMaxHeight: 120
                    useMock: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.md3.outline_variant
                opacity: 0.15
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 6

                    Text {
                        text: "Main color"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.outline
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error"]
                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                readonly property int  lastIndex:  3
                                readonly property bool isFirst:    index === 0
                                readonly property bool isLast:     index === lastIndex
                                readonly property bool isSelected: Config.cava.color === modelData

                                Layout.fillWidth: true
                                height: 28
                                color: Colors.md3[modelData] ?? Colors.md3.primary

                                topLeftRadius:     isFirst    ? 14 : (isSelected ? 14 : 6)
                                topRightRadius:    isLast     ? 14 : (isSelected ? 14 : 6)
                                bottomLeftRadius:  isFirst    ? 14 : (isSelected ? 14 : 6)
                                bottomRightRadius: isLast     ? 14 : (isSelected ? 14 : 6)

                                Behavior on topLeftRadius     { NumberAnimation { duration: 150 } }
                                Behavior on topRightRadius    { NumberAnimation { duration: 150 } }
                                Behavior on bottomLeftRadius  { NumberAnimation { duration: 150 } }
                                Behavior on bottomRightRadius { NumberAnimation { duration: 150 } }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.update({
                                            cava: Object.assign({}, Config.cava, { color: modelData })
                                        })
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 6

                    Text {
                        text: "Accent color"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.outline
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error"]
                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                readonly property int  lastIndex:  3
                                readonly property bool isFirst:    index === 0
                                readonly property bool isLast:     index === lastIndex
                                readonly property bool isSelected: Config.cava.colorAlt === modelData

                                Layout.fillWidth: true
                                height: 28
                                color: Colors.md3[modelData] ?? Colors.md3.error

                                topLeftRadius:     isFirst    ? 14 : (isSelected ? 14 : 6)
                                topRightRadius:    isLast     ? 14 : (isSelected ? 14 : 6)
                                bottomLeftRadius:  isFirst    ? 14 : (isSelected ? 14 : 6)
                                bottomRightRadius: isLast     ? 14 : (isSelected ? 14 : 6)

                                Behavior on topLeftRadius     { NumberAnimation { duration: 150 } }
                                Behavior on topRightRadius    { NumberAnimation { duration: 150 } }
                                Behavior on bottomLeftRadius  { NumberAnimation { duration: 150 } }
                                Behavior on bottomRightRadius { NumberAnimation { duration: 150 } }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.update({
                                            cava: Object.assign({}, Config.cava, { colorAlt: modelData })
                                        })
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.md3.outline_variant
                opacity: 0.15
            }

            SettingChips {
                label: "Position"
                options: [
                    {
                        label: "Top",
                        value: 0,
                        icon: arrowUpwardComp
                    },
                    {
                        label: "Bottom",
                        value: 1,
                        icon: arrowDownwardComp
                    }
                ]
                currentValue: Config.cava.position
                onSelected: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            position: v
                        })
                    })
            }

            SettingChips {
                label: "Layout"
                sublabel: "How bars are arranged across the width"
                options: [
                    {
                        label: "Mono",
                        value: "mono"
                    },
                    {
                        label: "Edges",
                        value: "edges"
                    },
                    {
                        label: "Center",
                        value: "center"
                    }
                ]
                currentValue: Config.cava.layout
                onSelected: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            layout: v
                        })
                    })
            }

            SettingChips {
                label: "Curve type"
                sublabel: Config.cava.renderType === "curve" ? "Smoothing applied to the curve render" : "Requires \"curve\" render type"
                enabled: Config.cava.renderType === "curve"
                opacity: enabled ? 1.0 : 0.4
                options: [
                    {
                        label: "Smooth",
                        value: "smooth"
                    },
                    {
                        label: "Sharp",
                        value: "sharp"
                    }
                ]
                currentValue: Config.cava.curveType
                onSelected: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            curveType: v
                        })
                    })
            }

            SettingSwitch {
                label: "Fill"
                sublabel: "Draw a filled gradient area under the spectrum"
                checked: Config.cava.drawFill
                onToggled: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            drawFill: v
                        })
                    })
            }

            SettingSwitch {
                label: "Stroke"
                sublabel: "Draw an outline along the spectrum"
                checked: Config.cava.drawStroke
                onToggled: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            drawStroke: v
                        })
                    })
            }

            SettingChips {
                label: "Color style"
                sublabel: "How colors are applied across the spectrum"
                options: [
                    {
                        label: "Solid",
                        value: "solid"
                    },
                    {
                        label: "Loudness",
                        value: "loudness"
                    },
                    {
                        label: "Gradient V",
                        value: "gradient-v"
                    },
                    {
                        label: "Gradient H",
                        value: "gradient-h"
                    }
                ]
                currentValue: Config.cava.colorStyle
                onSelected: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            colorStyle: v
                        })
                    })
            }

            SettingSlider {
                label: "Bars"
                sublabel: "Number of frequency bars rendered"
                from: 8
                to: 100
                stepSize: 2
                value: Config.cava.bars
                onMoved: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            bars: Math.round(v)
                        })
                    })
            }

            SettingSlider {
                label: "Height"
                sublabel: "Height of the visualizer in pixels"
                from: 40
                to: 1200
                unit: "px"
                value: Config.cava.height
                onMoved: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            height: Math.round(v)
                        })
                    })
            }

            SettingSlider {
                label: "Opacity"
                sublabel: "Overlay opacity of the visualizer"
                from: 0.05
                to: 1.0
                stepSize: 0.05
                decimals: 2
                value: Config.cava.opacity
                onMoved: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            opacity: v
                        })
                    })
                isLast: true
            }
        }
    }

    SectionCard {
        label: "Weyes"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Enable"
            sublabel: CompositorService.hasCapability("cursorPosition") ? "Show wayland-weyes 👀" : "Requires Hyprland (cursor position isn't available on " + CompositorService.backendName + ")"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            checked: Config.weyes.enabled
            onToggled: v => Config.update({
                    weyes: Object.assign({}, Config.weyes, {
                        enabled: v
                    })
                })
        }

        SettingSwitch {
            label: "Mirror layout"
            sublabel: "Synchronize coords and size across all screens"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            checked: Config.weyes.mirror
            onToggled: v => Config.update({
                    weyes: Object.assign({}, Config.weyes, {
                        mirror: v
                    })
                })
        }

        SettingSwitch {
            label: "Tinted"
            sublabel: "Match colors to the system theme"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            checked: Config.weyes.tinted
            onToggled: v => Config.update({
                    weyes: Object.assign({}, Config.weyes, {
                        tinted: v
                    })
                })
            isLast: true
        }
    }

    SectionCard {
        label: "Neko"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Enable"
            sublabel: CompositorService.hasCapability("cursorPosition") ? "A cursor-chasing cat on your desktop" : "Requires Hyprland (cursor position isn't available on " + CompositorService.backendName + ")"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            checked: Config.neko.enabled
            onToggled: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        enabled: v
                    })
                })
        }

        SettingSwitch {
            label: "Sit above windows"
            sublabel: "Render on top of windows instead of on the wallpaper"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            checked: Config.neko.onTop
            onToggled: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        onTop: v
                    })
                })
        }

        SettingSelect {
            label: "Sprite"
            sublabel: "Appearance of the cat"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            options: NekoService.spriteNames.map(name => ({
                label: titleCase(name),
                value: name,
                icon: spritePreviewIcon
            }))
            currentValue: Config.neko.sprite
            onSelected: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        sprite: v
                    })
                })
        }

        SettingSlider {
            label: "Size"
            sublabel: "Rendered size of the sprite"
            from: 32
            to: 160
            stepSize: 4
            unit: "px"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            value: Config.neko.size
            onMoved: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        size: Math.round(v)
                    })
                })
        }

        SettingSlider {
            label: "Speed"
            sublabel: "How fast it chases the cursor"
            from: 4
            to: 30
            stepSize: 1
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            value: Config.neko.speed
            onMoved: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        speed: Math.round(v)
                    })
                })
            isLast: true
        }
    }
}
