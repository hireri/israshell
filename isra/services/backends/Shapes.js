.pragma library

function emptyMonitor() {
    return { name: "", id: -1, activeWorkspaceId: -1, activeWorkspaceHasFullscreen: false };
}

function emptyWindow(extra) {
    return Object.assign({ address: "", title: "", appId: "", workspace: -1, fullscreen: false }, extra || {});
}

function emptyWorkspace(extra) {
    return Object.assign({ id: -1, name: "", monitor: "", windows: 0, active: false, hasFullscreen: false }, extra || {});
}
