import QtQuick
import Quickshell
import QtQuick.Shapes

Item {
    id: root
    
    property string name: ""
    property bool filled: false
    property color color: "white"
    property real iconSize: 24

    width: iconSize
    height: iconSize
    layer.enabled: true
    layer.samples: 4

    property var _svgPaths: []

    onNameChanged: loadSvg()
    onFilledChanged: loadSvg()
    Component.onCompleted: loadSvg()

    function loadSvg() {
        if (!name) return;

        let file = name.toLowerCase() + ".svg";
        
        let baseUrl = Quickshell.shellDir + "/icons/";
        
        let outlinePath = baseUrl + "outline/" + file;
        let filledPath = baseUrl + "filled/" + file;

        if (filled) {
            fetchFile(filledPath, function(success, content) {
                if (success) {
                    parseSvgPaths(content);
                } else {
                    fetchFile(outlinePath, function(succ, outlineContent) {
                        if (succ) parseSvgPaths(outlineContent);
                    });
                }
            });
        } else {
            fetchFile(outlinePath, function(success, content) {
                if (success) parseSvgPaths(content);
            });
        }
    }

    function fetchFile(url, callback) {
        let xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    callback(true, xhr.responseText);
                } else {
                    callback(false, "");
                }
            }
        };
        xhr.open("GET", Qt.resolvedUrl(url));
        xhr.send();
    }

    function parseSvgPaths(xmlContent) {
        let paths = [];

        let regex = /d="([^"]+)"/g;
        let match;
        
        while ((match = regex.exec(xmlContent)) !== null) {
            paths.push(match[1]);
        }
        
        root._svgPaths = paths;
    }

    Shape {
        id: shapeContainer
        width: parent.width
        height: parent.height
        y: parent.height
        antialiasing: true

        Instantiator {
            model: root._svgPaths
            
            onObjectAdded: (index, object) => shapeContainer.data.push(object)
            onObjectRemoved: (index, object) => {
                let idx = shapeContainer.data.indexOf(object);
                if (idx !== -1) shapeContainer.data.splice(idx, 1);
            }

            ShapePath {
                strokeWidth: 0
                fillColor: root.color
                scale: Qt.size(shapeContainer.width / 960, shapeContainer.height / 960)
                
                PathSvg {
                    path: modelData
                }
            }
        }
    }
}