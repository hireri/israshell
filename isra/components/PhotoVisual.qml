import QtQuick
import QtQuick.Effects
import Quickshell
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property string shape: "circle"
    property string imagePath: ""
    property real sourceSizeAnchor: 0

    onWidthChanged: _sizeSettle.restart()

    Timer {
        id: _sizeSettle
        interval: 220
        onTriggered: root.sourceSizeAnchor = root.width
    }

    readonly property alias maskItem: frameShape

    property string _quantizerSource: ""

    ColorQuantizer {
        id: quantizer
        source: root._quantizerSource
        depth: 2
        rescaleSize: 8
    }

    readonly property color dominantColor: {
        const cols = quantizer.colors;
        if (!cols || cols.length === 0)
            return Colors.md3.primary;
        let best = cols[0];
        for (const c of cols)
            if (c.hslSaturation > best.hslSaturation)
                best = c;
        return best;
    }

    readonly property var scheme: {
        const cols = quantizer.colors;
        if (!cols || cols.length === 0 || !root.imagePath)
            return { surfaceContainerHigh: Colors.md3.surface_container_high };
        return ColorUtils.m3CardScheme(root.dominantColor, Config.darkMode);
    }

    readonly property string imageKey: root.imagePath ? (root.imagePath + "|" + Math.round(root.sourceSizeAnchor)) : ""

    property int _front: 0

    function _frontItem() {
        return root._front === 0 ? photoA : photoB;
    }
    function _backItem() {
        return root._front === 0 ? photoB : photoA;
    }

    function _show(key) {
        if (key === "") {
            fadeA.stop();
            fadeB.stop();
            fadeA.to = 0;
            fadeB.to = 0;
            fadeA.start();
            fadeB.start();
            return;
        }
        const front = root._frontItem();
        const back = root._backItem();
        if (front._key === key && front.status === Image.Ready)
            return;
        if (back._key === key && back.status === Image.Ready) {
            root._crossfade(1 - root._front);
            return;
        }
        back._key = key;
        back.source = root.imagePath ? ("file://" + root.imagePath) : "";
        back.sourceSize = Qt.size(root.sourceSizeAnchor, root.sourceSizeAnchor);
    }

    function _crossfade(slot) {
        if (slot === root._front)
            return;
        root._front = slot;
        const frontItem = slot === 0 ? photoA : photoB;
        root._quantizerSource = frontItem.source.toString();
        const frontAnim = slot === 0 ? fadeA : fadeB;
        const backAnim = slot === 0 ? fadeB : fadeA;
        frontAnim.stop();
        frontAnim.to = 1;
        frontAnim.start();
        backAnim.stop();
        backAnim.to = 0;
        backAnim.start();
    }

    MaterialShape {
        id: frameShape
        anchors.fill: parent
        name: root.shape || "circle"
        shapeSize: parent.width
        color: root.scheme.surfaceContainerHigh

        layer.enabled: true
        layer.smooth: true

        Behavior on color {
            ColorAnimation { duration: 400 }
        }
    }

    Image {
        id: photoA
        property string _key: ""
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
    }
    Image {
        id: photoB
        property string _key: ""
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
    }

    MultiEffect {
        id: effectA
        anchors.fill: parent
        source: photoA
        maskEnabled: true
        maskSource: frameShape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.5
        opacity: 0
    }
    MultiEffect {
        id: effectB
        anchors.fill: parent
        source: photoB
        maskEnabled: true
        maskSource: frameShape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.5
        opacity: 0
    }

    NumberAnimation { id: fadeA; target: effectA; property: "opacity"; duration: 380; easing.type: Easing.OutCubic }
    NumberAnimation { id: fadeB; target: effectB; property: "opacity"; duration: 380; easing.type: Easing.OutCubic }

    Connections {
        target: photoA
        function onStatusChanged() {
            if (photoA.status === Image.Ready)
                root._crossfade(0);
        }
    }
    Connections {
        target: photoB
        function onStatusChanged() {
            if (photoB.status === Image.Ready)
                root._crossfade(1);
        }
    }

    onImageKeyChanged: root._show(root.imageKey)
    Component.onCompleted: {
        root.sourceSizeAnchor = root.width;
        root._show(root.imageKey);
    }

    MaterialIcon {
        anchors.centerIn: parent
        name: "image"
        iconSize: parent.width * 0.3
        color: Colors.md3.on_surface_variant
        visible: effectA.opacity < 0.5 && effectB.opacity < 0.5
    }
}
