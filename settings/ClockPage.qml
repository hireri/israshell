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
                        {
                            key: "vertical",
                            label: "Vertical"
                        },
                        {
                            key: "horizontal",
                            label: "Horizontal"
                        },
                        {
                            key: "word",
                            label: "Word"
                        },
                        {
                            key: "analog",
                            label: "Analog"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 72
                        radius: 14
                        color: Config.clock.layout === modelData.key ? Colors.md3.primary_container : Colors.md3.surface_container_high
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Loader {
                                Layout.alignment: Qt.AlignHCenter
                                sourceComponent: {
                                    switch (modelData.key) {
                                    case "vertical":
                                        return verticalClockComp;
                                    case "horizontal":
                                        return horizontalClockComp;
                                    case "word":
                                        return wordClockComp;
                                    case "analog":
                                        return analogClockComp;
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
                            onClicked: updateClock({
                                layout: modelData.key
                            })
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            height: 80
            radius: 16
            color: Colors.md3.surface_container
            visible: Config.clock.layout !== "analog"

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 14
                }
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
                            {
                                key: "left",
                                label: "Left"
                            },
                            {
                                key: "center",
                                label: "Center"
                            },
                            {
                                key: "right",
                                label: "Right"
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 28
                            radius: 10
                            color: Config.clock.align === modelData.key ? Colors.md3.secondary_container : Colors.md3.surface_container_high
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            Loader {
                                anchors.centerIn: parent
                                sourceComponent: {
                                    switch (modelData.key) {
                                    case "left":
                                        return alignLeftComp;
                                    case "center":
                                        return alignCenterComp;
                                    case "right":
                                        return alignRightComp;
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: updateClock({
                                    align: modelData.key
                                })
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
            color: Config.clock.showSeconds ? Colors.md3.tertiary_container : Colors.md3.surface_container
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            visible: Config.clock.layout !== "analog"

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
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
                onClicked: updateClock({
                    showSeconds: !Config.clock.showSeconds
                })
            }
        }

        Rectangle {
            Layout.preferredWidth: 90
            height: 80
            radius: 16
            color: Config.clock.showDate ? Colors.md3.tertiary_container : Colors.md3.surface_container
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            visible: Config.clock.layout !== "analog"

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
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
                onClicked: updateClock({
                    showDate: !Config.clock.showDate
                })
            }
        }
    }

    SectionCard {
        Layout.fillWidth: true
        visible: Config.clock.layout === "analog"

        SettingSwitch {
            label: "Show seconds"
            sublabel: "Second hand on analog clock"
            checked: Config.clock.showSeconds
            onToggled: v => updateClock({
                    showSeconds: v
                })
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
                            Layout.fillWidth: true
                            height: 32
                            radius: Config.clock.colorRole === modelData ? 20 : 6
                            color: Colors.md3[modelData] ?? Colors.md3.primary
                            Behavior on radius {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: updateClock({
                                    colorRole: modelData
                                })
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
                spacing: 6

                Text {
                    text: Config.clock.layout === "analog" ? "Seconds color" : "Date color"
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
                            Layout.fillWidth: true
                            height: 32
                            radius: Config.clock.subColorRole === modelData ? 20 : 6
                            color: Colors.md3[modelData] ?? Colors.md3.secondary
                            Behavior on radius {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: updateClock({
                                    subColorRole: modelData
                                })
                            }
                        }
                    }
                }
            }
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
            onMoved: v => updateClock({
                    hourSize: v
                })
        }
        SettingSlider {
            label: "Minute size"
            from: 40
            to: 200
            stepSize: 1
            value: Config.clock.minuteSize
            onMoved: v => updateClock({
                    minuteSize: v
                })
        }
        SettingSlider {
            label: "Time spacing"
            from: -100
            to: 40
            stepSize: 1
            value: Config.clock.timeSpacing
            onMoved: v => updateClock({
                    timeSpacing: v
                })
        }
        SettingSlider {
            label: "Date spacing"
            visible: Config.clock.showDate
            from: -60
            to: 40
            stepSize: 1
            value: Config.clock.dateSpacing
            onMoved: v => updateClock({
                    dateSpacing: v
                })
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
            onMoved: v => updateClock({
                    shadowBlur: v
                })
        }
    }
}
