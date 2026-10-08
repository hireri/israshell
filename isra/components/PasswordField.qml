pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.icons

Item {
    id: root

    property string placeholder: ""
    property bool error: false
    property bool busy: false
    property bool locked: false
    property bool revealable: false
    property bool revealed: false
    property alias text: input.text
    readonly property bool hasText: input.text.length > 0

    signal accepted

    implicitWidth: 260
    implicitHeight: 44

    function focusInput() {
        input.forceActiveFocus();
    }

    onLockedChanged: if (locked) input.text = ""

    function clear() {
        input.text = "";
        revealed = false;
    }

    function shake() {
        shakeAnim.restart();
    }

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
            shapes: ["clover4", "arrow", "pill", "softBurst", "diamond", "clamShell", "pentagon"]
        }
    }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: height / 2
        color: root.locked ? Qt.alpha(Colors.md3.on_surface, 0.08) : Colors.md3.surface_container_lowest
        border.width: root.error && !root.locked ? 2 : 1
        border.color: root.locked ? "transparent" : root.error ? Colors.md3.error : Colors.md3.outline_variant
        clip: true

        transform: Translate { id: shift }

        SequentialAnimation {
            id: shakeAnim
            loops: 2
            NumberAnimation { target: shift; property: "x"; to: -12; duration: 40; easing.type: Easing.InOutQuad }
            NumberAnimation { target: shift; property: "x"; to: 12; duration: 80; easing.type: Easing.InOutQuad }
            NumberAnimation { target: shift; property: "x"; to: 0; duration: 40; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.locked ? Qt.ArrowCursor : Qt.IBeamCursor
            onClicked: input.forceActiveFocus()
        }

        Row {
            anchors {
                left: parent.left
                leftMargin: 16 + (textCursor.visible ? 10 : 0)
                verticalCenter: parent.verticalCenter
            }
            Behavior on anchors.leftMargin {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
            spacing: 8
            visible: !root.hasText

            MaterialIcon {
                transitionType: "none"
                anchors.verticalCenter: parent.verticalCenter
                name: "lock"
                iconSize: 18
                color: root.locked ? Qt.alpha(Colors.md3.on_surface, 0.38) : root.error ? Colors.md3.error : Colors.md3.on_surface_variant
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.placeholder
                color: root.locked ? Qt.alpha(Colors.md3.on_surface, 0.38) : root.error ? Colors.md3.error : Colors.md3.on_surface_variant
                font.family: Config.fontFamily
                font.pixelSize: 14
            }
        }

        TextInput {
            id: input
            anchors {
                left: parent.left
                leftMargin: 16
                right: parent.right
                rightMargin: root.revealable ? 44 : 12
                verticalCenter: parent.verticalCenter
            }
            opacity: root.revealed ? 1 : 0
            echoMode: root.revealed ? TextInput.Normal : TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            enabled: !root.busy && !root.locked
            color: Colors.md3.on_surface
            selectionColor: Colors.md3.primary
            selectedTextColor: Colors.md3.on_primary
            font.family: Config.fontFamily
            font.pixelSize: 14
            clip: true

            onTextChanged: {
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

            Keys.onReturnPressed: root.accepted()
            Keys.onEnterPressed: root.accepted()
        }

        ListView {
            id: dots
            anchors {
                left: parent.left
                leftMargin: 16
                right: parent.right
                rightMargin: root.revealable ? 44 : 12
                top: parent.top
                bottom: parent.bottom
            }
            visible: !root.revealed
            clip: true
            model: passwordModel
            orientation: ListView.Horizontal
            spacing: 6
            interactive: false
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
                NumberAnimation { property: "scale"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
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
            visible: input.activeFocus && !root.busy && !root.revealed && !root.locked
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

        Rectangle {
            visible: root.revealable && root.hasText
            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            width: 30
            height: 30
            radius: 15
            color: revealMa.containsMouse ? Colors.md3.secondary_container : "transparent"

            MaterialIcon {
                transitionType: "none"
                anchors.centerIn: parent
                name: root.revealed ? "visibility-off" : "visibility"
                iconSize: 17
                color: Colors.md3.on_surface_variant
            }

            MouseArea {
                id: revealMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.revealed = !root.revealed
            }
        }
    }
}
