import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    required property var entry
    required property int index

    readonly property bool isCritical: (entry.urgency ?? "normal") === "2"
    readonly property bool isLive: NotificationService.isGroupLive(entry ? entry.groupKey : "")

    function resolveIcon(source) {
        if (!source || source === "")
            return "";
        if (source.startsWith("/") || source.includes("://"))
            return source;
        return Quickshell.iconPath(source);
    }

    readonly property string _mainIcon: entry.image !== ""
        ? resolveIcon(entry.image)
        : (entry.appIcon !== "" ? resolveIcon(entry.appIcon) : resolveIcon(entry.desktopEntry))

    readonly property string _badgeIcon: {
        if (entry.image !== "") {
            const icon = entry.appIcon !== "" ? entry.appIcon : entry.desktopEntry;
            if (icon !== "" && resolveIcon(icon) !== resolveIcon(entry.image)) {
                return resolveIcon(icon);
            }
        }
        return "";
    }

    readonly property string relativeTime: {
        const m = Math.floor((Date.now() - entry.time) / 60000);
        if (m < 1)
            return "just now";
        if (m < 60)
            return m + "m";
        const h = Math.floor(m / 60);
        if (h < 24)
            return h + "h";
        return Math.floor(h / 24) + "d";
    }

    implicitHeight: card.height + 10
    height: isLive ? 0 : implicitHeight
    visible: !isLive

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.left: parent.left
        width: parent.width
        height: mainCol.implicitHeight + 28
        radius: 26
        color: root.isCritical
            ? Colors.md3.secondary_container
            : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        clip: true

        ColumnLayout {
            id: mainCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignTop

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 12
                        color: root.isCritical
                            ? Colors.md3.primary
                            : Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)

                        MaterialIcon {
                            name: root.entry.materialIcon !== ""
                                ? root.entry.materialIcon
                                : (root.isCritical ? "brightness-alert" : "notification-active")
                            color: root.isCritical ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                            anchors.centerIn: parent
                            width: 24
                            height: width
                            filled: true
                            visible: root._mainIcon === ""
                        }

                        Image {
                            anchors.fill: parent
                            source: root._mainIcon
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(80, 80)
                            asynchronous: true
                            visible: root._mainIcon !== ""
                        }
                    }

                    ClippingRectangle {
                        visible: root._badgeIcon !== ""
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: root.isCritical
                            ? Colors.md3.primary
                            : Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -3
                        anchors.bottomMargin: -3

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: root._badgeIcon
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(40, 40)
                            asynchronous: true
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: (root.entry.groupSummary && root.entry.groupSummary.length > 0)
                                ? root.entry.groupSummary
                                : root.entry.appName
                            color: Colors.md3.on_surface
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            renderType: Text.NativeRendering
                        }

                        Text {
                            text: root.relativeTime
                            color: root.isCritical ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            opacity: 0.75
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: (root.entry.body && root.entry.body.length > 0) ? root.entry.body : root.entry.summary
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    Layout.alignment: Qt.AlignTop
                    radius: 14
                    color: closeMouse.containsMouse
                        ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
                        : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    MaterialIcon {
                        name: "close"
                        anchors.centerIn: parent
                        iconSize: 14
                        color: closeMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: NotificationService.removeHistoryEntry(root.index)
                    }
                }
            }

            Loader {
                id: actionsLoader
                Layout.fillWidth: true
                active: root.entry.actions !== undefined && root.entry.actions.length > 0
                visible: active

                sourceComponent: Row {
                    spacing: 6

                    Repeater {
                        model: root.entry.actions ?? []
                        delegate: Rectangle {
                            required property var modelData
                            implicitWidth: actionLabel.implicitWidth + 20
                            implicitHeight: 26
                            radius: 13
                            color: actionMouse.containsMouse
                                ? Colors.md3.secondary_container
                                : Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: modelData.text || Localization.t("notificationGroup.open")
                                color: Colors.md3.on_surface
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                renderType: Text.NativeRendering
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    if (typeof modelData.invoke === "function") {
                                        modelData.invoke();
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
