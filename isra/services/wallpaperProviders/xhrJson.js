.pragma library

function getJson(url, onSuccess, onError) {
    const req = new XMLHttpRequest();
    req.open("GET", url);
    req.onreadystatechange = () => {
        if (req.readyState !== XMLHttpRequest.DONE)
            return;
        if (req.status !== 200) {
            onError("HTTP " + req.status);
            return;
        }
        try {
            onSuccess(JSON.parse(req.responseText));
        } catch (e) {
            onError(String(e));
        }
    };
    req.send();
}
