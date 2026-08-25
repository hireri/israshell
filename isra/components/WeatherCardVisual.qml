import QtQuick
import Quickshell.Widgets
import qs.style
import qs.services

Item {
    id: root

    property var screen: null

    readonly property var liveSpan: WidgetGrid.spanFromPixels(root.screen, root.width, root.height)

    readonly property bool showHours: root.liveSpan.w >= 5 && root.liveSpan.h >= 3

    readonly property int pad: 14
    readonly property int bottomInset: root.pad

    readonly property int dayRowHeight: 30
    readonly property int availableDayCount: Math.max(0, (LocaleService.weatherDaily ?? []).length - 1)
    readonly property int maxDayRows: Math.min(3, root.availableDayCount)
    readonly property int minMiddleHeight: 76
    readonly property real availableForDays: root.height - root.pad * 2 - header.height - 4 - root.minMiddleHeight - 6
    readonly property int fittingDayRows: Math.max(0, Math.min(root.maxDayRows, Math.floor(root.availableForDays / root.dayRowHeight)))
    readonly property int daysHeight: root.fittingDayRows * root.dayRowHeight
    readonly property bool showDays: root.showHours && root.fittingDayRows >= 1

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 22
        color: Colors.md3.surface_container_high
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.pad
        height: Math.max(headerIcon.height, headerText.implicitHeight)

        WeatherIcon {
            id: headerIcon
            anchors.left: parent.left
            anchors.top: parent.top
            code: WeatherReadout.code
            isDay: WeatherReadout.isDay
            iconSize: root.showHours ? 26 : 34
        }

        Column {
            id: headerText
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            Text {
                anchors.right: parent.right
                text: WeatherReadout.location
                font.family: Config.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Colors.md3.primary
            }

            Text {
                anchors.right: parent.right
                visible: root.showHours
                text: WeatherReadout.desc
                font.family: Config.fontFamily
                font.pixelSize: 18
                font.weight: Font.Medium
                color: Colors.md3.primary
            }
        }
    }

    WeatherDayRows {
        id: dayRows
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.bottomMargin: root.bottomInset
        height: root.showDays ? root.daysHeight : 0
        visible: root.showDays
        rowHeight: root.dayRowHeight

        opacity: root.showDays ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
    }

    Item {
        id: middle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: dayRows.top
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.topMargin: 4
        anchors.bottomMargin: 6

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: WeatherReadout.temp
                font.family: Config.fontFamily
                font.pixelSize: 44
                font.weight: Font.DemiBold
                color: Colors.md3.primary
            }

            Row {
                spacing: 8

                Text {
                    text: WeatherReadout.high
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Colors.md3.primary
                }

                Text {
                    text: WeatherReadout.low
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                }
            }
        }

        WeatherHourStrip {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.62
            height: parent.height
            visible: root.showHours
            slotWidth: 44

            opacity: root.showHours ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
        }
    }
}
