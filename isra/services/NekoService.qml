pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.style

// ported from https://github.com/adryd325/oneko.js
Singleton {
    id: root

    readonly property bool enabled: Config.neko.enabled && CompositorService.hasCapability("cursorPosition")

    property real x: 400
    property real y: 400

    property int frameCount: 0
    property int idleTime: 0
    property string idleAnimation: ""
    property int idleAnimationFrame: 0

    property int spriteCol: 3
    property int spriteRow: 3

    property bool _seeded: false

    property var spriteNames: []

    readonly property var spriteSets: ({
            idle: [[3, 3]],
            alert: [[7, 3]],
            scratchSelf: [[5, 0], [6, 0], [7, 0]],
            scratchWallN: [[0, 0], [0, 1]],
            scratchWallS: [[7, 1], [6, 2]],
            scratchWallE: [[2, 2], [2, 3]],
            scratchWallW: [[4, 0], [4, 1]],
            tired: [[3, 2]],
            sleeping: [[2, 0], [2, 1]],
            N: [[1, 2], [1, 3]],
            NE: [[0, 2], [0, 3]],
            E: [[3, 0], [3, 1]],
            SE: [[5, 1], [5, 2]],
            S: [[6, 3], [7, 2]],
            SW: [[5, 3], [6, 1]],
            W: [[4, 2], [4, 3]],
            NW: [[1, 0], [1, 1]]
        })

    function _bounds() {
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const s of Quickshell.screens) {
            minX = Math.min(minX, s.x);
            minY = Math.min(minY, s.y);
            maxX = Math.max(maxX, s.x + s.width);
            maxY = Math.max(maxY, s.y + s.height);
        }
        if (!isFinite(minX))
            return ({
                minX: 0,
                minY: 0,
                maxX: 1920,
                maxY: 1080
            });
        return ({
            minX,
            minY,
            maxX,
            maxY
        });
    }

    function _setSprite(name, frameIndex) {
        const set = root.spriteSets[name];
        const cell = set[frameIndex % set.length];
        root.spriteCol = cell[0];
        root.spriteRow = cell[1];
    }

    function _resetIdleAnimation() {
        root.idleAnimation = "";
        root.idleAnimationFrame = 0;
    }

    function _idle() {
        root.idleTime += 1;

        const b = root._bounds();
        const edge = Config.neko.size;

        if (root.idleTime > 10 && Math.floor(Math.random() * 200) === 0 && root.idleAnimation === "") {
            const available = ["sleeping", "scratchSelf"];
            if (root.x < b.minX + edge)
                available.push("scratchWallW");
            if (root.y < b.minY + edge)
                available.push("scratchWallN");
            if (root.x > b.maxX - edge)
                available.push("scratchWallE");
            if (root.y > b.maxY - edge)
                available.push("scratchWallS");
            root.idleAnimation = available[Math.floor(Math.random() * available.length)];
        }

        switch (root.idleAnimation) {
        case "sleeping":
            if (root.idleAnimationFrame < 8) {
                root._setSprite("tired", 0);
                break;
            }
            root._setSprite("sleeping", Math.floor(root.idleAnimationFrame / 4));
            if (root.idleAnimationFrame > 192)
                root._resetIdleAnimation();
            break;
        case "scratchWallN":
        case "scratchWallS":
        case "scratchWallE":
        case "scratchWallW":
        case "scratchSelf":
            root._setSprite(root.idleAnimation, root.idleAnimationFrame);
            if (root.idleAnimationFrame > 9)
                root._resetIdleAnimation();
            break;
        default:
            root._setSprite("idle", 0);
            return;
        }
        root.idleAnimationFrame += 1;
    }

    function _step() {
        if (!root._seeded) {
            root._seeded = true;
            root.x = CursorService.x;
            root.y = CursorService.y;
        }

        root.frameCount += 1;

        const mouseX = CursorService.x;
        const mouseY = CursorService.y;

        const diffX = root.x - mouseX;
        const diffY = root.y - mouseY;
        const distance = Math.hypot(diffX, diffY);

        const catchDistance = Math.max(48, Config.neko.size * 1.5);

        if (distance < Config.neko.speed || distance < catchDistance) {
            root._idle();
            return;
        }

        root.idleAnimation = "";
        root.idleAnimationFrame = 0;

        if (root.idleTime > 1) {
            root._setSprite("alert", 0);
            root.idleTime = Math.min(root.idleTime, 7);
            root.idleTime -= 1;
            return;
        }

        let direction = "";
        direction += diffY / distance > 0.5 ? "N" : "";
        direction += diffY / distance < -0.5 ? "S" : "";
        direction += diffX / distance > 0.5 ? "W" : "";
        direction += diffX / distance < -0.5 ? "E" : "";
        root._setSprite(direction, root.frameCount);

        const b = root._bounds();
        const half = Config.neko.size / 2;

        root.x = Math.min(Math.max(b.minX + half, root.x - (diffX / distance) * Config.neko.speed), b.maxX - half);
        root.y = Math.min(Math.max(b.minY + half, root.y - (diffY / distance) * Config.neko.speed), b.maxY - half);
    }

    onEnabledChanged: {
        if (enabled) {
            CursorService.acquire();
        } else {
            CursorService.release();
            root._seeded = false;
            root.idleTime = 0;
            root._resetIdleAnimation();
            root.spriteCol = 3;
            root.spriteRow = 3;
        }
    }

    function _refreshSpriteNames() {
        spriteListProc.running = false;
        spriteListProc.running = true;
    }

    Process {
        id: spriteListProc
        command: ["bash", "-c", "find " + JSON.stringify(Quickshell.shellDir + "/assets/sprites") + " -maxdepth 1 -type f -iname '*.gif' -printf '%f\\n' | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.spriteNames = text.trim().split("\n").filter(l => l.trim()).map(f => f.replace(/\.gif$/i, ""));
            }
        }
    }

    Component.onCompleted: {
        if (enabled)
            CursorService.acquire();
        root._refreshSpriteNames();
    }

    Timer {
        id: tick
        interval: 100
        repeat: true
        running: root.enabled
        onTriggered: root._step()
    }
}
