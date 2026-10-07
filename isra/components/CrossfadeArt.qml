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
    property real contentRotation: 0
    property bool settleUpright: false

    onSettleUprightChanged: {
        if (!settleUpright) {
            uprightAnim.stop();
            return;
        }
        uprightAnim.to = contentRotation > 180 ? 360 : 0;
        uprightAnim.restart();
    }

    NumberAnimation {
        id: uprightAnim
        target: root
        property: "contentRotation"
        duration: 500
        easing.type: Easing.OutCubic
        onFinished: root.contentRotation = 0
    }

    color: "transparent"

    property int frontSlot: 0
    property string targetNormUrl: ""

    function front() { return frontSlot === 0 ? imgA : imgB; }
    function back() { return frontSlot === 0 ? imgB : imgA; }
    function frontAnim() { return frontSlot === 0 ? animA : animB; }
    function backAnim() { return frontSlot === 0 ? animB : animA; }

    function _normalize(path) {
        if (!path || path === "")
            return "";
        return Qt.resolvedUrl(path).toString();
    }

    function _show(path) {
        const norm = _normalize(path);
        targetNormUrl = norm;

        if (norm === "") {
            animA.stop();
            animB.stop();
            animA.to = 0;
            animB.to = 0;
            animA.start();
            animB.start();
            return;
        }

        if (_normalize(front().source) === norm && front().status === Image.Ready) {
            frontAnim().stop();
            frontAnim().to = 1;
            frontAnim().start();
            backAnim().stop();
            backAnim().to = 0;
            backAnim().start();
            return;
        }

        if (_normalize(back().source) === norm && back().status === Image.Ready) {
            _crossfade(1 - frontSlot);
            return;
        }

        if (_normalize(back().source) === norm)
            back().source = "";

        back().source = norm;
        frontAnim().stop();
        frontAnim().to = 1;
        frontAnim().start();
    }

    function _crossfade(slot) {
        if (slot === frontSlot)
            return;
        const loaded = slot === 0 ? imgA : imgB;
        if (_normalize(loaded.source) !== targetNormUrl)
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
        rotation: root.contentRotation
        layer.enabled: root.blurEnabled
        layer.effect: MultiEffect {
            blurEnabled: root.blurEnabled
            blur: root.blurAmount
            blurMax: root.blurMax
        }
        onStatusChanged: {
            if (status === Image.Ready)
                root._crossfade(0);
        }
    }

    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: root.renderSize
        asynchronous: true
        cache: true
        opacity: 0
        rotation: root.contentRotation
        layer.enabled: root.blurEnabled
        layer.effect: MultiEffect {
            blurEnabled: root.blurEnabled
            blur: root.blurAmount
            blurMax: root.blurMax
        }
        onStatusChanged: {
            if (status === Image.Ready)
                root._crossfade(1);
        }
    }

    NumberAnimation { id: animA; target: imgA; property: "opacity"; duration: root.fadeDuration; easing.type: Easing.OutCubic }
    NumberAnimation { id: animB; target: imgB; property: "opacity"; duration: root.fadeDuration; easing.type: Easing.OutCubic }
}