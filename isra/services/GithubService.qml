pragma Singleton
import QtQuick
import Quickshell
import qs.style
import qs.services

Singleton {
    id: root

    // { [username]: { loading, error, totalContributions, weeks, fetchedAt } }
    property var _cache: ({})

    function _emptyState() {
        return { loading: false, error: "", totalContributions: 0, weeks: [], fetchedAt: 0 };
    }

    function stateFor(username: string): var {
        return root._cache[username] ?? root._emptyState();
    }

    function ensureFetched(username: string): void {
        if (!username)
            return;
        const s = root._cache[username];
        if (s && (s.loading || s.fetchedAt > 0))
            return;
        root._fetch(username);
    }

    function refresh(username: string): void {
        if (!username)
            return;
        root._fetch(username);
    }

    function _setState(username, patch) {
        const merged = {};
        for (const k in root._cache)
            merged[k] = root._cache[k];
        merged[username] = Object.assign({}, root.stateFor(username), patch);
        root._cache = merged;
    }

    function _fetch(username) {
        if (!NetworkService.isOnline) {
            root._setState(username, { loading: false, error: "offline" });
            return;
        }

        root._setState(username, { loading: true, error: "" });

        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://github-contributions-api.jogruber.de/v4/" + encodeURIComponent(username) + "?y=last");
        xhr.timeout = 15000;
        xhr.setRequestHeader("Accept", "application/json");
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 404) {
                root._setState(username, { loading: false, error: "user_not_found" });
                return;
            }
            if (xhr.status !== 200) {
                root._setState(username, { loading: false, error: "fetch_failed" });
                console.warn("[GithubService] fetch failed:", xhr.status);
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                if (!data.contributions || !data.total) {
                    root._setState(username, { loading: false, error: "parse_error" });
                    return;
                }

                const rawContributions = data.contributions;
                const weeks = [];
                let currentWeek = [];

                for (let i = 0; i < rawContributions.length; i++) {
                    const item = rawContributions[i];
                    const dateObj = new Date(item.date);
                    
                    currentWeek.push({
                        contributionCount: item.count,
                        date: item.date,
                        weekday: dateObj.getUTCDay(),
                        color: item.color
                    });

                    if (currentWeek.length === 7 || i === rawContributions.length - 1) {
                        weeks.push({ contributionDays: currentWeek });
                        currentWeek = [];
                    }
                }

                const currentYear = new Date().getFullYear().toString();
                const totalContributions = data.total[currentYear] ?? Object.values(data.total)[0] ?? 0;

                root._setState(username, {
                    loading: false,
                    error: "",
                    totalContributions: totalContributions,
                    weeks: weeks,
                    fetchedAt: Date.now()
                });
            } catch (e) {
                root._setState(username, { loading: false, error: "parse_error" });
                console.warn("[GithubService] parse error:", e);
            }
        };
        xhr.send();
    }

    Connections {
        target: NetworkService
        function onIsOnlineChanged() {
            if (NetworkService.isOnline) {
                for (const u in root._cache)
                    root._fetch(u);
            }
        }
    }

    Timer {
        interval: 45 * 60 * 1000
        running: NetworkService.isOnline
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            for (const u in root._cache)
                root._fetch(u);
        }
    }
}