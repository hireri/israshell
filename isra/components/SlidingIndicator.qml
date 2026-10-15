import QtQuick

Rectangle {
    id: root

    property int index: -1
    property int span: 1
    property real step: 44
    property real inset: 4

    property bool _ready: false
    property bool _fwd: true
    property real _l: 0
    property real _r: 0

    function _place() {
        if (index < 0)
            return;
        const l = index * step + inset;
        if (l !== _l)
            _fwd = l > _l;
        _l = l;
        _r = (index + span) * step - inset;
    }

    function covers(cx) {
        return index >= 0 && cx > x && cx < x + width;
    }

    onIndexChanged: _place()
    onSpanChanged: _place()
    Component.onCompleted: {
        _place();
        _ready = true;
    }

    x: _l
    width: Math.max(_r - _l, 4)
    height: parent.height - 2 * inset
    anchors.verticalCenter: parent.verticalCenter
    radius: height / 2
    opacity: index >= 0 ? 1.0 : 0.0

    Behavior on _l {
        enabled: root._ready
        NumberAnimation {
            duration: root._fwd ? 380 : 240
            easing.type: Easing.OutCubic
        }
    }
    Behavior on _r {
        enabled: root._ready
        NumberAnimation {
            duration: root._fwd ? 240 : 380
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }
}
