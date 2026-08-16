import QtQuick
import qs.style
import qs.services

Item {
    id: root

    property int code: 0
    property bool isDay: true
    property string overlayName: ""

    readonly property string animationPath: root.overlayName !== "" ? WeatherAssets.overlayPathByName(root.overlayName) : WeatherAssets.overlayPath(root.code, root.isDay)

    readonly property bool wanted: (Config.weather?.animatedOverlays ?? false) && root.animationPath !== ""

    readonly property bool active: loader.status === Loader.Ready
    readonly property bool failed: loader.status === Loader.Error

    Loader {
        id: loader
        anchors.fill: parent
        source: root.wanted ? Qt.resolvedUrl("LottieView.qml") : ""
        asynchronous: true

        onStatusChanged: {
            if (loader.status === Loader.Error)
                console.warn("[WeatherOverlay] lottie unavailable; falling back to the static scene");
        }
    }

    Binding {
        target: loader.item
        property: "animationSource"
        value: "file://" + root.animationPath
        when: loader.status === Loader.Ready
    }
}
