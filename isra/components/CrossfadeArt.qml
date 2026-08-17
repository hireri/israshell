pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

ClippingRectangle {
    id: root

    property string url: ""
    property bool blurEnabled: false
    property real blurAmount: 1.0
    property real blurMax: 32
    property size renderSize: Qt.size(120, 120)
    property int fadeDuration: 260

    color: "transparent"

    property int frontSlot: 0
    property string targetUrl: ""

    function front() { return frontSlot === 0 ? imgA : imgB; }
    function back() { return frontSlot === 0 ? imgB : imgA; }
    function frontAnim() { return frontSlot === 0 ? animA : animB; }
    function backAnim() { return frontSlot === 0 ? animB : animA; }

    function _show(path) {
        targetUrl = path;
        if (path === "") {
            animA.stop();
            animB.stop();
            animA.to = 0;
            animB.to = 0;
            animA.start();
            animB.start();
            return;
        }
        if (front().source.toString() === path && front().status === Image.Ready)
            return;
        if (back().source.toString() === path && back().status === Image.Ready) {
            _crossfade(1 - frontSlot);
            return;
        }
        back().source = path;
        frontAnim().stop();
        frontAnim().to = 1;
        frontAnim().start();
    }

    function _crossfade(slot) {
        if (slot === frontSlot)
            return;
        const loaded = slot === 0 ? imgA : imgB;
        if (loaded.source.toString() !== targetUrl)
            return;
        frontSlot = slot;
        frontAnim().stop();
        frontAnim().to = 1;
        frontAnim().start();
        backAnim().stop();
        backAnim().to = 0;
        backAnim().start();
    }

    onUrlChanged: _show(root.url)
    Component.onCompleted: _show(root.url)

    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: root.renderSize
        asynchronous: true
        cache: true
        opacity: 0
        layer.enabled: root.blurEnabled
        layer.effect: MultiEffect {
            blurEnabled: root.blurEnabled
            blur: root.blurAmount
            blurMax: root.blurMax
        }
        onStatusChanged: if (status === Image.Ready) root._crossfade(0)
    }
    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: root.renderSize
        asynchronous: true
        cache: true
        opacity: 0
        layer.enabled: root.blurEnabled
        layer.effect: MultiEffect {
            blurEnabled: root.blurEnabled
            blur: root.blurAmount
            blurMax: root.blurMax
        }
        onStatusChanged: if (status === Image.Ready) root._crossfade(1)
    }

    NumberAnimation { id: animA; target: imgA; property: "opacity"; duration: root.fadeDuration; easing.type: Easing.OutCubic }
    NumberAnimation { id: animB; target: imgB; property: "opacity"; duration: root.fadeDuration; easing.type: Easing.OutCubic }
}
