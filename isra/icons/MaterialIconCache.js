.pragma library

var _cache = ({});

function _parseSvgPaths(xmlContent) {
    var paths = [];
    var regex = /d="([^"]+)"/g;
    var match;
    while ((match = regex.exec(xmlContent)) !== null)
        paths.push(match[1]);
    return paths;
}

function _readFile(path) {
    try {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", path, false);
        xhr.send();
        return xhr.responseText || "";
    } catch (e) {
        return "";
    }
}

function getPaths(iconsDir, variant, name) {
    if (!name)
        return [];

    var key = variant + ":" + name;
    var cached = _cache[key];
    if (cached !== undefined)
        return cached;

    var text = _readFile("file://" + iconsDir + "/" + variant + "/" + name + ".svg");
    var paths = text ? _parseSvgPaths(text) : [];
    _cache[key] = paths;
    return paths;
}
