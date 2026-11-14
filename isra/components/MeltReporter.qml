import QtQuick

QtObject {
    id: reporter

    property var win: null
    property string key: ""
    property rect rect: Qt.rect(0, 0, 0, 0)
    property bool active: false
    property int edge: -1
    property real depth: -1

    readonly property var _v: active ? ({ x: rect.x, y: rect.y, width: rect.width, height: rect.height, edge: edge, depth: depth }) : null
    on_VChanged: reporter.win?.setMelt(reporter.key, reporter._v)
    onWinChanged: reporter.win?.setMelt(reporter.key, reporter._v)
    Component.onDestruction: reporter.win?.setMelt(reporter.key, null)
}
