pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import qs.style
import "format.js" as Fmt

Rectangle {
    id: root

    property string name: ""
    property string shape: "cookie6"
    property var items: []
    property string note: ""

    implicitHeight: 292
    radius: 24
    color: Config.dim(Colors.md3.surface_container)

    ColumnLayout {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ShapeIcon {
                size: 34
                shape: root.shape
                fill: root.items.length > 0 ? Colors.md3.primary : Config.dim(Colors.md3.surface_container_highest)
                ink: root.items.length > 0 ? Colors.md3.on_primary : Colors.md3.on_surface_variant

                Text {
                    anchors.centerIn: parent
                    text: String(root.items.length)
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: root.items.length > 0 ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.name
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Colors.md3.on_surface
            }
        }

        ListView {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length > 0
            clip: true
            model: root.items
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: view.contentHeight > view.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }

            delegate: Item {
                id: row
                required property var modelData

                width: ListView.view.width - 12
                height: 40

                ColumnLayout {
                    anchors {
                        fill: parent
                        leftMargin: 4
                        rightMargin: 4
                    }
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Colors.md3.on_surface
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: Fmt.needsRestart(row.modelData.name)
                            text: Localization.t("systemApp.pkg_restart")
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Colors.md3.tertiary
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.from !== "" ? row.modelData.from + " → " + row.modelData.to : row.modelData.to
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        color: Colors.md3.outline
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.items.length === 0
            spacing: 10

            Item {
                Layout.fillHeight: true
            }

            ShapeIcon {
                Layout.alignment: Qt.AlignHCenter
                size: 64
                shape: root.shape
                icon: "check"
                fill: Colors.md3.primary_container
                ink: Colors.md3.on_primary_container
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Localization.t("systemApp.pkg_up_to_date_short")
                font.family: Config.fontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Colors.md3.on_surface
            }

            Text {
                Layout.fillWidth: true
                visible: root.note !== ""
                horizontalAlignment: Text.AlignHCenter
                text: root.note
                wrapMode: Text.WordWrap
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Colors.md3.outline
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
