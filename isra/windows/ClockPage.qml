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
    title: "Desktop Clock"
    subtitle: "Layout, style and sizing"

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
        AlignAutoIcon {
            iconSize: 16
            filled: Config.clock.align === "auto"
        }
    }
    Component {
        id: alignLeftComp
        AlignLeftIcon {
            iconSize: 16
            filled: Config.clock.align === "left"
        }
    }
    Component {
        id: alignCenterComp
        AlignCenterIcon {
            iconSize: 16
            filled: Config.clock.align === "center"
        }
    }
    Component {
        id: alignRightComp
        AlignRightIcon {
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

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layoutInner.implicitHeight + 32
        radius: 20
        color: Colors.md3.surface_container

        ColumnLayout {
            id: layoutInner
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 16
            }
            spacing: 16

            Text {
                text: "Layout Style"
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Colors.md3.outline
            }

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
                        : (verticalMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)

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

                        VerticalClockIcon {
                            iconSize: 14
                            filled: btnVertical.active
                            color: btnVertical.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Vertical"
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
                        : (horizontalMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)

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

                        HorizontalClockIcon {
                            iconSize: 14
                            filled: btnHorizontal.active
                            color: btnHorizontal.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Horizontal"
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
                        : (wordMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)

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

                        WordClockIcon {
                            iconSize: 14
                            filled: btnWord.active
                            color: btnWord.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Word"
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
                        : (analogMouse.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high)

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

                        AnalogClockIcon {
                            iconSize: 14
                            filled: btnAnalog.active
                            color: btnAnalog.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Analog"
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
                color: Colors.md3.surface_container_high
                radius: 12

                AnimatedImage {
                    id: wallView
                    source: WallpaperService.currentWall !== "" ? "file://" + WallpaperService.currentWallPreview : ""
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    anchors.fill: parent
                    visible: source !== ""
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
                        text: Config.clock.layout === "analog" ? "Seconds hand color" : "Accent color"
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
            label: "Show date"
            sublabel: "Include date information below the time"
            checked: Config.clock.showDate ?? false
            onToggled: v => updateClock({ showDate: v })
        }

        SettingSwitch {
            label: Config.clock.layout === "analog" ? "Show seconds hand" : "Show seconds"
            sublabel: Config.clock.layout === "analog" ? "Adds a sweeping seconds hand to the face" : "Displays ticking seconds"
            checked: Config.clock.showSeconds ?? false
            onToggled: v => updateClock({ showSeconds: v })
        }

        SettingSwitch {
            label: "Show digital clock"
            sublabel: "Render digital time inside the analog clock face"
            enabled: Config.clock.layout === "analog"
            opacity: enabled ? 1.0 : 0.4
            checked: Config.clock.showDigitalInside ?? false
            onToggled: v => updateClock({ showDigitalInside: v })
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        SettingSlider{
            label: "Outline width"
            sublabel: "Colored outline around the clock face"
            isLast: true
            enabled: Config.clock.layout === "analog"
            from: 0
            to: 10
            stepSize: 1
            value: Config.clock.outlineWidth
            onMoved: v => updateClock({ outlineWidth: v })
            opacity: enabled ? 1.0 : 0.4
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    SectionCard {
        Layout.fillWidth: true
        SettingSwitch {
            label: "Manual positioning"
            sublabel: "Drag the clock freely instead of auto-placing it"
            isLast: true
            checked: Config.clock.manualPos ?? false
            onToggled: v => updateClock({ manualPos: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true

        SettingChips {
            label: "Content alignment"
            sublabel: "Flow layout of the time and date elements"
            options: [
                { value: "auto",   label: "Auto",   icon: alignAutoComp },
                { value: "left",   label: "Left",   icon: alignLeftComp },
                { value: "center", label: "Center", icon: alignCenterComp },
                { value: "right",  label: "Right",  icon: alignRightComp }
            ]
            currentValue: Config.clock.align ?? "auto"
            onSelected: (val) => updateClock({ align: val })
        }

        SettingInput {
            label: "Font family"
            sublabel: "Leave empty to use the shell font"
            value: Config.clock.fontFamily
            placeholder: "e.g. Google Sans Flex"
            fieldWidth: 180
            onCommitted: v => updateClock({ fontFamily: v })
        }
        SettingSlider {
            label: "Weight"
            from: 100
            to: 900
            stepSize: 10
            value: Config.clock.hourWeight
            onMoved: v => updateClock({ hourWeight: v })
        }
        SettingSlider {
            label: "Sub weight"
            sublabel: "Minutes, seconds, date"
            from: 100
            to: 900
            stepSize: 10
            value: Config.clock.minuteWeight
            onMoved: v => updateClock({ minuteWeight: v })
        }
        SettingSlider {
            label: "Width"
            sublabel: "Condensed ← normal → expanded"
            from: 25
            to: 150
            stepSize: 1
            value: Config.clock.fontWidth ?? 100
            onMoved: v => updateClock({ fontWidth: v })
        }
        SettingSlider {
            label: "Roundness"
            sublabel: "Corner radius of letterforms (ROND axis)"
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
            label: "Hour size"
            from: 40
            to: 200
            stepSize: 1
            value: Config.clock.hourSize
            onMoved: v => updateClock({ hourSize: v })
        }
        SettingSlider {
            label: "Minute size"
            from: 40
            to: 200
            stepSize: 1
            value: Config.clock.minuteSize
            onMoved: v => updateClock({ minuteSize: v })
        }
        SettingSlider {
            label: "Time spacing"
            from: -100
            to: 40
            stepSize: 1
            value: Config.clock.timeSpacing
            onMoved: v => updateClock({ timeSpacing: v })
        }
        SettingSlider {
            label: "Date spacing"
            visible: Config.clock.showDate
            from: -60
            to: 40
            stepSize: 1
            value: Config.clock.dateSpacing
            onMoved: v => updateClock({ dateSpacing: v })
        }
        SettingSlider {
            label: "Date size"
            visible: Config.clock.showDate
            isLast: true
            from: 10
            to: 60
            stepSize: 1
            value: Config.clock.dateSize
            onMoved: v => updateClock({ dateSize: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true
        visible: Config.clock.layout === "word"

        SettingSlider {
            label: "Word size"
            from: 20
            to: 120
            stepSize: 1
            value: Config.clock.hourSize
            onMoved: v => updateClock({ hourSize: v })
        }
        SettingSlider {
            label: "Line spacing"
            from: -40
            to: 40
            stepSize: 1
            value: Config.clock.wordSpacing ?? -6
            onMoved: v => updateClock({ wordSpacing: v })
        }
        SettingSlider {
            label: "Date spacing"
            visible: Config.clock.showDate
            from: -60
            to: 40
            stepSize: 1
            value: Config.clock.dateSpacing
            onMoved: v => updateClock({ dateSpacing: v })
        }
        SettingSlider {
            label: "Date size"
            visible: Config.clock.showDate
            isLast: true
            from: 10
            to: 60
            stepSize: 1
            value: Config.clock.dateSize
            onMoved: v => updateClock({ dateSize: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true
        visible: Config.clock.layout === "analog"

        SettingSlider {
            label: "Clock size"
            from: 80
            to: 500
            stepSize: 4
            value: Config.clock.analogSize ?? 200
            onMoved: v => updateClock({ analogSize: v })
        }
        SettingSlider {
            label: "Face wobble"
            sublabel: "Number of lobes on the clock face edge"
            from: 2
            to: 20
            stepSize: 1
            value: Config.clock.ringSides ?? 8
            onMoved: v => updateClock({ ringSides: v })
        }
        SettingSlider {
            label: "Wobble depth"
            sublabel: "How far the edge undulates in and out"
            from: 0
            to: 30
            stepSize: 1
            value: Config.clock.ringAmplitude ?? 6
            onMoved: v => updateClock({ ringAmplitude: v })
        }
        SettingSlider {
            label: "Date spacing"
            visible: Config.clock.showDate
            from: -60
            to: 40
            stepSize: 1
            value: Config.clock.dateSpacing
            onMoved: v => updateClock({ dateSpacing: v })
        }
        SettingSlider {
            label: "Date size"
            visible: Config.clock.showDate
            isLast: true
            from: 10
            to: 60
            stepSize: 1
            value: Config.clock.dateSize
            onMoved: v => updateClock({ dateSize: v })
        }
    }

    SectionCard {
        Layout.fillWidth: true

        SettingSlider {
            label: "Shadow blur"
            from: 0
            to: 64
            stepSize: 1
            value: Config.clock.shadowBlur
            onMoved: v => updateClock({ shadowBlur: v })
        }
        SettingSlider {
            label: "Shadow X"
            from: -40
            to: 40
            stepSize: 1
            value: Config.clock.shadowX ?? 0
            onMoved: v => updateClock({ shadowX: v })
        }
        SettingSlider {
            label: "Shadow Y"
            from: -40
            to: 40
            stepSize: 1
            value: Config.clock.shadowY ?? 0
            onMoved: v => updateClock({ shadowY: v })
        }
        SettingSlider {
            label: "Shadow opacity"
            isLast: true
            from: 0
            to: 100
            stepSize: 1
            value: Math.round((Config.clock.shadowOpacity ?? 0.2) * 100)
            onMoved: v => updateClock({ shadowOpacity: v / 100 })
        }
    }
}