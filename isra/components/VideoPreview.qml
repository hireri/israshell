import QtQuick
import Quickshell
import Quickshell.Io
import "videoPreview.js" as Jobs

QtObject {
    id: root

    property string path
    property bool active: true

    property string frame
    property real duration: 0

    property bool _requested: false
    property int _attempts: 0

    onPathChanged: {
        root.frame = "";
        root.duration = 0;
        root._requested = false;
        root._attempts = 0;
        root._ensure();
    }
    onActiveChanged: root._ensure()
    Component.onCompleted: root._ensure()

    function _ensure() {
        if (!root.path || !root.active || root._requested)
            return;
        root._requested = true;
        const video = root.path;
        Jobs.request(() => root._start(video));
    }

    function _start(video) {
        if (video !== root.path) {
            Jobs.release();
            return;
        }
        job.createObject(root, { video: video }).running = true;
    }

    function _done(video, output) {
        Jobs.release();
        if (video !== root.path)
            return;
        const lines = output.trim().split("\n");
        const frame = (lines[0] ?? "").trim();
        const dur = parseFloat(lines[1]);
        if (!isNaN(dur))
            root.duration = dur;
        if (frame) {
            root.frame = frame;
        } else if (root._attempts < 1) {
            root._attempts++;
            root._requested = false;
            Qt.callLater(root._ensure);
        }
    }

    property Component _job: Component {
        id: job

        Process {
            id: proc
            required property string video
            command: ["bash", Quickshell.shellDir + "/scripts/video-frame.sh", proc.video]
            stdout: StdioCollector {
                onStreamFinished: {
                    root._done(proc.video, text);
                    proc.destroy();
                }
            }
        }
    }
}
