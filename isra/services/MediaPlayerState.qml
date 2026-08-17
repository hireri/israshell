pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    PersistentProperties {
        id: persist
        property string pinnedDesktopEntry: ""
    }

    readonly property var players: {
        const out = [];
        for (const p of Mpris.players.values)
            if (p.trackTitle && p.trackTitle !== "")
                out.push(p);
        return out;
    }

    property var _currentPlayer: null
    property var _pinnedPlayer: null
    property var _openScreen: null

    property var artCache: ({})
    property var _artPending: ({})

    function _artLocalPath(url) {
        if (url === "")
            return "";
        if (url.startsWith("file://"))
            return url;
        if (url.startsWith("/"))
            return "file://" + url;
        return "";
    }

    function resolvedArt(url) {
        const local = _artLocalPath(url);
        if (local !== "")
            return local;
        return artCache[url] ?? "";
    }

    function ensureArt(url) {
        if (url === "" || _artLocalPath(url) !== "" || artCache[url] || _artPending[url])
            return;
        _artPending[url] = true;
        const file = "/tmp/qs_art_" + Qt.md5(url);
        artFetchComponent.createObject(root, {
            artUrl: url,
            targetFile: file,
            command: ["bash", "-c", `f='${file}'; t="$f.tmp"; [ -f "$f" ] || { curl -4 -sSL '${url}' -o "$t" && mv "$t" "$f"; }`],
            running: true
        });
    }

    Component {
        id: artFetchComponent
        Process {
            property string artUrl: ""
            property string targetFile: ""
            onExited: code => {
                if (code === 0)
                    root.artCache = Object.assign({}, root.artCache, { [artUrl]: "file://" + targetFile });
                delete root._artPending[artUrl];
                destroy();
            }
        }
    }

    property var colorCache: ({})
    property var _colorPending: ({})
    property var _colorWanted: ({})

    function resolvedColor(url) {
        return colorCache[url] ?? null;
    }

    function ensureColors(url) {
        if (url === "")
            return;
        ensureArt(url);
        if (colorCache[url] || _colorPending[url])
            return;
        const local = resolvedArt(url);
        if (local === "") {
            _colorWanted[url] = true;
            return;
        }
        delete _colorWanted[url];
        _colorPending[url] = true;
        colorFetchComponent.createObject(root, { artUrl: url, source: local });
    }

    onArtCacheChanged: {
        for (const url in _colorWanted) {
            if (resolvedArt(url) !== "")
                ensureColors(url);
        }
    }

    Component {
        id: colorFetchComponent
        ColorQuantizer {
            id: quantizer
            property string artUrl: ""
            depth: 2
            rescaleSize: 8
            onColorsChanged: {
                if (colors && colors.length > 0) {
                    let best = colors[0];
                    for (const c of colors)
                        if (c.hslSaturation > best.hslSaturation)
                            best = c;
                    root.colorCache = Object.assign({}, root.colorCache, { [artUrl]: best });
                }
                delete root._colorPending[artUrl];
                destroy();
            }
        }
    }

    onPlayersChanged: {
        if (players.length === 0) {
            _currentPlayer = null;
            _pinnedPlayer = null;
            _openScreen = null;
            return;
        }

        if (players.length < 2) {
            _pinnedPlayer = null;
        } else {
            if (_pinnedPlayer === null && persist.pinnedDesktopEntry !== "") {
                for (const p of players) {
                    if ((p.desktopEntry ?? "") === persist.pinnedDesktopEntry) {
                        _pinnedPlayer = p;
                        break;
                    }
                }
            }
            if (_pinnedPlayer === null && persist.pinnedDesktopEntry === "") {
                _pinnedPlayer = _currentPlayer ?? players[0];
                persist.pinnedDesktopEntry = _pinnedPlayer?.desktopEntry ?? "";
            }
        }

        if (_currentPlayer === null || players.indexOf(_currentPlayer) === -1) {
            _currentPlayer = _pinnedPlayer ?? players[0];
            playerChangedSilently(_currentPlayer);
        }
    }

    readonly property var currentPlayer: _currentPlayer
    readonly property var pinnedPlayer: _pinnedPlayer
    readonly property var openScreen: _openScreen

    readonly property var displayPlayer: {
        if (_pinnedPlayer !== null && players.indexOf(_pinnedPlayer) !== -1)
            return _pinnedPlayer;
        if (_currentPlayer !== null && players.indexOf(_currentPlayer) !== -1)
            return _currentPlayer;
        return players[0] ?? null;
    }

    signal playerSwitched(var oldPlayer, var newPlayer)
    signal playerChangedSilently(var newPlayer)

    function toggle(screen) {
        if (_openScreen === screen)
            close();
        else
            open(screen);
    }

    function open(screen) {
        _openScreen = screen;
        const pinValid = _pinnedPlayer !== null && players.indexOf(_pinnedPlayer) !== -1;
        if (pinValid) {
            if (_currentPlayer !== _pinnedPlayer) {
                _currentPlayer = _pinnedPlayer;
                playerChangedSilently(_currentPlayer);
            }
        } else if (_currentPlayer === null || players.indexOf(_currentPlayer) === -1) {
            _currentPlayer = players[0] ?? null;
            playerChangedSilently(_currentPlayer);
        }
    }

    function close() {
        _openScreen = null;
    }

    function switchTo(player) {
        if (player === _currentPlayer)
            return;
        if (players.indexOf(player) === -1)
            return;
        const old = _currentPlayer;
        _currentPlayer = player;
        playerSwitched(old, player);
    }

    function pin(player) {
        if (players.indexOf(player) === -1)
            return;
        _pinnedPlayer = player;
        persist.pinnedDesktopEntry = player.desktopEntry ?? "";
    }

    Component.onCompleted: {
        _currentPlayer = players[0] ?? null;
    }

    IpcHandler {
        target: "media"
        function next() {
            root.displayPlayer?.next();
        }
        function previous() {
            root.displayPlayer?.previous();
        }
        function togglePlaying() {
            root.displayPlayer?.togglePlaying();
        }
        function play() {
            root.displayPlayer?.play();
        }
        function pause() {
            root.displayPlayer?.pause();
        }
    }
}
