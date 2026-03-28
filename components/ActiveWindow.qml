import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

import qs.style

Item {
    id: root
    readonly property int maxTextWidth: 450
    readonly property var activeWindow: Hyprland.toplevels.values.find(t => t.activated)

    implicitWidth: leftContent.implicitWidth + 20
    height: 32

    property bool layerA: true

    property string iconSourceA: ""
    property string iconSourceB: ""
    property string textAppIdA: ""
    property string textTitleA: ""
    property string textAppIdB: ""
    property string textTitleB: ""
    property string displayedAppId: ""

    function getAppId(w) {
        if (!w)
            return "";
        return w.wayland?.appId || w.lastIpcObject?.class || w.lastIpcObject?.initialClass || "";
    }

    function getIconSource(appId) {
        if (!appId)
            return "";

        if (appId.startsWith("steam_app_")) {
            return "image://icon/" + appId + "?fallback=steam";
        }

        return "image://icon/" + appId + "?fallback=application-x-executable";
    }

    function updateWindowInfo() {
        const w = activeWindow;
        const newAppId = getAppId(w);
        const newTitle = w ? (w.title ?? "") : "";
        const newSource = getIconSource(newAppId);

        displayedAppId = newAppId;

        if (layerA) {
            iconSourceB = newSource;
            textAppIdB = newAppId;
            textTitleB = newTitle;
        } else {
            iconSourceA = newSource;
            textAppIdA = newAppId;
            textTitleA = newTitle;
        }

        layerA = !layerA;
        crossfade.restart();
    }

    onActiveWindowChanged: updateWindowInfo()

    Connections {
        target: activeWindow || null
        ignoreUnknownSignals: true

        function onTitleChanged() {
            if (layerA)
                textTitleA = activeWindow.title;
            else
                textTitleB = activeWindow.title;
        }

        function onWaylandChanged() {
            const newAppId = getAppId(activeWindow);
            const newSource = getIconSource(newAppId);
            displayedAppId = newAppId;

            if (layerA) {
                textAppIdA = newAppId;
                iconSourceA = newSource;
            } else {
                textAppIdB = newAppId;
                iconSourceB = newSource;
            }
        }
    }

    Component.onCompleted: {
        const w = activeWindow;
        const initAppId = getAppId(w);
        displayedAppId = initAppId;
        iconSourceA = getIconSource(initAppId);
        textAppIdA = initAppId;
        textTitleA = w?.title ?? "";
    }

    ParallelAnimation {
        id: crossfade
        NumberAnimation {
            target: iconA
            property: "opacity"
            to: layerA ? 1 : 0
            duration: 180
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: iconB
            property: "opacity"
            to: layerA ? 0 : 1
            duration: 180
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: textColA
            property: "opacity"
            to: layerA ? 1 : 0
            duration: 180
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: textColB
            property: "opacity"
            to: layerA ? 0 : 1
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        id: leftContent
        anchors.centerIn: parent
        spacing: 8

        ClippingRectangle {
            implicitWidth: 32
            implicitHeight: 32
            anchors.verticalCenter: parent.verticalCenter
            radius: 10

            IconImage {
                id: iconA
                anchors.fill: parent
                source: iconSourceA
                opacity: 1
            }
            IconImage {
                id: iconB
                anchors.fill: parent
                source: iconSourceB
                opacity: 0
            }

            Text {
                anchors.centerIn: parent
                text: displayedAppId ? displayedAppId.charAt(0).toUpperCase() : ""
                color: Colors.md3.on_secondary_container
                font.pixelSize: 14
                font.family: Config.fontFamily
                font.weight: Font.Medium
                visible: (layerA ? iconA : iconB).status !== Image.Ready
            }
        }

        Item {
            id: textContainer
            anchors.verticalCenter: parent.verticalCenter
            height: textColA.implicitHeight
            clip: true

            width: {
                const activeW = layerA ? Math.max(appIdTextA.implicitWidth, titleTextA.implicitWidth) : Math.max(appIdTextB.implicitWidth, titleTextB.implicitWidth);
                return Math.min(activeW, maxTextWidth);
            }

            Behavior on width {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutQuad
                }
            }

            Column {
                id: textColA
                width: textContainer.width
                opacity: 1

                Text {
                    id: appIdTextA
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 10
                    font.family: Config.fontFamily
                    text: textAppIdA
                }
                Text {
                    id: titleTextA
                    color: Colors.md3.on_surface
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    text: textTitleA
                }
            }

            Column {
                id: textColB
                width: textContainer.width
                opacity: 0

                Text {
                    id: appIdTextB
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 10
                    font.family: Config.fontFamily
                    text: textAppIdB
                }
                Text {
                    id: titleTextB
                    color: Colors.md3.on_surface
                    font.pixelSize: 12
                    font.family: Config.fontFamily
                    text: textTitleB
                }
            }
        }
    }
}
