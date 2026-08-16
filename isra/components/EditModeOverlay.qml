import QtQuick
import Quickshell.Widgets
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    property var hostScreen: null
    readonly property bool barAtBottom: Config.bar.position === 1

    property Item blurSource: null
    readonly property bool blurActive: root.blurSource !== null && Config.blurAllowed(true)

    readonly property alias toolbarItem: toolbar
    readonly property alias widgetDrawerItem: widgetDrawer

    readonly property rect toolbarRect: Qt.rect(toolbar.x, toolbar.y, toolbar.width, toolbar.height)
    readonly property real toolbarRadius: toolbar.radius

    anchors.fill: parent

    MouseArea {
        anchors.fill: parent
        enabled: widgetDrawer.open
        onClicked: widgetDrawer.close()
    }

    component ToolButton: Rectangle {
        id: btn

        property string icon: ""
        property bool active: false
        property bool filled: false
        property string tooltip: ""
        signal activated

        implicitWidth: 34
        implicitHeight: 34
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter

        color: btn.filled ? Colors.md3.primary : (btn.active ? Qt.alpha(Colors.md3.on_surface, 0.12) : Qt.alpha(Colors.md3.on_surface, 0))

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: btn.filled ? Qt.rgba(1, 1, 1, 0.10) : Qt.alpha(Colors.md3.on_surface, 0.08)
            opacity: btnMouse.containsMouse ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            name: btn.icon
            filled: btn.active || btn.filled
            iconSize: 17
            color: btn.filled ? Colors.md3.on_primary : Colors.md3.on_surface_variant
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
        }
    }

    ClippingRectangle {
        id: toolbar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: root.barAtBottom ? parent.top : undefined
        anchors.bottom: root.barAtBottom ? undefined : parent.bottom
        anchors.topMargin: 24
        anchors.bottomMargin: 24
        layer.enabled: true

        readonly property real pillW: toolbarRow.implicitWidth + 12
        readonly property real pillH: 48
        readonly property real _targetW: widgetDrawer.open ? widgetDrawer.cardW : pillW
        readonly property real _targetH: widgetDrawer.open ? widgetDrawer.cardH : pillH
        readonly property real _targetRadius: widgetDrawer.open ? 20 : _targetH / 2

        width: _targetW
        height: _targetH
        radius: _targetRadius

        Behavior on width {
            NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
        }
        Behavior on height {
            NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
        }
        Behavior on radius {
            NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
        }

        color: root.blurActive ? "transparent" : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        border.width: 1
        border.color: Qt.alpha(Colors.md3.on_surface, 0.15)

        ShaderEffectSource {
            anchors.fill: parent
            visible: root.blurActive
            sourceItem: root.blurSource
            sourceRect: Qt.rect(toolbar.x, toolbar.y, toolbar.width, toolbar.height)
            hideSource: false
        }

        Rectangle {
            anchors.fill: parent
            visible: root.blurActive
            color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        }

        Row {
            id: toolbarRow
            anchors.centerIn: parent
            spacing: 4
            visible: opacity > 0.01

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7
                leftPadding: 8
                rightPadding: 4

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "edit"
                    filled: true
                    iconSize: 16
                    color: Colors.md3.primary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Localization.t("background.editing_widgets")
                    color: Colors.md3.on_surface
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 20
                color: Qt.alpha(Colors.md3.on_surface, 0.15)
            }

            Item {
                width: 2
                height: 1
            }

            ToolButton {
                icon: "add"
                active: widgetDrawer.open
                onActivated: widgetDrawer.toggle()
            }

            ToolButton {
                icon: "history"
                onActivated: EditModeService.undoChanges()
            }

            ToolButton {
                icon: "check"
                filled: true
                onActivated: EditModeService.disable()
            }
        }

        WidgetDrawer {
            id: widgetDrawer
            hostScreen: root.hostScreen
            anchors.fill: parent
        }

        Connections {
            target: widgetDrawer
            function onOpenChanged(): void {
                if (widgetDrawer.open) {
                    contentToPill.stop();
                    contentToGrid.restart();
                } else {
                    contentToGrid.stop();
                    contentToPill.restart();
                }
            }
        }

        SequentialAnimation {
            id: contentToGrid
            NumberAnimation { target: toolbarRow; property: "opacity"; to: 0; duration: 120; easing.type: Easing.OutCubic }
            NumberAnimation { target: widgetDrawer; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }

        SequentialAnimation {
            id: contentToPill
            NumberAnimation { target: widgetDrawer; property: "opacity"; to: 0; duration: 120; easing.type: Easing.OutCubic }
            NumberAnimation { target: toolbarRow; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }
    }
}
