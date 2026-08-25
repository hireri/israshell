import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services

Item {
    id: root

    property bool showLogo: true
    property bool showSwatches: true

    readonly property var _rows: [
        { k: Localization.t("fetchCard.kernel"), v: SystemInfo.kernel },
        { k: Localization.t("fetchCard.uptime"), v: SystemInfo.uptime },
        { k: Localization.t("fetchCard.wm"), v: SystemInfo.session },
        { k: Localization.t("fetchCard.shell"), v: SystemInfo.shellName },
        { k: Localization.t("fetchCard.packages"), v: SystemInfo.packages },
        { k: Localization.t("fetchCard.cpu"), v: SystemInfo.cpu },
        { k: Localization.t("fetchCard.gpu"), v: SystemInfo.gpu },
        { k: Localization.t("fetchCard.memory"), v: SystemInfo.memory }
    ]

    readonly property bool wide: root.width > root.height * 1.25
    property bool appliedWide: false
    property bool _started: false

    onWideChanged: {
        if (root._started)
            swapSeq.restart();
    }

    Component.onCompleted: {
        root.appliedWide = root.wide;
        root._started = true;
    }

    SequentialAnimation {
        id: swapSeq
        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 110; easing.type: Easing.OutCubic }
        ScriptAction { script: root.appliedWide = root.wide }
        NumberAnimation { target: content; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
    }

    readonly property real _u: {
        if (root.width <= 0 || root.height <= 0)
            return 1;
        return Math.max(0.6, Math.min(1.5, Math.min(root.width / 398, root.height / 224)));
    }

    readonly property real _radius: 20

    readonly property bool _logoVisible: root.showLogo && root.appliedWide && root.width > 260
    readonly property real _pad: 16 * root._u

    Rectangle {
        anchors.fill: parent
        radius: Math.min(root._radius, Math.min(width, height) / 2)
        color: Config.desktopWidgetsBlurActive ? Config.dim(Colors.md3.surface_container_high) : Colors.md3.surface_container_high
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: !Config.desktopWidgetsBlurActive
            shadowBlur: 0.5
            shadowColor: Qt.alpha("black", 0.2)
            shadowVerticalOffset: 4
        }

        Item {
            id: content
            anchors.fill: parent

            IconImage {
                id: logo
                visible: root._logoVisible
                x: root._pad
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: Math.max(40, Math.min(root.height - root._pad * 2, 84 * root._u))
                source: Quickshell.iconPath(SystemInfo.logo, "distributor-logo-linux")
                smooth: true
            }

            Column {
                id: info

                x: root._logoVisible ? logo.x + logo.implicitSize + 16 * root._u : root._pad
                width: root.width - x - root._pad
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * root._u

                readonly property real rowH: 15 * root._u
                readonly property real available: root.height - root._pad * 2
                    - info.rowH - 8 * root._u
                    - (root.showSwatches ? 14 * root._u : 0)
                readonly property int maxRows: Math.max(1, Math.floor(info.available / (info.rowH + 3 * root._u)))

                Text {
                    text: SystemInfo.username + "@" + SystemInfo.hostname
                    font.family: Config.fontMonospace
                    font.pixelSize: 13 * root._u
                    font.weight: Font.Bold
                    color: Colors.md3.primary
                    width: info.width
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: info.width
                    height: 1
                    color: Qt.alpha(Colors.md3.outline, 0.45)
                }

                Item {
                    width: 1
                    height: 4 * root._u
                }

                Repeater {
                    model: root._rows.slice(0, info.maxRows)

                    Row {
                        required property var modelData

                        width: info.width
                        height: info.rowH
                        spacing: 6 * root._u

                        Text {
                            text: modelData.k
                            font.family: Config.fontMonospace
                            font.pixelSize: 11 * root._u
                            font.weight: Font.Bold
                            color: Colors.md3.on_surface
                        }

                        Text {
                            width: parent.width - x
                            text: modelData.v
                            font.family: Config.fontMonospace
                            font.pixelSize: 11 * root._u
                            color: Colors.md3.on_surface_variant
                            elide: Text.ElideRight
                        }
                    }
                }

                Item {
                    visible: root.showSwatches
                    width: 1
                    height: 6 * root._u
                }

                Row {
                    visible: root.showSwatches
                    spacing: 4 * root._u

                    Repeater {
                        model: [
                            Colors.md3.primary,
                            Colors.md3.secondary,
                            Colors.md3.tertiary,
                            Colors.md3.error,
                            Colors.md3.primary_container,
                            Colors.md3.secondary_container,
                            Colors.md3.tertiary_container,
                            Colors.md3.outline
                        ]

                        Rectangle {
                            required property var modelData

                            width: 10 * root._u
                            height: 10 * root._u
                            radius: 3 * root._u
                            color: modelData
                            antialiasing: true
                        }
                    }
                }
            }
        }
    }
}
