pragma Singleton
import QtQuick
import Quickshell
import qs.style

Singleton {
    id: root

    readonly property bool running: Config.pomodoro.running
    readonly property var steps: (Config.pomodoro.steps && Config.pomodoro.steps.length > 0) ? Config.pomodoro.steps : root._fallbackSteps
    readonly property var _fallbackSteps: [{ focusMinutes: 25, breakType: "short_break", breakMinutes: 5 }]

    readonly property var phases: {
        const result = [];
        for (const s of root.steps) {
            result.push({ type: "focus", minutes: s.focusMinutes });
            result.push({ type: s.breakType, minutes: s.breakMinutes });
        }
        return result;
    }

    readonly property int phaseIndex: Math.max(0, Math.min(root.phases.length - 1, Config.pomodoro.phaseIndex ?? 0))
    readonly property var currentPhase: root.phases[root.phaseIndex]
    readonly property string stepType: root.currentPhase.type

    readonly property int cycleIndex: Math.floor(root.phaseIndex / 2) + 1
    readonly property int cycleTotal: root.steps.length

    property int remainingMs: Config.pomodoro.remainingMs

    readonly property real progress: {
        const total = root._durationMs(root.currentPhase);
        return total > 0 ? Math.max(0, Math.min(1, 1 - root.remainingMs / total)) : 0;
    }

    function _durationMs(phase) {
        return Math.max(1, phase.minutes) * 60 * 1000;
    }

    function _patch(changes) {
        Config.update({ pomodoro: Object.assign({}, Config.pomodoro, changes) });
    }

    function _recompute() {
        if (!root.running)
            return;
        const remaining = Config.pomodoro.endTimestamp - Date.now();
        if (remaining <= 0) {
            root._advancePhase();
            return;
        }
        root.remainingMs = remaining;
    }

    function _advancePhase() {
        const nextIndex = (root.phaseIndex + 1) % root.phases.length;
        const duration = root._durationMs(root.phases[nextIndex]);
        root.remainingMs = duration;
        root._patch({ phaseIndex: nextIndex, endTimestamp: Date.now() + duration, running: true });
    }

    function resume(): void {
        if (root.running)
            return;
        root._patch({ endTimestamp: Date.now() + root.remainingMs, running: true });
    }

    function pause(): void {
        if (!root.running)
            return;
        root._recompute();
        root._patch({ running: false, remainingMs: root.remainingMs });
    }

    function toggle(): void {
        if (root.running)
            root.pause();
        else
            root.resume();
    }

    function skip(): void {
        root._advancePhase();
    }

    function restart(): void {
        const duration = root._durationMs(root.currentPhase);
        root.remainingMs = duration;
        if (root.running)
            root._patch({ endTimestamp: Date.now() + duration });
        else
            root._patch({ remainingMs: duration });
    }

    function setSteps(steps): void {
        const phaseCount = steps.length * 2;
        const clampedIndex = Math.min(Config.pomodoro.phaseIndex ?? 0, phaseCount - 1);
        const s = steps[Math.floor(clampedIndex / 2)];
        const duration = root._durationMs(clampedIndex % 2 === 0 ? { minutes: s.focusMinutes } : { minutes: s.breakMinutes });
        root.remainingMs = duration;
        root._patch({ steps: steps, phaseIndex: clampedIndex, running: false, endTimestamp: 0, remainingMs: duration });
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: root._recompute()
    }

    Component.onCompleted: root._recompute()
}
