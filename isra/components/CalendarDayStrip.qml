pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    property date day: new Date()
    property var events: []

    signal addRequested
    signal eventClicked(var ev)

    readonly property int headerHeight: 28
    readonly property string dayText: LocaleService.formatDateLong(day)

    implicitWidth: 268
    implicitHeight: 144

    function subtitle(ev) {
        let s = ev.allDay ? Localization.t("calendar.allDay") : LocaleService.formatClockTime(new Date(ev.start)) + " – " + LocaleService.formatClockTime(new Date(ev.end));
        if (ev.location)
            s += " · " + ev.location;
        return s;
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Colors.md3.surface_container
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: 12

        Item {
            id: header
            width: parent.width
            height: root.headerHeight

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - countLabel.width - addBtn.width - 16
                text: root.dayText
                elide: Text.ElideRight
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Text {
                id: countLabel
                anchors.right: addBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.events.length > 0 ? Localization.t("calendar.eventCount").arg(root.events.length) : ""
                color: Colors.md3.on_surface_variant
                font.family: Config.fontFamily
                font.pixelSize: 12
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Rectangle {
                id: addBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: height / 2
                color: addMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "add"
                    iconSize: 16
                    color: Colors.md3.on_surface
                    scale: addMa.pressed ? 0.85 : 1
                    Behavior on scale {
                        NumberAnimation { duration: 100 }
                    }
                }

                MouseArea {
                    id: addMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.addRequested()
                }
            }
        }

        Item {
            visible: root.events.length === 0
            y: root.headerHeight
            width: parent.width
            height: 34

            MaterialIcon {
                id: emptyIcon
                name: "calendar-month"
                iconSize: 18
                color: Colors.md3.on_surface_variant
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Text {
                anchors.left: emptyIcon.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: Localization.t("calendar.noEvents")
                color: Colors.md3.on_surface_variant
                font.family: Config.fontFamily
                font.pixelSize: 12
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        ListView {
            id: list
            y: root.headerHeight
            width: parent.width
            height: parent.height - root.headerHeight
            clip: true
            spacing: 4
            model: root.events

            flickDeceleration: 4000
            maximumFlickVelocity: 2200
            boundsBehavior: Flickable.DragAndOvershootBounds

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    list.cancelFlick();
                    list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, list.contentY - event.angleDelta.y * 0.5));
                }
            }

            delegate: Item {
                id: row
                required property var modelData

                width: list.width
                height: 34

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -6
                    anchors.rightMargin: -6
                    radius: 10
                    color: Colors.md3.on_surface
                    opacity: rowMa.containsMouse ? 0.08 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }
                }

                Rectangle {
                    width: 4
                    height: parent.height
                    radius: 2
                    color: row.modelData.color || Colors.md3.primary
                }

                Column {
                    x: 14
                    width: row.width - x - (linkBtn.visible ? 32 : 0)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        text: row.modelData.title ?? ""
                        elide: Text.ElideRight
                        color: Colors.md3.on_surface
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Text {
                        width: parent.width
                        text: root.subtitle(row.modelData)
                        elide: Text.ElideRight
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.eventClicked(row.modelData)
                }

                Rectangle {
                    id: linkBtn
                    visible: (row.modelData.link ?? "") !== ""
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: height / 2
                    color: linkMa.containsMouse ? Colors.md3.primary : Colors.md3.surface_container_highest
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "arrow-outward"
                        iconSize: 16
                        color: linkMa.containsMouse ? Colors.md3.on_primary : Colors.md3.on_surface
                        scale: linkMa.pressed ? 0.85 : 1
                        Behavior on scale {
                            NumberAnimation { duration: 100 }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        id: linkMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(row.modelData.link)
                    }
                }
            }
        }
    }
}
