pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.services
import qs.style
import "lyricsFetch.js" as LyricsFetch

Singleton {
    id: root

    readonly property var player: MediaPlayerState.displayPlayer

    property int subscribers: 0
    readonly property bool active: root.subscribers > 0

    property var lines: []
    property int activeIndex: -1
    // "idle" | "loading" | "ok" | "not_found" | "no_info" | "offline" | "error"
    property string status: "idle"

    readonly property bool hasLyrics: root.status === "ok" && root.lines.length > 0

    function subscribe(): void {
        root.subscribers++;
    }

    function unsubscribe(): void {
        root.subscribers = Math.max(0, root.subscribers - 1);
    }

    function _trackKey(p): string {
        if (!p)
            return "";
        return JSON.stringify([p.dbusName ?? "", p.uniqueId ?? 0, p.trackTitle ?? "", p.trackArtist ?? "", p.trackAlbum ?? "", Math.floor(p.length ?? 0)]);
    }

    property string _trackKeyNow: root._trackKey(root.player)
    property string _loadedKey: ""

    property int _serial: 0
    property string _latestId: ""
    property var _handle: null

    readonly property int _cacheMax: 8
    property var _cache: ({})
    property var _cacheOrder: []

    function _cacheSet(key, lines): void {
        if (root._cache[key] === undefined)
            root._cacheOrder.push(key);
        root._cache = Object.assign({}, root._cache, {
            [key]: lines
        });
        while (root._cacheOrder.length > root._cacheMax) {
            const oldest = root._cacheOrder.shift();
            if (oldest === key)
                continue;
            const next = Object.assign({}, root._cache);
            delete next[oldest];
            root._cache = next;
        }
    }

    function _clear(): void {
        root.lines = [];
        root.activeIndex = -1;
        root._loadedKey = "";
        root._lastReported = -1;
        root._reanchor(0);
    }

    function _abort(): void {
        if (root._handle) {
            root._handle.abort();
            root._handle = null;
        }
    }

    function refresh(): void {
        if (!root.active) {
            root._abort();
            root.status = "idle";
            return;
        }

        const p = root.player;
        const key = root._trackKey(p);
        if (key !== "" && key === root._loadedKey && root.status === "ok")
            return;

        root._abort();
        root._clear();

        const title = p?.trackTitle ?? "";
        const artist = p?.trackArtist ?? "";
        if (!title || !artist) {
            root.status = "no_info";
            return;
        }

        const cached = root._cache[key];
        if (cached !== undefined) {
            root.lines = cached;
            root._loadedKey = key;
            root.status = cached.length > 0 ? "ok" : "not_found";
            root._reanchor(p?.position ?? 0);
            return;
        }

        if (!NetworkService.isOnline) {
            root.status = "offline";
            return;
        }

        root._serial++;
        const requestId = String(root._serial);
        root._latestId = requestId;
        root.status = "loading";

        root._handle = LyricsFetch.fetchLyrics(title, artist, p?.trackAlbum ?? "", p?.length ?? 0, Config.githubRepo, lines => {
            if (requestId !== root._latestId)
                return;
            root._handle = null;
            root._cacheSet(key, lines);
            root.lines = lines;
            root._loadedKey = key;
            root.activeIndex = -1;
            root._lastReported = -1;
            root._reanchor(root.player?.position ?? 0);
            root.status = "ok";
        }, err => {
            if (requestId !== root._latestId)
                return;
            root._handle = null;
            if (err === "not_found")
                root._cacheSet(key, []);
            root.status = err === "not_found" ? "not_found" : "error";
            if (err !== "not_found")
                console.warn("[LyricsService]", err);
        });
    }

    property real _anchorPos: 0
    property real _anchorMs: 0
    property real _lastReported: -1

    readonly property bool _playing: root.player?.playbackState === MprisPlaybackState.Playing

    function _reanchor(pos: real): void {
        root._anchorPos = pos;
        root._anchorMs = Date.now();
    }

    function position(): real {
        if (!root._playing)
            return root._anchorPos;
        return root._anchorPos + (Date.now() - root._anchorMs) / 1000;
    }

    function indexAt(pos: real): int {
        const list = root.lines;
        let idx = -1;
        for (let i = 0; i < list.length; i++) {
            if (list[i].start <= pos)
                idx = i;
            else
                break;
        }
        return idx;
    }

    on_PlayingChanged: root._reanchor(root.position())
    on_TrackKeyNowChanged: refreshDebounce.restart()
    onActiveChanged: {
        if (root.active)
            refreshDebounce.restart();
        else {
            refreshDebounce.stop();
            root._abort();
            root._clear();
            root.status = "idle";
        }
    }

    Timer {
        id: refreshDebounce
        interval: 350
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 300
        repeat: true
        running: root.active && root.hasLyrics
        onTriggered: {
            const p = root.player;
            if (!p)
                return;
            const reported = p.position ?? 0;
            if (reported !== root._lastReported) {
                root._lastReported = reported;
                if (reported > 0 || root._anchorPos === 0)
                    root._reanchor(reported);
            }
            const idx = root.indexAt(root.position());
            if (idx !== root.activeIndex)
                root.activeIndex = idx;
        }
    }

    Connections {
        target: NetworkService
        function onIsOnlineChanged(): void {
            if (NetworkService.isOnline && root.active && root.status === "offline")
                root.refresh();
        }
    }
}
