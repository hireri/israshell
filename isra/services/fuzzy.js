.pragma library

function substringEditDistance(query, target, maxEdits) {
    const m = query.length;
    const n = target.length;
    if (m === 0)
        return 0;
    if (n === 0)
        return m;

    if (maxEdits !== undefined && (m - n) > maxEdits)
        return maxEdits + 1;

    const abort = maxEdits !== undefined;
    let prevRow = new Array(n + 1).fill(0);
    let currRow = new Array(n + 1);

    for (let i = 1; i <= m; i++) {
        currRow[0] = i;
        let rowMin = i;
        for (let j = 1; j <= n; j++) {
            const cost = query.charAt(i - 1) === target.charAt(j - 1) ? 0 : 1;
            const v = Math.min(
                prevRow[j - 1] + cost,
                prevRow[j] + 1,
                currRow[j - 1] + 1
            );
            currRow[j] = v;
            if (v < rowMin)
                rowMin = v;
        }
        if (abort && rowMin > maxEdits)
            return maxEdits + 1;
        const tmp = prevRow;
        prevRow = currRow;
        currRow = tmp;
    }

    let minVal = prevRow[0];
    for (let j = 1; j <= n; j++) {
        if (prevRow[j] < minVal) {
            minVal = prevRow[j];
            if (minVal === 0)
                break;
        }
    }
    return minVal;
}

function maxAllowedEdits(queryLength) {
    if (queryLength <= 2)
        return 0;
    if (queryLength <= 4)
        return 1;
    if (queryLength <= 7)
        return 2;
    return Math.floor(queryLength / 3);
}

function scoreText(q, text, band) {
    if (!text)
        return undefined;

    if (band.exact !== undefined && text === q)
        return band.exact;

    if (band.startsWith !== undefined && text.startsWith(q))
        return band.startsWith - text.length * (band.lenPenalty ?? 1);

    if (band.includes !== undefined && text.includes(q))
        return band.includes - text.indexOf(q) * (band.indexPenalty ?? 1) - text.length * (band.lenPenalty ?? 1);

    if (band.fuzzy !== undefined) {
        const maxEdits = maxAllowedEdits(q.length);
        const dist = substringEditDistance(q, text, maxEdits);
        if (dist <= maxEdits)
            return band.fuzzy - dist * 50 - text.length * (band.fuzzyLenPenalty ?? band.lenPenalty ?? 1);
    }

    return undefined;
}
