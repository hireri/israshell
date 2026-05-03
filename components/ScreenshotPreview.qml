import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.style
import qs.icons
import Quickshell.Widgets
import QtQuick.Effects

Item {
    id: outer

    property string imagePath: ""
    property bool active: false
    property bool panelActive: false
    property string dismissMode: "slide"

    function show(path) {
        imagePath = path;
        if (!panelActive)
            panelActive = true;
        active = true;
        dismissTimer.restart();
    }

    function dismiss(mode) {
        dismissMode = mode ?? "slide";
        active = false;
    }

    component PreviewPanel: PanelWindow {
        id: panel
        required property var targetScreen
        required property string outputDir

        anchors.left: true
        anchors.top: true
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:screenshotPreview"
        WlrLayershell.screen: targetScreen
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: 400
        implicitHeight: contentCol.implicitHeight + 16 + 16

        readonly property int maxImgW: 260
        readonly property int maxImgH: 180
        readonly property real imgNatW: screenshotImage.implicitWidth > 0 ? screenshotImage.implicitWidth : maxImgW
        readonly property real imgNatH: screenshotImage.implicitHeight > 0 ? screenshotImage.implicitHeight : maxImgH
        readonly property real imgScale: Math.min(1.0, maxImgW / imgNatW, maxImgH / imgNatH)
        readonly property int imgW: Math.round(imgNatW * imgScale)
        readonly property int imgH: Math.round(imgNatH * imgScale)

        property real cardX: -400
        property real cardOpacity: 0.0
        property bool isDragging: false
        property bool dismissing: false
        readonly property real dismissThreshold: 70

        Behavior on cardX {
            enabled: !panel.isDragging && !panel.dismissing
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        function _handleRelease(diffX, velocityX) {
            panel.isDragging = false;
            const fling = Math.abs(velocityX) > 0.5;
            const past = Math.abs(diffX) > panel.dismissThreshold;
            if (past || fling) {
                outer.dismiss("slide");
            } else {
                panel.cardX = 0;
                snapOpacity.start();
            }
        }

        NumberAnimation {
            id: snapOpacity
            target: panel
            property: "cardOpacity"
            to: 1.0
            duration: 300
            easing.type: Easing.OutCubic
        }

        Component.onCompleted: {
            slideInAnim.start();
            dismissTimer.restart();
        }

        ParallelAnimation {
            id: slideInAnim
            NumberAnimation {
                target: panel
                property: "cardX"
                to: 0
                duration: 280
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: panel
                property: "cardOpacity"
                to: 1.0
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation {
            id: slideOutAnim
            ParallelAnimation {
                NumberAnimation {
                    target: panel
                    property: "cardX"
                    to: panel.cardX > 0 ? 400 : -400
                    duration: 240
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: panel
                    property: "cardOpacity"
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            ScriptAction {
                script: outer.panelActive = false
            }
        }

        SequentialAnimation {
            id: scaleOutAnim
            ParallelAnimation {
                NumberAnimation {
                    target: contentCol
                    property: "scale"
                    to: 0.88
                    duration: 180
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: panel
                    property: "cardOpacity"
                    to: 0
                    duration: 160
                    easing.type: Easing.InCubic
                }
            }
            ScriptAction {
                script: outer.panelActive = false
            }
        }

        Connections {
            target: outer

            function onActiveChanged() {
                if (!outer.active) {
                    panel.dismissing = true;
                    slideInAnim.stop();
                    snapOpacity.stop();
                    if (outer.dismissMode === "scale")
                        scaleOutAnim.start();
                    else
                        slideOutAnim.start();
                } else {
                    panel.dismissing = false;
                    slideOutAnim.stop();
                    scaleOutAnim.stop();
                    contentCol.scale = 1.0;
                    slideInAnim.start();
                }
            }
        }

        Column {
            id: contentCol
            x: 16
            y: 16
            spacing: 8
            scale: 1.0
            transformOrigin: Item.Bottom

            transform: Translate {
                x: panel.cardX
            }
            opacity: panel.cardOpacity

            Item {
                id: imageFrame
                width: panel.imgW
                height: panel.imgH

                RectangularShadow {
                    anchors.fill: imageFrame
                    radius: imageFrame.radius
                    blur: 20
                    color: Qt.rgba(0, 0, 0, 0.3)
                    offset: Qt.vector2d(0, 4)
                    antialiasing: true
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 16
                    border.width: 6
                    border.color: Colors.md3.surface_container

                    Image {
                        id: screenshotImage
                        anchors.fill: parent
                        source: outer.imagePath !== "" ? ("file://" + outer.imagePath) : ""
                        fillMode: Image.Stretch
                        smooth: true
                        asynchronous: true
                        sourceSize.width: panel.maxImgW * 2
                        sourceSize.height: panel.maxImgH * 2
                    }
                }

                HoverHandler {
                    id: imageHover
                    onHoveredChanged: outer.mouseInside = hovered || pillHover.hovered
                }

                property real _pressGX: 0
                property real _lastGX: 0
                property real _lastT: 0
                property real _velocity: 0

                MouseArea {
                    anchors.fill: parent
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onPressed: mouse => {
                        const g = mapToGlobal(mouse.x, mouse.y);
                        imageFrame._pressGX = g.x;
                        imageFrame._lastGX = g.x;
                        imageFrame._lastT = Date.now();
                        imageFrame._velocity = 0;
                        panel.isDragging = true;
                        slideInAnim.stop();
                        snapOpacity.stop();
                    }

                    onPositionChanged: mouse => {
                        if (!panel.isDragging)
                            return;
                        const g = mapToGlobal(mouse.x, mouse.y);
                        const now = Date.now();
                        const dt = now - imageFrame._lastT;
                        if (dt > 0)
                            imageFrame._velocity = (g.x - imageFrame._lastGX) / dt;
                        imageFrame._lastGX = g.x;
                        imageFrame._lastT = now;
                        const diff = g.x - imageFrame._pressGX;
                        panel.cardX = diff;
                        panel.cardOpacity = Math.max(0, 1.0 - Math.abs(diff) / 180);
                    }

                    onReleased: {
                        panel._handleRelease(panel.cardX, imageFrame._velocity);
                    }
                }
            }

            Item {
                id: pillBar
                width: pillRow.implicitWidth + 4
                height: 44
                RectangularShadow {
                    anchors.fill: pillBar
                    radius: pillBar.radius
                    blur: 20
                    color: Qt.rgba(0, 0, 0, 0.3)
                    offset: Qt.vector2d(0, 4)
                    antialiasing: true
                }

                Rectangle {
                    width: pillRow.implicitWidth + 4
                    height: 44
                    radius: height / 2
                    color: Colors.md3.surface_container

                    HoverHandler {
                        id: pillHover
                        onHoveredChanged: outer.mouseInside = hovered || imageHover.hovered
                    }

                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 0

                        PillButton {
                            iconComponent: EditIcon {}
                            onClicked: {
                                editProc.command = ["satty", "--filename", outer.imagePath, "--output-filename", outer.imagePath, "--actions-on-enter", "save-to-clipboard", "--save-after-copy", "--early-exit", "--copy-command", "wl-copy"];
                                editProc.startDetached();
                                outer.dismiss("scale");
                            }
                        }
                        PillButton {
                            iconComponent: FolderIcon {}
                            onClicked: {
                                Qt.openUrlExternally("file://" + panel.outputDir);
                                outer.dismiss("scale");
                            }
                        }
                        PillButton {
                            danger: true
                            iconComponent: DeleteIcon {}
                            onClicked: {
                                deleteProc.exec(["rm", outer.imagePath]);
                                outer.dismiss("scale");
                            }
                        }
                        PillButton {
                            iconComponent: CloseIcon {}
                            onClicked: outer.dismiss("scale")
                        }
                    }
                }
            }
        }

        Process {
            id: editProc
            running: false
        }
        Process {
            id: deleteProc
            running: false
        }
    }

    component PillButton: Item {
        id: btn
        property bool danger: false
        property Component iconComponent: null
        signal clicked
        width: 42
        height: 42

        Rectangle {
            anchors.centerIn: parent
            width: 34
            height: 34
            radius: height / 2
            color: btn.danger ? Colors.md3.error : Colors.md3.primary
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        Loader {
            anchors.centerIn: parent
            sourceComponent: btn.iconComponent
            onLoaded: {
                item.iconSize = 18;
                item.color = btn.danger ? Colors.md3.on_error : Colors.md3.on_primary;
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    Timer {
        id: dismissTimer
        interval: Config.notifications.popupTimeout * 1000
        running: false
        repeat: false
        onTriggered: outer.dismiss("slide")
    }

    property bool mouseInside: false
    onMouseInsideChanged: {
        if (mouseInside)
            dismissTimer.stop();
        else if (outer.active)
            dismissTimer.restart();
    }

    Loader {
        active: outer.panelActive && !Config.notifications.showAllMonitors
        sourceComponent: Component {
            PreviewPanel {
                targetScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
                outputDir: {
                    const p = outer.imagePath;
                    return p.substring(0, p.lastIndexOf("/"));
                }
            }
        }
    }
    Variants {
        model: (Config.notifications.showAllMonitors && outer.panelActive) ? Quickshell.screens : []
        Scope {
            id: screenScope
            required property var modelData
            PreviewPanel {
                targetScreen: screenScope.modelData
                outputDir: {
                    const p = outer.imagePath;
                    return p.substring(0, p.lastIndexOf("/"));
                }
            }
        }
    }
}
