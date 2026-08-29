.pragma library

const API = "https://lrclib.net/api";
const TIMEOUT = 12000;

const STAMP = /\[(\d{1,3}):(\d{2}(?:[.:]\d{1,3})?)\]/g;
const VOICE = /^(?:v1:|v2:|M:|F:)\s*/i;

function _normalize(value) {
    return String(value ?? "").toLowerCase().replace(/[^\w\s]/g, " ").trim();
}

function _overlaps(wanted, got) {
    const a = _normalize(wanted);
    const b = _normalize(got);
    if (!a || !b)
        return false;
    if (a.indexOf(b) !== -1 || b.indexOf(a) !== -1)
        return true;
    const words = a.split(/\s+/).filter(w => w.length > 3);
    const other = b.split(/\s+/);
    return words.some(w => other.indexOf(w) !== -1);
}

function _looksLike(candidate, title, artist) {
    if (!candidate || !candidate.syncedLyrics)
        return false;
    return _overlaps(title, candidate.trackName) && _overlaps(artist, candidate.artistName);
}

function _synthWords(text, start, end) {
    const raw = String(text ?? "").split(/(\s+)/).filter(s => s.length > 0);
    const words = [];
    let weightTotal = 0;
    for (const chunk of raw) {
        if (/^\s+$/.test(chunk)) {
            if (words.length > 0)
                words[words.length - 1].text += chunk;
            continue;
        }
        const weight = Math.max(1, chunk.length);
        words.push({ text: chunk, weight: weight, start: 0, end: 0 });
        weightTotal += weight;
    }
    if (words.length === 0 || !(end > start) || weightTotal <= 0)
        return words.map(w => ({ text: w.text, start: start, end: end > start ? end : start }));
    const span = end - start;
    let cursor = start;
    return words.map(w => {
        const dur = span * (w.weight / weightTotal);
        const out = { text: w.text, start: cursor, end: cursor + dur };
        cursor += dur;
        return out;
    });
}

function parseLrc(lrc) {
    const flat = [];
    for (const raw of String(lrc ?? "").split("\n")) {
        STAMP.lastIndex = 0;
        const stamps = [];
        let m;
        while ((m = STAMP.exec(raw)) !== null)
            stamps.push(m);
        if (stamps.length === 0)
            continue;

        const last = stamps[stamps.length - 1];
        let text = raw.slice(last.index + last[0].length).trim();

        let align = null;
        const voice = text.match(VOICE);
        if (voice) {
            const tag = voice[0].toLowerCase();
            align = (tag.indexOf("v2") === 0 || tag.indexOf("f:") === 0) ? "right" : "left";
            text = text.slice(voice[0].length).trim();
        }

        for (const stamp of stamps) {
            const minutes = parseInt(stamp[1], 10);
            const seconds = parseFloat(stamp[2].replace(":", "."));
            flat.push({ start: minutes * 60 + seconds, text: text, align: align });
        }
    }

    flat.sort((a, b) => a.start - b.start);

    return flat.map((line, i) => {
        const end = i + 1 < flat.length ? flat[i + 1].start : line.start;
        return {
            start: line.start,
            end: end,
            text: line.text,
            align: line.align,
            words: _synthWords(line.text, line.start, end)
        };
    });
}

function _getJson(url, ua, onOk, onFail) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.setRequestHeader("User-Agent", ua);
    xhr.setRequestHeader("Accept", "application/json");
    xhr.timeout = TIMEOUT;
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return;
        if (xhr.status === 404) {
            onOk(null);
            return;
        }
        if (xhr.status !== 200) {
            onFail("http_" + xhr.status);
            return;
        }
        try {
            onOk(JSON.parse(xhr.responseText));
        } catch (e) {
            onFail("parse_error");
        }
    };
    xhr.send();
    return xhr;
}

function fetchLyrics(title, artist, album, duration, repo, onOk, onFail) {
    const q = encodeURIComponent;
    const ua = `isra-shell (https://github.com/${repo})`;
    const attempts = [];
    if (album && duration > 0)
        attempts.push(`${API}/get?track_name=${q(title)}&artist_name=${q(artist)}&album_name=${q(album)}&duration=${Math.floor(duration)}`);
    attempts.push(`${API}/search?track_name=${q(title)}&artist_name=${q(artist)}`);
    attempts.push(`${API}/search?q=${q(title + " " + artist)}`);

    const handle = { aborted: false, xhr: null };
    handle.abort = function () {
        handle.aborted = true;
        if (handle.xhr)
            handle.xhr.abort();
    };

    let index = 0;
    let lastError = "";

    function next() {
        if (handle.aborted)
            return;
        if (index >= attempts.length) {
            onFail(lastError || "not_found");
            return;
        }
        const url = attempts[index++];
        handle.xhr = _getJson(url, ua, payload => {
            if (handle.aborted)
                return;
            const candidates = payload === null ? [] : (Array.isArray(payload) ? payload : [payload]);
            for (const candidate of candidates) {
                if (!_looksLike(candidate, title, artist))
                    continue;
                const lines = parseLrc(candidate.syncedLyrics);
                if (lines.length > 0) {
                    onOk(lines);
                    return;
                }
            }
            next();
        }, err => {
            if (handle.aborted)
                return;
            lastError = err;
            next();
        });
    }

    next();
    return handle;
}
