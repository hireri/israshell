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
    title: "Desktop Clock"
    subtitle: "Layout, style and sizing"

    function updateClock(changes) {
        Config.update({
            clock: Object.assign({}, Config.clock, changes)
        });
    }

    Component {
        id: verticalClockComp
        VerticalClockIcon {
            iconSize: 28
            filled: Config.clock.layout === "vertical"
            color: Config.clock.layout === "vertical" ? Colors.md3.on_primary_container : Colors.md3.outline_variant
        }
    }
    Component {
        id: horizontalClockComp
        HorizontalClockIcon {
            iconSize: 28
            filled: Config.clock.layout === "horizontal"
            color: Config.clock.layout === "horizontal" ? Colors.md3.on_primary_container : Colors.md3.outline_variant
        }
    }
    Component {
        id: wordClockComp
        WordClockIcon {
            iconSize: 28
            filled: Config.clock.layout === "word"
            color: Config.clock.layout === "word" ? Colors.md3.on_primary_container : Colors.md3.outline_variant
        }
    }
    Component {
        id: analogClockComp
        AnalogClockIcon {
            iconSize: 28
            filled: Config.clock.layout === "analog"
            color: Config.clock.layout === "analog" ? Colors.md3.on_primary_container : Colors.md3.outline_variant
        }
    }

    Component {
        id: alignAutoComp
        AlignAutoIcon {
            iconSize: 18
            filled: Config.clock.align === "auto"
            color: Config.clock.align === "auto" ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
        }
    }

    Component {
        id: alignLeftComp
        AlignLeftIcon {
            iconSize: 18
            filled: Config.clock.align === "left"
            color: Config.clock.align === "left" ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
        }
    }
    Component {
        id: alignCenterComp
        AlignCenterIcon {
            iconSize: 18
            filled: Config.clock.align === "center"
            color: Config.clock.align === "center" ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
        }
    }
    Component {
        id: alignRightComp
        AlignRightIcon {
            iconSize: 18
            filled: Config.clock.align === "right"
            color: Config.clock.align === "right" ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layoutInner.implicitHeight + 28
        radius: 16
        color: Colors.md3.surface_container

        ColumnLayout {
            id: layoutInner
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 16
            }
            spacing: 10

            Text {
                text: "Layout"
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Colors.md3.outline
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { key: "vertical",   label: "Vertical"   },
                        { key: "horizontal", label: "Horizontal" },
                        { key: "word",       label: "Word"       },
                        { key: "analog",     label: "Analog"     }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 72
                        radius: 14
                        color: Config.clock.layout === modelData.key ? Colors.md3.primary_container : Colors.md3.surface_container_high
                        Behavior on color { ColorAnimation { duration: 120 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Loader {
                                Layout.alignment: Qt.AlignHCenter
                                sourceComponent: {
                                    switch (modelData.key) {
                                    case "vertical":   return verticalClockComp
                                    case "horizontal": return horizontalClockComp
                                    case "word":       return wordClockComp
                                    case "analog":     return analogClockComp
                                    }
                                }
                            }

                            Text {
                                text: modelData.label
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Config.clock.layout === modelData.key ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: updateClock({ layout: modelData.key })
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        visible: Config.clock.layout !== "analog"

        Rectangle {
            Layout.fillWidth: true
            height: 80
            radius: 16
            color: Colors.md3.surface_container

            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                spacing: 8

                Text {
                    text: "Alignment"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Colors.md3.outline
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { key: "auto",   label: "Auto"   },
                            { key: "left",   label: "Left"   },
                            { key: "center", label: "Center" },
                            { key: "right",  label: "Right"  }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 28
                            radius: 10
                            color: Config.clock.align === modelData.key ? Colors.md3.secondary_container : Colors.md3.surface_container_high
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Loader {
                                anchors.centerIn: parent
                                sourceComponent: {
                                    switch (modelData.key) {
                                    case "auto":   return alignAutoComp
                                    case "left":   return alignLeftComp
                                    case "center": return alignCenterComp
                                    case "right":  return alignRightComp
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: updateClock({ align: modelData.key })
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 90
            height: 80
            radius: 16
            visible: Config.clock.layout !== "word"
            color: Config.clock.showSeconds ? Colors.md3.tertiary_container : Colors.md3.surface_container
            Behavior on color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 4

                Text {
                    text: "Seconds"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Config.clock.showSeconds ? Colors.md3.on_tertiary_container : Colors.md3.outline
                }
                Text {
                    text: Config.clock.showSeconds ? "22:03:42" : "22:03"
                    font.family: Config.fontMonospace
                    font.pixelSize: 12
                    color: Config.clock.showSeconds ? Colors.md3.on_tertiary_container : Colors.md3.on_surface_variant
                    opacity: 0.8
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: updateClock({ showSeconds: !Config.clock.showSeconds })
            }
        }

        Rectangle {
            Layout.preferredWidth: 90
            height: 80
            radius: 16
            color: Config.clock.showDate ? Colors.md3.tertiary_container : Colors.md3.surface_container
            Behavior on color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 4

                Text {
                    text: "Date"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Config.clock.showDate ? Colors.md3.on_tertiary_container : Colors.md3.outline
                }
                Text {
                    text: Qt.formatDate(new Date(), "ddd d")
                    font.family: Config.fontMonospace
                    font.pixelSize: 12
                    color: Config.clock.showDate ? Colors.md3.on_tertiary_container : Colors.md3.on_surface_variant
                    opacity: 0.8
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: updateClock({ showDate: !Config.clock.showDate })
            }
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
        visible: Config.clock.layout === "analog"

        SettingSwitch {
            label: "Show seconds hand"
            sublabel: "Adds a sweeping seconds hand"
            checked: Config.clock.showSeconds
            onToggled: v => updateClock({ showSeconds: v })
        }
        SettingSwitch {
            isLast: true
            label: "Show date"
            sublabel: "Date label below the clock face"
            checked: Config.clock.showDate
            onToggled: v => updateClock({ showDate: v })
        }
        SettingSwitch {
            isLast: true
            label: "Show digital clock"
            sublabel: "Digital clock inside the clock face"
            checked: Config.clock.showDigitalInside
            onToggled: v => updateClock({ showDigitalInside: v })
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: colorsInner.implicitHeight + 24
        radius: 16
        color: Colors.md3.surface_container

        RowLayout {
            id: colorsInner
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 16
            }
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: 6

                Text {
                    text: "Time color"
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
                            height: 32
                            color: Colors.md3[modelData] ?? Colors.md3.primary

                            topLeftRadius:     isFirst    ? 20 : (isSelected ? 20 : 6)
                            topRightRadius:    isLast     ? 20 : (isSelected ? 20 : 6)
                            bottomLeftRadius:  isFirst    ? 20 : (isSelected ? 20 : 6)
                            bottomRightRadius: isLast     ? 20 : (isSelected ? 20 : 6)

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

            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: Colors.md3.outline_variant
                opacity: 0.4
                Layout.leftMargin: 16
                Layout.rightMargin: 16
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: 6

                Text {
                    text: Config.clock.layout === "analog" ? "Seconds color" : "Date / minute color"
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
                            height: 32
                            color: Colors.md3[modelData] ?? Colors.md3.secondary

                            topLeftRadius:     isFirst    ? 20 : (isSelected ? 20 : 6)
                            topRightRadius:    isLast     ? 20 : (isSelected ? 20 : 6)
                            bottomLeftRadius:  isFirst    ? 20 : (isSelected ? 20 : 6)
                            bottomRightRadius: isLast     ? 20 : (isSelected ? 20 : 6)

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

    SectionCard {
        Layout.fillWidth: true

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
