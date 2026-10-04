pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.style
import qs.icons

Item {
    id: root

    implicitWidth: 260
    implicitHeight: 44

    readonly property bool failed: LockscreenService.showFailure
    readonly property bool busy: LockscreenService.unlockInProgress
    readonly property bool hasText: input.text.length > 0

    readonly property var dotMaterialShapes: ["clover4", "arrow", "pill", "softBurst", "diamond", "clamShell", "pentagon"]

    ListModel { id: passwordModel }

    Component {
        id: dotSquareComp
        Rectangle { width: 16; height: 16; radius: 4; color: Colors.md3.on_surface }
    }
    Component {
        id: dotCircleComp
        Rectangle { width: 16; height: 16; radius: 8; color: Colors.md3.on_surface }
    }
    Component {
        id: dotMaterialComp
        MaterialShape {
            shapeSize: 16
            immediate: true
            color: Colors.md3.on_surface
            random: true
            shapes: root.dotMaterialShapes
        }
    }

    Rectangle {
        id: box
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            right: submit.left
            rightMargin: 8
        }
        radius: height / 2
        color: Colors.md3.surface_container_lowest
        border.width: root.failed ? 2 : 1
        border.color: root.failed ? Colors.md3.error : Colors.md3.outline_variant

        transform: Translate { id: shift }

        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: shift; property: "x"; to: -12; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: shift; property: "x"; to: 12; duration: 80; easing.type: Easing.InOutQuad }
            NumberAnimation { target: shift; property: "x"; to: 0; duration: 40; easing.type: Easing.InOutQuad }
        }

        Row {
            anchors {
                left: parent.left
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
            spacing: 8
            visible: !root.hasText

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "lock"
                iconSize: 18
                color: root.failed ? Colors.md3.error : Colors.md3.on_surface_variant
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Localization.t(root.failed ? "lockSurface.incorrect_password" : "lockSurface.password")
                color: root.failed ? Colors.md3.error : Colors.md3.on_surface_variant
                font.pixelSize: 14
            }
        }

        TextInput {
            id: input
            anchors.fill: parent
            opacity: 0
            focus: true
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            enabled: !root.busy

            Component.onCompleted: {
                text = LockscreenService.currentText;
                cursorPosition = text.length;
                forceActiveFocus();
            }

            onActiveFocusChanged: {
                if (!activeFocus)
                    forceActiveFocus();
            }

            onTextChanged: {
                LockscreenService.currentText = text;

                const oldLen = passwordModel.count;
                const newLen = text.length;
                if (newLen > oldLen) {
                    const insertCount = newLen - oldLen;
                    const insertAt = Math.max(0, Math.min(oldLen, cursorPosition - insertCount));
                    for (let i = 0; i < insertCount; i++)
                        passwordModel.insert(insertAt + i, {});
                } else if (newLen < oldLen) {
                    const removeCount = oldLen - newLen;
                    const removeAt = Math.max(0, Math.min(newLen, cursorPosition));
                    for (let i = 0; i < removeCount; i++)
                        passwordModel.remove(removeAt);
                }

                textCursor.opacity = 1;
                cursorBlink.restart();
            }

            onCursorPositionChanged: {
                dots.ensureCaretVisible();
                textCursor.opacity = 1;
                cursorBlink.restart();
            }

            Keys.onReturnPressed: LockscreenService.tryUnlock()
            Keys.onEnterPressed: LockscreenService.tryUnlock()

            Connections {
                target: LockscreenService

                function onCurrentTextChanged() {
                    if (input.text !== LockscreenService.currentText)
                        input.text = LockscreenService.currentText;
                }
                function onUnlocked() {
                    SoundService.unlock();
                    input.text = "";
                }
                function onShowFailureChanged() {
                    if (LockscreenService.showFailure) {
                        SoundService.unlockFail();
                        shake.start();
                        input.text = "";
                    }
                }
            }
        }

        ListView {
            id: dots
            anchors {
                left: parent.left
                leftMargin: 16
                right: parent.right
                rightMargin: 12
                top: parent.top
                bottom: parent.bottom
            }
            clip: true
            model: passwordModel
            orientation: ListView.Horizontal
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 0

            readonly property int dotW: 16
            readonly property int dotSpacing: 6

            function caretX(idx) {
                return idx <= 0 ? 0 : idx * (dotW + dotSpacing) - dotSpacing;
            }

            function caretCenterX(idx) {
                return idx <= 0 ? 0 : idx * (dotW + dotSpacing) - dotSpacing / 2;
            }

            function ensureCaretVisible() {
                const caret = caretX(input.cursorPosition);
                let cx = contentX;
                if (caret < cx)
                    cx = caret;
                else if (caret > cx + width)
                    cx = caret - width;
                contentX = Math.max(0, Math.min(cx, Math.max(0, contentWidth - width)));
            }

            Behavior on contentX {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            onContentWidthChanged: ensureCaretVisible()

            delegate: Item {
                width: 16
                height: dots.height

                Loader {
                    id: dotVisual
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    sourceComponent: {
                        switch (Config.lockscreen.dotShape) {
                        case "circle": return dotCircleComp;
                        case "material": return dotMaterialComp;
                        default: return dotSquareComp;
                        }
                    }

                    SequentialAnimation {
                        running: root.busy
                        loops: Animation.Infinite

                        ParallelAnimation {
                            NumberAnimation { target: dotVisual; property: "opacity"; to: 0.3; duration: 750; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: dotVisual; property: "scale"; to: 0.85; duration: 750; easing.type: Easing.InOutQuad }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: dotVisual; property: "opacity"; to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: dotVisual; property: "scale"; to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }

            add: Transition {
                NumberAnimation { property: "scale"; from: 0; to: 1; duration: 160; easing.type: Easing.OutBack }
            }
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "scale"; to: 0; duration: 120; easing.type: Easing.InQuad }
                    NumberAnimation { property: "width"; to: 0; duration: 120; easing.type: Easing.InQuad }
                }
            }
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 160; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            id: textCursor
            width: 2
            height: 18
            radius: 1
            color: Colors.md3.on_surface
            visible: input.activeFocus && !root.busy && root.hasText
            anchors.verticalCenter: dots.verticalCenter
            x: {
                const idx = input.cursorPosition;
                const center = dots.caretCenterX(idx) - dots.contentX;
                const aligned = idx <= 0 ? center : center - textCursor.width / 2;
                const minX = dots.x;
                const maxX = dots.x + dots.width - textCursor.width;
                return Math.max(minX, Math.min(maxX, dots.x + aligned));
            }

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            SequentialAnimation {
                id: cursorBlink
                loops: Animation.Infinite
                running: textCursor.visible

                PauseAnimation { duration: 600 }
                NumberAnimation { target: textCursor; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InOutQuad }
                PauseAnimation { duration: 300 }
                NumberAnimation { target: textCursor; property: "opacity"; to: 1; duration: 300; easing.type: Easing.InOutQuad }
            }
        }
    }

    LockButton {
        id: submit
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        size: 44
        icon: "arrow-forward"
        readonly property bool ready: root.hasText && !root.busy
        container: ready ? Colors.md3.primary : Colors.md3.surface_container_highest
        content: ready ? Colors.md3.on_primary : Colors.md3.on_surface_variant
        onClicked: if (ready) LockscreenService.tryUnlock()
    }
}
