import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import qs.style
import qs.services

Variants {
    id: root

    default property list<LogoutButton> buttons
    model: Quickshell.screens

    PanelWindow {
        id: w

        required property var modelData
        screen: modelData

        visible: false

        WlrLayershell.namespace: "quickshell:powerMenu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: PowerMenuState.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        onVisibleChanged: {
            if (visible && !PowerMenuState.visible) {
                scrim.opacity = 0;
                visible = false;
            }
        }

        property string userHost: Quickshell.env("USER")
        property string uptimeStr: ""
        property var hoveredButton: null

        function keyName(key) {
            if (key >= Qt.Key_A && key <= Qt.Key_Z)
                return String.fromCharCode(key).toUpperCase();
            return "?";
        }

        Process {
            id: infoProc
            command: ["sh", "-c", "hostname; uptime -p"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = text.trim().split("\n");
                    if (lines.length >= 1)
                        w.userHost = Quickshell.env("USER") + "@" + lines[0].trim();
                    if (lines.length >= 2)
                        w.uptimeStr = lines[1].trim().replace("up ", "").replace(/ hours?/, "h").replace(/ minutes?/, "m");
                }
            }
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        function openMenu() {
            infoProc.running = true;
            visible = true;
            exitAnim.stop();
            enterAnim.start();
        }

        function closeMenu() {
            enterAnim.stop();
            exitAnim.start();
        }

        NumberAnimation {
            id: enterAnim
            target: scrim
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 280
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            id: exitAnim
            NumberAnimation {
                target: scrim
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 200
                easing.type: Easing.InCubic
            }
            ScriptAction {
                script: w.visible = false
            }
        }

        Connections {
            target: PowerMenuState

            function onVisibleChanged() {
                if (PowerMenuState.visible)
                    w.openMenu();
                else
                    w.closeMenu();
            }
        }

        contentItem {
            focus: PowerMenuState.visible
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    PowerMenuState.hide();
                } else {
                    for (let i = 0; i < buttons.length; i++)
                        if (event.key === buttons[i].keybind)
                            buttons[i].exec();
                }
            }
        }

        Rectangle {
            id: scrim
            anchors.fill: parent
            opacity: 0
            color: Qt.alpha(Colors.md3.scrim, 0.75)

            MouseArea {
                anchors.fill: parent
                onClicked: PowerMenuState.hide()
            }

            GridLayout {
                id: buttonGrid
                anchors.centerIn: parent
                columns: 3
                columnSpacing: 38
                rowSpacing: 38

                Repeater {
                    model: buttons
                    delegate: Rectangle {
                        id: circle
                        required property LogoutButton modelData

                        width: 136
                        height: 136
                        radius: 68
                        color: modelData.containerColor

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.alpha(modelData.contentColor, ma.containsMouse ? 0.1 : 0.0)
                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: 48
                            font.family: Config.fontFamily
                            color: modelData.contentColor
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: w.hoveredButton = circle.modelData
                            onExited: {
                                if (w.hoveredButton === circle.modelData) {
                                    w.hoveredButton = null;
                                    tooltipHideTimer.restart();
                                }
                            }
                            onClicked: circle.modelData.exec()
                        }
                    }
                }
            }

            Rectangle {
                id: tooltip

                anchors.top: buttonGrid.bottom
                anchors.topMargin: 24
                anchors.horizontalCenter: buttonGrid.horizontalCenter

                property string label: ""
                property string displayLabel: ""
                property bool shown: false

                height: 36
                radius: 18
                color: Colors.md3.surface_container_high

                opacity: shown ? 1.0 : 0.0
                scale: shown ? 1.0 : 0.82
                transformOrigin: Item.Top

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutBack
                    }
                }

                Text {
                    id: tooltipMeasure
                    text: tooltip.label
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                    visible: false
                }

                width: shown ? tooltipMeasure.implicitWidth + 40 : 0
                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: tooltipLabelOld
                    anchors.centerIn: parent
                    text: tooltip.displayLabel
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                    color: Colors.md3.on_surface_variant
                    renderType: Text.NativeRendering
                    opacity: 0.0
                }

                Text {
                    id: tooltipLabelNew
                    anchors.centerIn: parent
                    text: tooltip.label
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: Config.fontFamily
                    color: Colors.md3.on_surface_variant
                    renderType: Text.NativeRendering
                    opacity: 1.0
                }

                onLabelChanged: {
                    tooltipLabelOld.text = tooltip.displayLabel;
                    tooltipLabelOld.opacity = 1.0;
                    tooltipLabelNew.opacity = 0.0;
                    crossfadeAnim.restart();
                    tooltip.displayLabel = tooltip.label;
                }

                ParallelAnimation {
                    id: crossfadeAnim
                    NumberAnimation {
                        target: tooltipLabelOld
                        property: "opacity"
                        to: 0.0
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: tooltipLabelNew
                        property: "opacity"
                        to: 1.0
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    id: tooltipHideTimer
                    interval: 2000
                    repeat: false
                    onTriggered: {
                        tooltip.shown = false;
                        tooltipClearTimer.restart();
                    }
                }

                Timer {
                    id: tooltipClearTimer
                    interval: 200
                    repeat: false
                    onTriggered: tooltip.label = ""
                }

                Connections {
                    target: w
                    function onHoveredButtonChanged() {
                        if (w.hoveredButton !== null) {
                            tooltipHideTimer.stop();
                            tooltipClearTimer.stop();
                            tooltip.label = w.hoveredButton.text;
                            tooltip.shown = true;
                        } else {
                            tooltipHideTimer.restart();
                        }
                    }
                }
            }

            function keyName(key) {
                if (key >= Qt.Key_A && key <= Qt.Key_Z)
                    return String.fromCharCode(key).toUpperCase();
                return "?";
            }

            Item {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottomMargin: 48
                anchors.leftMargin: 64
                anchors.rightMargin: 64
                height: 52

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    implicitWidth: userRow.implicitWidth + 16
                    height: 52
                    radius: 26
                    color: Colors.md3.surface_container

                    Row {
                        id: userRow
                        anchors.centerIn: parent
                        spacing: 14

                        Item {
                            width: 36
                            height: 36
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: 18
                                color: Colors.md3.primary_container
                                visible: avatar.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: Quickshell.env("USER").charAt(0).toUpperCase()
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    font.family: Config.fontFamily
                                    color: Colors.md3.on_primary_container
                                    renderType: Text.NativeRendering
                                }
                            }

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: 18
                                visible: avatar.status === Image.Ready
                                color: "transparent"
                                layer.enabled: true

                                Image {
                                    id: avatar
                                    anchors.fill: parent
                                    source: "file://" + Quickshell.env("HOME") + "/.face"
                                    sourceSize: Qt.size(72, 72)
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    cache: false
                                }
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.alpha(Colors.md3.outline_variant, 0.4)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            rightPadding: 8

                            Text {
                                text: w.userHost
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                font.family: Config.fontFamily
                                color: Colors.md3.on_surface
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: w.uptimeStr !== "" ? "up " + w.uptimeStr : ""
                                font.pixelSize: 11
                                font.family: Config.fontFamily
                                color: Qt.alpha(Colors.md3.on_surface, 0.5)
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    implicitWidth: hintsRow.implicitWidth + 32
                    height: 52
                    radius: 26
                    color: Colors.md3.surface_container

                    Row {
                        id: hintsRow
                        anchors.centerIn: parent
                        spacing: 0

                        Repeater {
                            model: buttons
                            delegate: Row {
                                required property LogoutButton modelData
                                required property int index
                                spacing: 0

                                Text {
                                    visible: index > 0
                                    text: "·"
                                    font.pixelSize: 13
                                    font.family: Config.fontFamily
                                    color: Qt.alpha(Colors.md3.on_surface, 0.3)
                                    renderType: Text.NativeRendering
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 12
                                    rightPadding: 12
                                }

                                Row {
                                    spacing: 6
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 6
                                        color: Qt.alpha(Colors.md3.on_surface, 0.08)
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: keyName(modelData.keybind)
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            font.family: Config.fontFamily
                                            color: Qt.alpha(Colors.md3.on_surface, 0.6)
                                            renderType: Text.NativeRendering
                                        }
                                    }

                                    Text {
                                        text: modelData.text
                                        font.pixelSize: 13
                                        font.family: Config.fontFamily
                                        color: Qt.alpha(Colors.md3.on_surface, 0.7)
                                        renderType: Text.NativeRendering
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
