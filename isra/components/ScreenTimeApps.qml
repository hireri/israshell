pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.services
import "../windows/system/format.js" as Fmt

Column {
    id: root

    property var apps: []
    property int count: 3
    property int rowH: 22

    spacing: 4

    Repeater {
        model: root.apps.slice(0, root.count)

        Item {
            id: app
            required property var modelData
            width: root.width
            height: root.rowH

            Rectangle {
                id: dotItem
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: ScreenTimeService.categoryColor(app.modelData.category)
            }

            Text {
                id: durationText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Fmt.duration(app.modelData.seconds)
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.outline
                renderType: Text.NativeRendering
            }

            Text {
                anchors.left: dotItem.right
                anchors.leftMargin: 10
                anchors.right: durationText.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: ScreenTimeService.appName(app.modelData.id)
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Colors.md3.on_surface
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }
        }
    }
}
