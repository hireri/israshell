pragma Singleton
import Quickshell

Singleton {
    id: root

    property var openScreen: null

    signal openRequested(var screen, real localX, real localY)

    function open(screen, localX, localY) {
        root.openScreen = screen;
        root.openRequested(screen, localX, localY);
    }

    function close() {
        root.openScreen = null;
    }
}
