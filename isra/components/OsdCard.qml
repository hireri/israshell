import QtQuick
import QtQuick.Layouts

import qs.style

Rectangle {
    id: card

    property int effectivePosition: 1
    property bool vertical: false
    property string valueText: ""
    property bool dimmed: false
    property bool errorActive: false
    property real fillFraction: 0
    property real errorFraction: 0
    property int fontSize: 24
    property Component icon

    radius: vertical ? width / 2 : height / 2
    color: Colors.md3.surface_container
    border.width: 1
    border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)
    clip: true

    property real slideOffset: {
        switch (card.effectivePosition) {
        case 1:
            return -(height + 24);
        case 2:
            return width + 24;
        case 3:
            return height + 24;
        case 4:
            return -(width + 24);
        }
        return 0;
    }

    transform: Translate {
        x: (card.effectivePosition === 2 || card.effectivePosition === 4) ? card.slideOffset : 0
        y: (card.effectivePosition === 1 || card.effectivePosition === 3) ? card.slideOffset : 0
    }

    Component.onCompleted: slideAnim.start()

    NumberAnimation {
        id: slideAnim
        target: card
        property: "slideOffset"
        to: 0
        duration: 220
        easing.type: Easing.OutExpo
    }

    ColumnLayout {
        visible: card.vertical
        anchors {
            fill: parent
            topMargin: 16
            bottomMargin: 10
        }
        spacing: 12

        Item {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignHCenter

            Text {
                anchors.centerIn: parent
                text: card.valueText
                font.family: Config.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: card.dimmed ? Colors.md3.on_surface_variant : (card.errorActive ? Colors.md3.error : Colors.md3.on_surface)
            }
        }

        OsdTrackBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.preferredWidth: 8

            vertical: true
            fillFraction: card.fillFraction
            errorFraction: card.errorFraction
            fillColor: card.dimmed ? Colors.md3.outline : Colors.md3.primary
            trackColor: Colors.md3.surface_variant
            errorColor: Colors.md3.error
        }

        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignHCenter

            Loader {
                anchors.centerIn: parent
                sourceComponent: card.icon
            }
        }
    }

    RowLayout {
        visible: !card.vertical
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 10
        }
        spacing: 12

        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter

            Loader {
                anchors.centerIn: parent
                sourceComponent: card.icon
            }
        }

        OsdTrackBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            Layout.alignment: Qt.AlignVCenter

            vertical: false
            fillFraction: card.fillFraction
            errorFraction: card.errorFraction
            fillColor: card.dimmed ? Colors.md3.outline : Colors.md3.primary
            trackColor: Colors.md3.surface_variant
            errorColor: Colors.md3.error
        }

        Item {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: card.valueText
                font.family: Config.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: card.dimmed ? Colors.md3.on_surface_variant : (card.errorActive ? Colors.md3.error : Colors.md3.on_surface)
            }
        }
    }

    component OsdTrackBar: Item {
        id: bar

        property bool vertical: false
        property real fillFraction: 0
        property real errorFraction: 0

        property color fillColor: Colors.md3.primary
        property color trackColor: Colors.md3.surface_variant
        property color errorColor: Colors.md3.error

        property real gap: 4

        readonly property real thickness: vertical ? width : height
        readonly property real total: vertical ? height : width

        readonly property real errorLen: errorFraction * total
        readonly property real errorGap: errorLen > 0.5 ? gap : 0
        readonly property real fillLen: Math.max(fillFraction * total - errorLen, 0)
        readonly property real fillGap: fillLen > 0.5 ? gap : 0
        readonly property real trackLen: Math.max(total - errorLen - errorGap - fillLen - fillGap, 0)

        Rectangle {
            visible: bar.errorLen > 0.5
            color: bar.errorColor
            radius: bar.thickness / 2

            x: 0
            y: bar.vertical ? bar.total - bar.errorLen : 0
            width: bar.vertical ? bar.thickness : bar.errorLen
            height: bar.vertical ? bar.errorLen : bar.thickness
        }

        Rectangle {
            visible: bar.fillLen > 0.5
            color: bar.fillColor
            radius: bar.thickness / 2

            x: bar.vertical ? 0 : bar.errorLen + bar.errorGap
            y: bar.vertical ? bar.total - bar.errorLen - bar.errorGap - bar.fillLen : 0
            width: bar.vertical ? bar.thickness : bar.fillLen
            height: bar.vertical ? bar.fillLen : bar.thickness
        }

        Rectangle {
            visible: bar.trackLen > 0.5
            color: bar.trackColor
            radius: bar.thickness / 2

            x: bar.vertical ? 0 : bar.errorLen + bar.errorGap + bar.fillLen + bar.fillGap
            y: 0
            width: bar.vertical ? bar.thickness : bar.trackLen
            height: bar.vertical ? bar.trackLen : bar.thickness
        }
    }
}
