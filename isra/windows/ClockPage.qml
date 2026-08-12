pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services
import qs.components
import qs.windows.components
import qs.icons

PageBase {
    id: pageRoot
    title: Localization.t("settingsWindow.desktop_clock")
    subtitle: Localization.t("clockPage.layout_style_and_sizing")

    readonly property var systemFontsModel: {
        var families = Qt.fontFamilies();
        var uniqueFamilies = families.filter(function(item, pos, self) {
            return self.indexOf(item) === pos;
        });
        uniqueFamilies.sort(function(a, b) {
            return a.localeCompare(b);
        });
        return uniqueFamilies.map(function(family) {
            return {
                label: family,
                value: family
            };
        });
    }
    
    property var previewTime: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: pageRoot.previewTime = new Date()
    }

    function updateClock(changes) {
        Config.update({
            clock: Object.assign({}, Config.clock, changes)
        });
    }

    Component {
        id: alignAutoComp
        MaterialIcon {
            name: "align-auto"
            iconSize: 16
            filled: Config.clock.align === "auto"
        }
    }
    Component {
        id: alignLeftComp
        MaterialIcon {
            name: "align-left"
            iconSize: 16
            filled: Config.clock.align === "left"
        }
    }
    Component {
        id: alignCenterComp
        MaterialIcon {
            name: "align-center"
            iconSize: 16
            filled: Config.clock.align === "center"
        }
    }
    Component {
        id: alignRightComp
        MaterialIcon {
            name: "align-right"
            iconSize: 16
            filled: Config.clock.align === "right"
        }
    }

    Component {
        id: verticalPreviewComp
        ClockVertical {
            scale: 0.5
            transformOrigin: Item.Center
            currentTime: pageRoot.previewTime
            clockFont: Config.clock.fontFamily || Config.fontFamily
            textColor: Colors.md3[Config.clock.colorRole] ?? Colors.md3.on_surface
            subColor: Colors.md3[Config.clock.subColorRole] ?? Colors.md3.on_surface_variant
            halign: Text.AlignHCenter
            showSeconds: Config.clock.showSeconds ?? false
            is12h: Config.hourFormat !== 0
        }
    }
    Component {
        id: horizontalPreviewComp
        ClockHorizontal {
            scale: 0.5
            transformOrigin: Item.Center
            currentTime: pageRoot.previewTime
            clockFont: Config.clock.fontFamily || Config.fontFamily
            textColor: Colors.md3[Config.clock.colorRole] ?? Colors.md3.on_surface
            subColor: Colors.md3[Config.clock.subColorRole] ?? Colors.md3.on_surface_variant
            halign: Text.AlignHCenter
            showSeconds: Config.clock.showSeconds ?? false
            is12h: Config.hourFormat !== 0
        }
    }
    Component {
        id: wordPreviewComp
        ClockWord {
            scale: 0.4
            transformOrigin: Item.Center
            currentTime: pageRoot.previewTime
            clockFont: Config.clock.fontFamily || Config.fontFamily
            textColor: Colors.md3[Config.clock.colorRole] ?? Colors.md3.on_surface
            subColor: Colors.md3[Config.clock.subColorRole] ?? Colors.md3.on_surface_variant
            halign: Text.AlignHCenter
            showSeconds: Config.clock.showSeconds ?? false
            is12h: Config.hourFormat !== 0
        }
    }
    Component {
        id: analogPreviewComp
        ClockAnalog {
            currentTime: pageRoot.previewTime
            clockFont: Config.clock.fontFamily || Config.fontFamily
            textColor: Colors.md3[Config.clock.colorRole] ?? Colors.md3.on_surface
            subColor: Colors.md3[Config.clock.subColorRole] ?? Colors.md3.on_surface_variant
            halign: Text.AlignHCenter
            showSeconds: Config.clock.showSeconds ?? false
            is12h: Config.hourFormat !== 0
            analogSize: 130
        }
    }

    HeroCard {
        Layout.fillWidth: true
        title: Localization.t("overviewPage.desktop_clock")
        subtitle: {
            if (!Config.desktopClock) return Localization.t("clockPage.hidden");

            var layoutNames = {
                "vertical": Localization.t("clockPage.vertical_style"),
                "horizontal": Localization.t("clockPage.horizontal_style"),
                "word": Localization.t("clockPage.word_clock"),
                "analog": Localization.t("clockPage.analog_face")
            };
            var layout = layoutNames[Config.clock.layout] ?? Localization.t("clockPage.standard");
            return Localization.t("clockPage.visible_layout").arg(layout);
        }
        iconBg: Colors.md3.tertiary_container
        cardColor: Colors.md3.surface_container
        checked: Config.desktopClock ?? false
        onToggled: v => Config.update({ desktopClock: v })
        MaterialIcon { name: "analog-clock"; transitionType: "circle" }
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
                    id: btnVertical
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    topRightRadius: active ? 17 : 8
                    bottomRightRadius: active ? 17 : 8

                    Behavior on topRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.clock.layout === "vertical"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (verticalMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (verticalMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        topRightRadius: parent.topRightRadius
                        bottomRightRadius: parent.bottomRightRadius
                        color: verticalMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnVertical.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "vertical-clock"
                            iconSize: 14
                            filled: btnVertical.active
                            color: btnVertical.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Localization.t("clockPage.vertical")
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnVertical.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: verticalMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: updateClock({ layout: "vertical" })
                    }
                }

                Rectangle {
                    id: btnHorizontal
                    Layout.fillWidth: true
                    height: 34
                    radius: active ? 17 : 8

                    Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.clock.layout === "horizontal"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (horizontalMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (horizontalMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: horizontalMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnHorizontal.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "horizontal-clock"
                            iconSize: 14
                            filled: btnHorizontal.active
                            color: btnHorizontal.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Localization.t("clockPage.horizontal")
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnHorizontal.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: horizontalMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: updateClock({ layout: "horizontal" })
                    }
                }

                Rectangle {
                    id: btnWord
                    Layout.fillWidth: true
                    height: 34
                    radius: active ? 17 : 8

                    Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.clock.layout === "word"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (wordMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (wordMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: wordMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnWord.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "word-clock"
                            iconSize: 14
                            filled: btnWord.active
                            color: btnWord.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Localization.t("clockPage.word")
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnWord.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: wordMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: updateClock({ layout: "word" })
                    }
                }

                Rectangle {
                    id: btnAnalog
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    topLeftRadius: active ? 17 : 8
                    bottomLeftRadius: active ? 17 : 8

                    Behavior on topLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on bottomLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.clock.layout === "analog"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (analogMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (analogMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        topLeftRadius: parent.topLeftRadius
                        bottomLeftRadius: parent.bottomLeftRadius
                        color: analogMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnAnalog.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "analog-clock"
                            iconSize: 14
                            filled: btnAnalog.active
                            color: btnAnalog.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Localization.t("clockPage.analog")
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnAnalog.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: analogMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: updateClock({ layout: "analog" })
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

                Loader {
                    id: previewLoader
                    anchors.centerIn: parent
                    asynchronous: false
                    
                    property var activeComponent: null
                    property var targetComponent: {
                        switch (Config.clock.layout) {
                        case "vertical":   return verticalPreviewComp
                        case "horizontal": return horizontalPreviewComp
                        case "word":       return wordPreviewComp
                        case "analog":     return analogPreviewComp
                        default:           return verticalPreviewComp
                        }
                    }
                    
                    onTargetComponentChanged: transitionSeq.restart()
                    sourceComponent: activeComponent
                    
                    SequentialAnimation {
                        id: transitionSeq
                        ParallelAnimation {
                            NumberAnimation { target: previewLoader; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                            NumberAnimation { target: previewLoader; property: "scale"; to: 0.9; duration: 150; easing.type: Easing.OutCubic }
                        }
                        ScriptAction {
                            script: previewLoader.activeComponent = previewLoader.targetComponent
                        }
                        ParallelAnimation {
                            NumberAnimation { target: previewLoader; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                            NumberAnimation { target: previewLoader; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    Component.onCompleted: {
                        previewLoader.activeComponent = previewLoader.targetComponent
                    }
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
                        text: Localization.t("backgroundPage.main_color")
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.outline
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: ["primary", "secondary", "tertiary", "on_surface"]
                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                readonly property int  lastIndex:  3
                                readonly property bool isFirst:    index === 0
                                readonly property bool isLast:     index === lastIndex
                                readonly property bool isSelected: Config.clock.colorRole === modelData

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
                                    onClicked: updateClock({ colorRole: modelData })
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
                        text: Config.clock.layout === "analog" ? Localization.t("clockPage.seconds_hand_color") : Localization.t("backgroundPage.accent_color")
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.md3.outline
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: ["primary", "secondary", "tertiary", "on_surface"]
                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                readonly property int  lastIndex:  3
                                readonly property bool isFirst:    index === 0
                                readonly property bool isLast:     index === lastIndex
                                readonly property bool isSelected: Config.clock.subColorRole === modelData

                                Layout.fillWidth: true
                                height: 28
                                color: Colors.md3[modelData] ?? Colors.md3.secondary

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
                                    onClicked: updateClock({ subColorRole: modelData })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    SectionCard {
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("clockPage.show_date")
            sublabel: Localization.t("clockPage.include_date_information_below_the")
            checked: Config.clock.showDate ?? false
            onToggled: v => updateClock({ showDate: v })
        }

        SettingSwitch {
            label: Config.clock.layout === "analog" ? Localization.t("clockPage.show_seconds_hand") : Localization.t("clockPage.show_seconds")
            sublabel: Config.clock.layout === "analog" ? Localization.t("clockPage.adds_a_sweeping_seconds_hand") : Localization.t("clockPage.displays_ticking_seconds")
            checked: Config.clock.showSeconds ?? false
            onToggled: v => updateClock({ showSeconds: v })
        }

        SettingSwitch {
            label: Localization.t("clockPage.show_digital_clock")
            sublabel: Localization.t("clockPage.render_digital_time_inside_the")
            enabled: Config.clock.layout === "analog"
            opacity: enabled ? 1.0 : 0.4
            checked: Config.clock.showDigitalInside ?? false
            onToggled: v => updateClock({ showDigitalInside: v })
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        SettingSlider{
            label: Localization.t("clockPage.outline_width")
            sublabel: Localization.t("clockPage.colored_outline_around_the_clock")
            isLast: true
            visible: ClockSizing.fieldsForLayout(Config.clock.layout).includes("outlineWidth")
            from: ClockSizing.boundsFor(Config.clock.layout, "outlineWidth")?.min ?? 0
            to: ClockSizing.boundsFor(Config.clock.layout, "outlineWidth")?.max ?? 10
            stepSize: 1
            value: Config.clock.outlineWidth
            onMoved: v => updateClock({ outlineWidth: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true
        SettingSwitch {
            label: Localization.t("clockPage.manual_positioning")
            sublabel: Localization.t("clockPage.drag_the_clock_freely_instead")
            isLast: true
            checked: Config.clock.manualPos ?? false
            onToggled: v => updateClock({ manualPos: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true

        SettingChips {
            label: Localization.t("clockPage.content_alignment")
            sublabel: Localization.t("clockPage.flow_layout_of_the_time")
            options: [
                { value: "auto",   label: Localization.t("barPage.auto"),   icon: alignAutoComp },
                { value: "left",   label: Localization.t("barPage.left"),   icon: alignLeftComp },
                { value: "center", label: Localization.t("backgroundPage.center"), icon: alignCenterComp },
                { value: "right",  label: Localization.t("barPage.right"),  icon: alignRightComp }
            ]
            currentValue: Config.clock.align ?? "auto"
            onSelected: (val) => updateClock({ align: val })
        }

        SettingSelect {
            label: Localization.t("clockPage.font_family")
            sublabel: Localization.t("clockPage.leave_empty_to_use_the")
            options: pageRoot.systemFontsModel
            currentValue: Config.clock.fontFamily
            onSelected: v => {
                if (v && v.trim().length > 0) {
                    updateClock({
                        fontFamily: v.trim()
                    });
                }
            }
        }
        SettingSlider {
            label: Localization.t("clockPage.weight")
            from: 100
            to: 900
            stepSize: 10
            value: Config.clock.hourWeight
            onMoved: v => updateClock({ hourWeight: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.sub_weight")
            sublabel: Localization.t("clockPage.minutes_seconds_date")
            from: 100
            to: 900
            stepSize: 10
            value: Config.clock.minuteWeight
            onMoved: v => updateClock({ minuteWeight: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.width")
            sublabel: Localization.t("clockPage.condensed_normal_expanded")
            from: 25
            to: 150
            stepSize: 1
            value: Config.clock.fontWidth ?? 100
            onMoved: v => updateClock({ fontWidth: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.roundness")
            sublabel: Localization.t("clockPage.corner_radius_of_letterforms_rond")
            isLast: true
            from: 0
            to: 100
            stepSize: 1
            value: Config.clock.fontRoundness ?? 0
            onMoved: v => updateClock({ fontRoundness: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true
        visible: Config.clock.layout === "vertical" || Config.clock.layout === "horizontal"

        SettingSlider {
            label: Localization.t("clockPage.hour_size")
            from: ClockSizing.boundsFor(Config.clock.layout, "hourSize")?.min ?? 40
            to: ClockSizing.boundsFor(Config.clock.layout, "hourSize")?.max ?? 200
            stepSize: 1
            value: Config.clock.hourSize
            onMoved: v => updateClock({ hourSize: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.minute_size")
            visible: ClockSizing.fieldsForLayout(Config.clock.layout).includes("minuteSize")
            from: ClockSizing.boundsFor(Config.clock.layout, "minuteSize")?.min ?? 40
            to: ClockSizing.boundsFor(Config.clock.layout, "minuteSize")?.max ?? 200
            stepSize: 1
            value: Config.clock.minuteSize
            onMoved: v => updateClock({ minuteSize: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.time_spacing")
            visible: ClockSizing.fieldsForLayout(Config.clock.layout).includes("timeSpacing")
            from: ClockSizing.boundsFor(Config.clock.layout, "timeSpacing")?.min ?? -100
            to: ClockSizing.boundsFor(Config.clock.layout, "timeSpacing")?.max ?? 40
            stepSize: 1
            value: Config.clock.timeSpacing
            onMoved: v => updateClock({ timeSpacing: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.date_spacing")
            visible: Config.clock.showDate
            from: ClockSizing.boundsFor(Config.clock.layout, "dateSpacing")?.min ?? -60
            to: ClockSizing.boundsFor(Config.clock.layout, "dateSpacing")?.max ?? 40
            stepSize: 1
            value: Config.clock.dateSpacing
            onMoved: v => updateClock({ dateSpacing: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.date_size")
            visible: Config.clock.showDate
            isLast: true
            from: ClockSizing.boundsFor(Config.clock.layout, "dateSize")?.min ?? 10
            to: ClockSizing.boundsFor(Config.clock.layout, "dateSize")?.max ?? 60
            stepSize: 1
            value: Config.clock.dateSize
            onMoved: v => updateClock({ dateSize: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true
        visible: Config.clock.layout === "word"

        SettingSlider {
            label: Localization.t("clockPage.word_size")
            from: ClockSizing.boundsFor(Config.clock.layout, "hourSize")?.min ?? 40
            to: ClockSizing.boundsFor(Config.clock.layout, "hourSize")?.max ?? 200
            stepSize: 1
            value: Config.clock.hourSize
            onMoved: v => updateClock({ hourSize: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.line_spacing")
            from: ClockSizing.boundsFor(Config.clock.layout, "wordSpacing")?.min ?? -40
            to: ClockSizing.boundsFor(Config.clock.layout, "wordSpacing")?.max ?? 40
            stepSize: 1
            value: Config.clock.wordSpacing ?? -6
            onMoved: v => updateClock({ wordSpacing: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.date_spacing")
            visible: Config.clock.showDate
            from: ClockSizing.boundsFor(Config.clock.layout, "dateSpacing")?.min ?? -60
            to: ClockSizing.boundsFor(Config.clock.layout, "dateSpacing")?.max ?? 40
            stepSize: 1
            value: Config.clock.dateSpacing
            onMoved: v => updateClock({ dateSpacing: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.date_size")
            visible: Config.clock.showDate
            isLast: true
            from: ClockSizing.boundsFor(Config.clock.layout, "dateSize")?.min ?? 10
            to: ClockSizing.boundsFor(Config.clock.layout, "dateSize")?.max ?? 60
            stepSize: 1
            value: Config.clock.dateSize
            onMoved: v => updateClock({ dateSize: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true
        visible: Config.clock.layout === "analog"

        SettingSlider {
            label: Localization.t("clockPage.clock_size")
            from: ClockSizing.boundsFor(Config.clock.layout, "analogSize")?.min ?? 80
            to: ClockSizing.boundsFor(Config.clock.layout, "analogSize")?.max ?? 500
            stepSize: 4
            value: Config.clock.analogSize ?? 200
            onMoved: v => updateClock({ analogSize: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.face_wobble")
            sublabel: Localization.t("clockPage.number_of_lobes_on_the")
            from: 2
            to: 20
            stepSize: 1
            value: Config.clock.ringSides ?? 8
            onMoved: v => updateClock({ ringSides: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.wobble_depth")
            sublabel: Localization.t("clockPage.how_far_the_edge_undulates")
            from: 0
            to: 30
            stepSize: 1
            value: Config.clock.ringAmplitude ?? 6
            onMoved: v => updateClock({ ringAmplitude: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.date_spacing")
            visible: Config.clock.showDate && ClockSizing.fieldsForLayout(Config.clock.layout).includes("dateSpacing")
            from: -60
            to: 40
            stepSize: 1
            value: Config.clock.dateSpacing
            onMoved: v => updateClock({ dateSpacing: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.date_size")
            visible: Config.clock.showDate
            isLast: true
            from: ClockSizing.boundsFor(Config.clock.layout, "dateSize")?.min ?? 10
            to: ClockSizing.boundsFor(Config.clock.layout, "dateSize")?.max ?? 60
            stepSize: 1
            value: Config.clock.dateSize
            onMoved: v => updateClock({ dateSize: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true

        SettingSlider {
            label: Localization.t("clockPage.shadow_blur")
            from: 0
            to: 64
            stepSize: 1
            value: Config.clock.shadowBlur
            onMoved: v => updateClock({ shadowBlur: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.shadow_x")
            from: -40
            to: 40
            stepSize: 1
            value: Config.clock.shadowX ?? 0
            onMoved: v => updateClock({ shadowX: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.shadow_y")
            from: -40
            to: 40
            stepSize: 1
            value: Config.clock.shadowY ?? 0
            onMoved: v => updateClock({ shadowY: v })
        }
        SettingSlider {
            label: Localization.t("clockPage.shadow_opacity")
            isLast: true
            from: 0
            to: 100
            stepSize: 1
            value: Math.round((Config.clock.shadowOpacity ?? 0.2) * 100)
            onMoved: v => updateClock({ shadowOpacity: v / 100 })
        }
    }
}