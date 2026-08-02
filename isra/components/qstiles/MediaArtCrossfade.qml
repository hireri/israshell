import QtQuick

Item {
    id: root

    property string url: ""

    property int _frontSlot: 0
    property string _pendingUrl: ""

    onUrlChanged: _show(url)

    function _front() {
        return _frontSlot === 0 ? imgA : imgB;
    }

    function _back() {
        return _frontSlot === 0 ? imgB : imgA;
    }

    function _show(u) {
        root._pendingUrl = u;

        if (u === "") {
            fadeA.stop();
            fadeB.stop();
            fadeA.to = 0;
            fadeB.to = 0;
            fadeA.start();
            fadeB.start();
            return;
        }

        if (_front().source.toString() === u && _front().status === Image.Ready)
            return;
        if (_back().source.toString() === u && _back().status === Image.Ready) {
            _crossfade(1 - root._frontSlot);
            return;
        }

        _back().source = u;
    }

    function _crossfade(slot) {
        if (slot === root._frontSlot)
            return;
        const img = slot === 0 ? imgA : imgB;
        if (img.source.toString() !== root._pendingUrl)
            return;

        root._frontSlot = slot;

        const fadeIn = slot === 0 ? fadeA : fadeB;
        const fadeOut = slot === 0 ? fadeB : fadeA;
        fadeIn.stop();
        fadeIn.to = 1;
        fadeIn.start();
        fadeOut.stop();
        fadeOut.to = 0;
        fadeOut.start();
    }

    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize: Qt.size(128, 64)
        opacity: 0
    }

    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize: Qt.size(128, 64)
        opacity: 0
    }

    NumberAnimation { id: fadeA; target: imgA; property: "opacity"; duration: 220; easing.type: Easing.OutCubic }
    NumberAnimation { id: fadeB; target: imgB; property: "opacity"; duration: 220; easing.type: Easing.OutCubic }

    Connections {
        target: imgA
        function onStatusChanged() {
            if (imgA.status === Image.Ready)
                root._crossfade(0);
        }
    }

    Connections {
        target: imgB
        function onStatusChanged() {
            if (imgB.status === Image.Ready)
                root._crossfade(1);
        }
    }
}
