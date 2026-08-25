import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property real buttonScale: 0.28
    property bool interactive: true

    property string shape: "circle"
    property string playingShape: "cookie9"

    readonly property var player: MediaPlayerState.displayPlayer
    readonly property bool isPlaying: root.player?.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: root.player?.trackArtUrl ?? ""

    readonly property string _bodyShapeName: root.isPlaying ? (root.playingShape || "cookie9") : (root.shape || "circle")

    property real _bodyRotation: 0

    function _spin(): void {
        root._bodyRotation += bodyShape.symmetryStep;
    }

    on_BodyShapeNameChanged: {
        bodyShape.rotationAnimates = false;
        bodyMaskShape.rotationAnimates = false;
        root._bodyRotation = 0;
        bodyShape.rotationAnimates = true;
        bodyMaskShape.rotationAnimates = true;
    }

    property int _front: 0

    function _frontItem() {
        return root._front === 0 ? artA : artB;
    }
    function _backItem() {
        return root._front === 0 ? artB : artA;
    }

    function _show(url) {
        if (url === "") {
            fadeA.stop();
            fadeB.stop();
            fadeA.to = 0;
            fadeB.to = 0;
            root._spin();
            fadeA.start();
            fadeB.start();
            return;
        }
        const front = root._frontItem();
        const back = root._backItem();
        if (front._key === url && front.status === Image.Ready) {
            root._spin();
            return;
        }
        if (back._key === url && back.status === Image.Ready) {
            root._crossfade(1 - root._front);
            return;
        }
        back._key = url;
        back.source = url;
    }

    function _crossfade(slot) {
        if (slot === root._front)
            return;
        root._spin();
        root._front = slot;
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
        id: bodyShape
        anchors.fill: parent
        name: root._bodyShapeName
        shapeSize: parent.width
        color: Config.desktopWidgetsBlurActive ? Config.dim(Colors.md3.primary_container) : Colors.md3.primary_container
        rotationDegrees: root._bodyRotation
        outlined: true
        strokeColor: Qt.alpha(Colors.md3.outline, 0.5)
        strokeWidth: 1

        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            shadowEnabled: !Config.desktopWidgetsBlurActive
            shadowBlur: 0.5
            shadowColor: Qt.alpha("black", 0.2)
            shadowVerticalOffset: 4
        }
    }

    Item {
        id: maskWrapper
        anchors.fill: parent

        MaterialShape {
            id: bodyMaskShape
            anchors.fill: parent
            name: root._bodyShapeName
            shapeSize: parent.width
            color: "white"
            rotationDegrees: root._bodyRotation
        }
    }

    ShaderEffectSource {
        id: bodyMaskSource
        anchors.fill: parent
        sourceItem: maskWrapper
        hideSource: true
        visible: false
    }

    Image {
        id: artA
        property string _key: ""
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
        visible: false
    }
    Image {
        id: artB
        property string _key: ""
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
        visible: false
    }

    MultiEffect {
        id: effectA
        anchors.fill: parent
        source: artA
        maskEnabled: true
        maskSource: bodyMaskSource
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.5
        opacity: 0
    }
    MultiEffect {
        id: effectB
        anchors.fill: parent
        source: artB
        maskEnabled: true
        maskSource: bodyMaskSource
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.5
        opacity: 0
    }

    NumberAnimation { id: fadeA; target: effectA; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
    NumberAnimation { id: fadeB; target: effectB; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }

    Connections {
        target: artA
        function onStatusChanged() {
            if (artA.status === Image.Ready)
                root._crossfade(0);
        }
    }
    Connections {
        target: artB
        function onStatusChanged() {
            if (artB.status === Image.Ready)
                root._crossfade(1);
        }
    }

    Timer {
        id: clearArtDelay
        interval: 250
        onTriggered: root._show("")
    }

    onArtUrlChanged: {
        MediaPlayerState.ensureArt(root.artUrl);
        if (root.artUrl === "") {
            clearArtDelay.restart();
        } else {
            clearArtDelay.stop();
            root._show(root.artUrl);
        }
    }

    Component.onCompleted: {
        MediaPlayerState.ensureArt(root.artUrl);
        root._show(root.artUrl);
    }

    MaterialIcon {
        anchors.centerIn: parent
        name: "music-note"
        iconSize: parent.width * 0.3
        color: Colors.md3.on_primary_container
        visible: effectA.opacity < 0.5 && effectB.opacity < 0.5
    }

    Item {
        id: playBtn
        width: parent.width * root.buttonScale
        height: width
        anchors {
            left: parent.left
            bottom: parent.bottom
        }

        MaterialShape {
            anchors.fill: parent
            name: "square"
            shapeSize: parent.width
            color: Colors.md3.primary
        }

        MaterialIcon {
            anchors.centerIn: parent
            name: "play-pause"
            filled: root.isPlaying
            iconSize: parent.width * 0.45
            color: Colors.md3.on_primary
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            visible: root.interactive
            cursorShape: Qt.PointingHandCursor
            onClicked: root.player?.togglePlaying()
        }
    }

    Item {
        id: skipBtn
        width: parent.width * root.buttonScale
        height: width
        anchors {
            right: parent.right
            top: parent.top
        }
        readonly property bool canSkip: root.player?.canGoNext ?? false
        opacity: canSkip ? 1.0 : 0.5

        MaterialShape {
            anchors.fill: parent
            name: "clover4"
            shapeSize: parent.width
            color: Colors.md3.secondary_container
        }

        MaterialIcon {
            anchors.centerIn: parent
            name: "next-prev"
            filled: true
            iconSize: parent.width * 0.4
            color: Colors.md3.on_secondary_container
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            visible: root.interactive
            cursorShape: skipBtn.canSkip ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (skipBtn.canSkip)
                root.player.next()
        }
    }
}