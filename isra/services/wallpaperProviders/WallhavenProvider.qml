pragma Singleton
import QtQuick
import "xhrJson.js" as XhrJson

QtObject {
    id: root

    readonly property string name: "Wallhaven"

    function _purity(allowNsfw) {
        return allowNsfw ? "110" : "100";
    }

    function _sorting(sort) {
        if (sort === "random")
            return "random";
        if (sort === "new")
            return "date_added";
        return "toplist";
    }

    function _map(d) {
        return {
            id: "wh-" + d.id,
            thumb: d.thumbs.small,
            full: d.path,
            width: d.dimension_x ?? 0,
            height: d.dimension_y ?? 0,
            size: d.file_size ?? 0
        };
    }

    function fetchRandomUrl(allowNsfw, onUrl, onError) {
        const url = "https://wallhaven.cc/api/v1/search?sorting=random&purity=" + root._purity(allowNsfw);
        XhrJson.getJson(url, json => {
            const u = (json.data && json.data.length > 0) ? json.data[0].path : null;
            u ? onUrl(u) : onError("no results");
        }, onError);
    }

    function search(query, page, allowNsfw, sort, onResult, onError) {
        const url = "https://wallhaven.cc/api/v1/search?purity=" + root._purity(allowNsfw) + "&page=" + page + "&sorting=" + root._sorting(sort) + (query ? "&q=" + encodeURIComponent(query) : "");
        XhrJson.getJson(url, json => {
            const items = (json.data || []).map(root._map);
            onResult({
                items: items,
                hasMore: json.meta ? json.meta.current_page < json.meta.last_page : false
            });
        }, onError);
    }
}
