import QtQuick
import qs.services

Image {
    id: root

    property int code: 0
    property bool isDay: true
    property real iconSize: 48

    width: root.iconSize
    height: root.iconSize

    readonly property int _sourceUnit: Math.max(8, Math.ceil(root.iconSize * 2 / 8) * 8)
    sourceSize: Qt.size(root._sourceUnit, root._sourceUnit)

    source: "file://" + WeatherAssets.iconPath(root.code, root.isDay)
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    cache: true
    smooth: true
}
