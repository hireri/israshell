import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property real padding: 16

    default property alias content: col.data

    implicitWidth: parent?.width ?? 0
    implicitHeight: col.implicitHeight + root.padding * 2

    ColumnLayout {
        id: col
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 12
    }
}
