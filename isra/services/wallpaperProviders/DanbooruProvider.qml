pragma Singleton
import QtQuick
import "xhrJson.js" as XhrJson

QtObject {
    id: root

    readonly property string name: "Danbooru"

    function _tags(query, allowNsfw, sort) {
        const parts = [];
        if (query)
            parts.push(encodeURIComponent(query));
        if (sort === "top")
            parts.push("order:rank");
        if (!allowNsfw)
            parts.push("rating:general,sensitive");
        return parts.join("+");
    }

    function _isVideo(url) {
        return /\.(mp4|webm|zip)(\?.*)?$/i.test(url ?? "");
    }

    function _map(d) {
        const url = d.file_url ?? d.large_file_url ?? "";
        return {
            id: "danb-" + d.id,
            thumb: d.preview_file_url ?? "",
            full: url,
            width: d.image_width ?? 0,
            height: d.image_height ?? 0,
            size: d.file_size ?? 0,
            isVideo: root._isVideo(url),
            duration: d.duration ?? 0
        };
    }

    function fetchRandomUrl(allowNsfw, onUrl, onError) {
        const tags = allowNsfw ? "" : "rating:general,sensitive";
        const url = "https://danbooru.donmai.us/posts/random.json?tags=" + tags;
        XhrJson.getJson(url, json => {
            const u = json ? (json.file_url ?? json.large_file_url) : null;
            u ? onUrl(u) : onError("no results");
        }, onError);
    }

    function search(query, page, allowNsfw, sort, onResult, onError) {
        const pageParam = sort === "random" ? "&random=true" : "&page=" + page;
        const url = "https://danbooru.donmai.us/posts.json?limit=20" + pageParam + "&tags=" + root._tags(query, allowNsfw, sort);
        XhrJson.getJson(url, json => {
            const raw = json || [];
            const items = raw.filter(d => d.file_url || d.large_file_url).map(root._map);
            onResult({
                items: items,
                hasMore: sort === "random" || raw.length === 20
            });
        }, onError);
    }
}
