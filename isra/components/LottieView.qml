import QtQuick
import Qt.labs.lottieqt

Item {
    id: root

    property string animationSource: ""

    LottieAnimation {
        anchors.fill: parent
        source: root.animationSource
        loops: LottieAnimation.Infinite
        autoPlay: true
    }
}
