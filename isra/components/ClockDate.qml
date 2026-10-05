import QtQuick
import qs.style
import qs.services

Text {
    id: root

    property var face
    property bool pill: false

    readonly property string longText: {
        LocaleService.liveTime;
        const locale = Qt.locale(Config.language.split("_").slice(0, 2).join("_"));
        return new Date().toLocaleDateString(locale, Config.dateOrder === 1 ? "dddd, MMMM d" : "dddd, d MMMM");
    }

    visible: root.face.cfg.showDate
    color:   root.pill ? Colors.md3.on_surface : root.face.subColor
    text:    (root.face.cfg.dateFormat ?? "short") === "long" ? root.longText : LocaleService.shortDateText

    horizontalAlignment: root.face.halign
    topPadding:          root.pill ? root.font.pixelSize * 0.3 : 0
    bottomPadding:       root.pill ? root.font.pixelSize * 0.3 : 0
    leftPadding:         root.pill ? root.font.pixelSize * 0.6 : 0
    rightPadding:        root.pill ? root.font.pixelSize * 0.6 : 0

    Rectangle {
        z: -1
        visible: root.pill
        width:  root.contentWidth + root.leftPadding + root.rightPadding
        height: root.implicitHeight
        x: root.face.halign === Text.AlignLeft ? 0
         : root.face.halign === Text.AlignRight ? root.width - width
         : (root.width - width) / 2
        radius: height / 2
        color:  Colors.md3.surface_container_highest
    }

    font.family:       root.face.clockFont
    font.pixelSize:    root.face.dateTextSize
    font.weight:       root.face.isGoogleSansFlex ? Font.Normal : root.face.subWeight
    font.variableAxes: root.face.isGoogleSansFlex ? root.face.subAxes : ({})
}
