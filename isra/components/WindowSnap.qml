import QtQuick
import Quickshell.Wayland

Loader {
    id: snap

    required property var rect
    required property real dpr
    property bool go: false
    property bool finished: false

    readonly property string key: `${rect.x},${rect.y},${rect.w},${rect.h}`

    signal saved(string key, string path)
    signal done

    function finish() {
        if (finished)
            return;
        finished = true;
        done();
    }

    active: go && !finished
    width: rect.win.w * dpr
    height: rect.win.h * dpr

    Timer {
        running: snap.active
        interval: 1500
        onTriggered: snap.finish()
    }

    sourceComponent: ScreencopyView {
        captureSource: snap.rect.toplevel
        live: false
        onHasContentChanged: if (hasContent)
            Qt.callLater(() => grabToImage(res => {
                    const path = `/tmp/qs-win-${Date.now()}-${Math.floor(Math.random() * 1e6)}.bmp`;
                    if (res.saveToFile(path))
                        snap.saved(snap.key, path);
                    snap.finish();
                }))
    }
}
