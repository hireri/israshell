import QtQuick
import Quickshell
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell.Io

Item {
    id: root

    property string name: ""
    property bool filled: false
    property color color: "white"
    property real iconSize: 24
    property int transitionDuration: 220
    // "wipe-up", "wipe-down", "wipe-left", "wipe-right", "circle", "crossfade-scale"
    property string transitionType: "wipe-left"

    width: iconSize
    height: iconSize
    layer.enabled: true
    layer.samples: 4

    property var _outlinePaths: []
    property var _filledPaths: []

    property bool _hasOutline: _outlinePaths.length > 0
    property bool _hasFilled: _filledPaths.length > 0
    property real _diagonal: Math.sqrt(root.width * root.width + root.height * root.height)

    property real _progress: {
        if (root._hasOutline && !root._hasFilled) return 0;
        if (!root._hasOutline && root._hasFilled) return 1;
        return filled ? 1 : 0;
    }

    Behavior on _progress {
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutQuad
        }
    }

    onNameChanged: loadSvgs()
    Component.onCompleted: loadSvgs()

    property string _currentLoadingName: ""
    property bool _outlineLoaded: false
    property bool _filledLoaded: false
    property string _outlineContent: ""
    property string _filledContent: ""

    function loadSvgs() {
        if (!name) {
            root._outlinePaths = [];
            root._filledPaths = [];
            root._currentLoadingName = "";
            return;
        }

        let loadingName = name.toLowerCase();
        root._currentLoadingName = loadingName;
        root._outlineLoaded = false;
        root._filledLoaded = false;

        outlineFileView.path = Quickshell.shellDir + "/icons/outline/" + loadingName + ".svg";
        filledFileView.path = Quickshell.shellDir + "/icons/filled/" + loadingName + ".svg";
    }

    function checkCompletion() {
        if (root._outlineLoaded && root._filledLoaded) {
            root._outlinePaths = root._outlineContent ? parseSvgPaths(root._outlineContent) : [];
            root._filledPaths = root._filledContent ? parseSvgPaths(root._filledContent) : [];
        }
    }

    function parseSvgPaths(xmlContent) {
        let paths = [];
        let regex = /d="([^"]+)"/g;
        let match;
        while ((match = regex.exec(xmlContent)) !== null) {
            paths.push(match[1]);
        }
        return paths;
    }

    Item {
        id: outlineClip
        clip: transitionType !== "circle" && transitionType !== "crossfade-scale"
        visible: root._hasOutline && root._progress < 1
        
        width: {
            if (transitionType === "circle" || transitionType === "crossfade-scale")
                return root.width;
            let w = root.width;
            if (transitionType === "wipe-left" || transitionType === "wipe-right")
                w = root.width * (1 - root._progress);
            return Math.round(w);
        }
        height: {
            if (transitionType === "circle" || transitionType === "crossfade-scale")
                return root.height;
            let h = root.height;
            if (transitionType === "wipe-up" || transitionType === "wipe-down")
                h = root.height * (1 - root._progress);
            return Math.round(h);
        }
        x: {
            if (transitionType === "circle" || transitionType === "crossfade-scale")
                return 0;
            let val = 0;
            if (transitionType === "wipe-right")
                val = root.width - width;
            return Math.round(val);
        }
        y: {
            if (transitionType === "circle" || transitionType === "crossfade-scale")
                return 0;
            let val = 0;
            if (transitionType === "wipe-down")
                val = root.height - height;
            return Math.round(val);
        }

        opacity: (transitionType === "circle" || transitionType === "crossfade-scale") ? (1 - root._progress) : 1
        scale: transitionType === "crossfade-scale" ? (1.0 - 0.2 * root._progress) : 1.0
        transformOrigin: Item.Center

        Shape {
            id: outlineShape
            width: root.width
            height: root.height
            x: -outlineClip.x
            y: root.height - outlineClip.y
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            Instantiator {
                active: root._hasOutline
                model: root._outlinePaths
                onObjectAdded: (index, object) => outlineShape.data.push(object)
                onObjectRemoved: (index, object) => {
                    let idx = outlineShape.data.indexOf(object);
                    if (idx !== -1) outlineShape.data.splice(idx, 1);
                }

                ShapePath {
                    strokeWidth: 0
                    fillColor: root.color
                    scale: Qt.size(outlineShape.width / 960, outlineShape.height / 960)
                    PathSvg { path: modelData }
                }
            }
        }
    }

    Item {
        id: filledClip
        visible: root._hasFilled && root._progress > 0
        
        width: {
            if (transitionType === "circle" || transitionType === "crossfade-scale")
                return root.width;
            let w = root.width;
            if (transitionType === "wipe-left" || transitionType === "wipe-right")
                w = root.width * root._progress;
            return Math.round(w);
        }
        height: {
            if (transitionType === "circle" || transitionType === "crossfade-scale")
                return root.height;
            let h = root.height;
            if (transitionType === "wipe-up" || transitionType === "wipe-down")
                h = root.height * root._progress;
            return Math.round(h);
        }
        x: {
            if (transitionType === "circle" || transitionType === "crossfade-scale")
                return 0;
            let val = 0;
            if (transitionType === "wipe-left")
                val = root.width - width;
            return Math.round(val);
        }
        y: {
            if (transitionType === "circle" || transitionType === "crossfade-scale")
                return 0;
            let val = 0;
            if (transitionType === "wipe-up")
                val = root.height - height;
            return Math.round(val);
        }

        clip: transitionType !== "circle" && transitionType !== "crossfade-scale"
        
        layer.enabled: transitionType === "circle" && root._progress > 0 && root._progress < 1
        layer.samples: 4
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: circleMask
        }

        opacity: transitionType === "crossfade-scale" ? root._progress : 1
        scale: transitionType === "crossfade-scale" ? (0.8 + 0.2 * root._progress) : 1.0
        transformOrigin: Item.Center

        Shape {
            id: filledShape
            width: root.width
            height: root.height
            x: -filledClip.x
            y: root.height - filledClip.y
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            Instantiator {
                active: root._hasFilled
                model: root._filledPaths
                onObjectAdded: (index, object) => filledShape.data.push(object)
                onObjectRemoved: (index, object) => {
                    let idx = filledShape.data.indexOf(object);
                    if (idx !== -1) filledShape.data.splice(idx, 1);
                }

                ShapePath {
                    strokeWidth: 0
                    fillColor: root.color
                    scale: Qt.size(filledShape.width / 960, filledShape.height / 960)
                    PathSvg { path: modelData }
                }
            }
        }
    }

    Item {
        id: circleMask
        width: root.width   
        height: root.height 
        visible: false
        layer.enabled: true
        layer.samples: 4
        layer.smooth: true

        Rectangle {
            width: root._diagonal * root._progress
            height: root._diagonal * root._progress
            radius: width / 2
            anchors.centerIn: parent
            color: "black"
        }
    }

    FileView {
        id: outlineFileView
        onLoaded: {
            root._outlineContent = text();
            root._outlineLoaded = true;
            checkCompletion();
        }
        onLoadFailed: {
            root._outlineContent = "";
            root._outlineLoaded = true;
            checkCompletion();
        }
    }

    FileView {
        id: filledFileView
        onLoaded: {
            root._filledContent = text();
            root._filledLoaded = true;
            checkCompletion();
        }
        onLoadFailed: {
            root._filledContent = "";
            root._filledLoaded = true;
            checkCompletion();
        }
    }
}