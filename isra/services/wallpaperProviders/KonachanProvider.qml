pragma Singleton
import QtQuick
import "xhrJson.js" as XhrJson

QtObject {
    id: root

    readonly property string name: "Konachan"

    function _tags(query, allowNsfw, sort) {
        const parts = [];
        if (query)
            parts.push(encodeURIComponent(query));
        if (sort === "top")
            parts.push("order:score");
        else if (sort === "random")
            parts.push("order:random");
        if (!allowNsfw)
            parts.push("rating:s");
        return parts.join("+");
    }

    function _map(d) {
        return {
            id: "kona-" + d.id,
            thumb: d.preview_url,
            full: d.file_url,
            width: d.width ?? 0,
            height: d.height ?? 0,
            size: d.file_size ?? 0
        };
    }

    function fetchRandomUrl(allowNsfw, onUrl, onError) {
        const url = "https://konachan.com/post.json?limit=1&tags=" + root._tags("", allowNsfw, "random");
        XhrJson.getJson(url, json => {
            const u = (json && json.length > 0) ? json[0].file_url : null;
            u ? onUrl(u) : onError("no results");
        }, onError);
    }

    function search(query, page, allowNsfw, sort, onResult, onError) {
        const url = "https://konachan.com/post.json?limit=20&page=" + page + "&tags=" + root._tags(query, allowNsfw, sort);
        XhrJson.getJson(url, json => {
            const items = (json || []).map(root._map);
            onResult({
                items: items,
                hasMore: items.length === 20
            });
        }, onError);
    }
}
