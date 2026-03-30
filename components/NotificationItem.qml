pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.style
import qs.services

Item {
    id: item

    property var wrapper: null
    property var groupRef: null
    property int itemIndex: 0

    readonly property bool isLive: wrapper !== null
    readonly property string body: wrapper?.body ?? ""
    readonly property string summary: wrapper?.summary ?? ""

    Component.onCompleted: {
        if (groupRef !== null) {
            item.x = 20;
            slideIn.start();
        }
    }

    NumberAnimation {
        id: slideIn
        target: item
        property: "x"
        to: 0
        duration: 200
        easing.type: Easing.OutCubic
    }

    implicitWidth: parent ? parent.width : 300
    implicitHeight: bodyText.implicitHeight

    Text {
        id: bodyText
        anchors {
            left: parent.left
            right: parent.right
        }
        text: item.body.length > 0 ? item.body : item.summary
        color: Colors.md3.on_surface_variant
        font.family: Config.fontFamily
        font.pixelSize: 13
        wrapMode: Text.WrapAnywhere
        textFormat: Text.RichText
        onLinkActivated: link => Qt.openUrlExternally(link)
    }
}
