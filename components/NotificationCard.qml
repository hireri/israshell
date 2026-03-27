import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.style
import qs.services

Rectangle {
    id: card

    property var wrapper: null
    property var historyData: null

    readonly property bool isLive: wrapper !== null

    readonly property string summary: isLive ? wrapper.summary : (historyData?.summary ?? "")
    readonly property string body: isLive ? wrapper.body : (historyData?.body ?? "")
    readonly property string appName: isLive ? wrapper.appName : (historyData?.appName ?? "")
    readonly property string appIcon: isLive ? wrapper.appIcon : (historyData?.appIcon ?? "")
    readonly property string imageUrl: isLive ? wrapper.image : (historyData?.image ?? "")

    readonly property string mainIconSrc: {
        const raw = imageUrl || appIcon;
        if (!raw)
            return "image://icon/dialog-information";
        if (raw.startsWith("/"))
            return "file://" + raw;
        return "image://icon/" + raw;
    }

    readonly property bool hasBadge: imageUrl.length > 0 && appIcon.length > 0
    readonly property string badgeSrc: {
        if (!appIcon)
            return "";
        if (appIcon.startsWith("/"))
            return "file://" + appIcon;
        return "image://icon/" + appIcon;
    }

    readonly property var actions: (isLive && wrapper?.notification) ? wrapper.notification.actions : []

    property bool expanded: isLive ? wrapper.expanded : false
    onExpandedChanged: if (isLive)
        wrapper.expanded = expanded

    width: 320
    implicitHeight: expanded ? contentCol.implicitHeight + 24 : 74
    height: implicitHeight

    Behavior on height {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    color: Colors.md3.surface_container_high
    radius: 12
    border.color: Colors.md3.outline_variant
    border.width: 1
    clip: true

    MouseArea {
        anchors.fill: parent
        onClicked: card.expanded = !card.expanded
    }

    ColumnLayout {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 10

            Item {
                width: 44
                height: 44

                Rectangle {
                    id: mainIconRect
                    anchors.fill: parent
                    radius: 10
                    color: Colors.md3.surface_container
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: card.hasBadge ? 0 : 6
                        fillMode: Image.PreserveAspectFit
                        source: card.mainIconSrc
                    }
                }

                Rectangle {
                    visible: card.hasBadge
                    width: 18
                    height: 18
                    radius: 5
                    color: Colors.md3.surface_container_high
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        fillMode: Image.PreserveAspectFit
                        source: card.badgeSrc
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    text: card.summary
                    color: Colors.md3.on_surface
                    font.family: Config.fontFamily
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: card.body
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    // strip html tags
                    textFormat: Text.PlainText
                    visible: card.body.length > 0 && !card.expanded
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            Rectangle {
                visible: card.isLive
                width: 28
                height: 28
                radius: 6
                color: dismissHover.containsMouse ? Colors.md3.surface_container_highest : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 12
                }

                MouseArea {
                    id: dismissHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: mouse => {
                        mouse.accepted = true;
                        card.wrapper?.notification?.dismiss();
                    }
                }
            }
        }

        ColumnLayout {
            visible: card.expanded
            opacity: card.expanded ? 1 : 0
            Layout.fillWidth: true
            spacing: 8
            Layout.topMargin: 8

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            Text {
                text: card.body
                color: Colors.md3.on_surface_variant
                font.family: Config.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                visible: card.body.length > 0
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Item {
                visible: card.isLive && card.actions.length > 0
                Layout.fillWidth: true
                implicitHeight: actionsFlickable.implicitHeight

                Flickable {
                    id: actionsFlickable
                    anchors.fill: parent
                    contentWidth: actionsRow.implicitWidth
                    implicitHeight: actionsRow.implicitHeight
                    clip: true
                    flickableDirection: Flickable.HorizontalFlick

                    ScrollBar.horizontal: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    RowLayout {
                        id: actionsRow
                        spacing: 6

                        Repeater {
                            model: ScriptModel {
                                values: card.actions
                            }

                            delegate: Rectangle {
                                required property var modelData

                                implicitWidth: actionLabel.implicitWidth + 24
                                height: 32
                                radius: 8
                                color: actionHover.containsMouse ? Colors.md3.secondary_container : Colors.md3.surface_container

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: modelData.text || ""
                                    color: Colors.md3.on_surface
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: actionHover
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: mouse => {
                                        mouse.accepted = true;
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
