.pragma library

function _isTableRuleLine(line) {
    const t = line.trim();
    if (t === "" || !t.includes("-") || !/^[-:|\s]+$/.test(t))
        return false;
    return t.split("|").some(cell => /^\s*:?-+:?\s*$/.test(cell) && cell.trim() !== "");
}

function _splitTableRow(line) {
    let t = line.trim();
    if (t.startsWith("|"))
        t = t.slice(1);
    if (t.endsWith("|") && !t.endsWith("\\|"))
        t = t.slice(0, -1);

    const cells = [];
    let cur = "";
    for (let i = 0; i < t.length; i++) {
        const c = t[i];
        if (c === "\\" && t[i + 1] === "|") {
            cur += "|";
            i++;
            continue;
        }
        if (c === "|") {
            cells.push(cur.trim());
            cur = "";
            continue;
        }
        cur += c;
    }
    cells.push(cur.trim());
    return cells;
}

function _alignForRule(cell) {
    const t = cell.trim();
    const left = t.startsWith(":");
    const right = t.endsWith(":");
    if (left && right)
        return "center";
    if (right)
        return "right";
    if (left)
        return "left";
    return "";
}

function parseBlocks(src) {
    const lines = (src ?? "").split("\n");
    const blocks = [];
    let prose = [];
    let fence = null;

    function flushProse() {
        const text = prose.join("\n").trim();
        prose = [];
        if (text !== "")
            blocks.push({
                type: "prose",
                text: text,
                lang: "",
                open: false
            });
    }

    let i = 0;
    while (i < lines.length) {
        const line = lines[i];

        if (fence) {
            const close = line.match(/^\s{0,3}(`{3,}|~{3,})\s*$/);
            if (close && close[1][0] === fence.marker && close[1].length >= fence.len) {
                blocks.push({
                    type: "code",
                    text: fence.lines.join("\n"),
                    lang: fence.lang,
                    open: false
                });
                fence = null;
            } else {
                fence.lines.push(line);
            }
            i++;
            continue;
        }

        const open = line.match(/^\s{0,3}(`{3,}|~{3,})\s*([A-Za-z0-9_+#.\-]*)\s*$/);
        if (open) {
            flushProse();
            fence = {
                marker: open[1][0],
                len: open[1].length,
                lang: open[2] ?? "",
                lines: []
            };
            i++;
            continue;
        }

        if (line.includes("|") && i + 1 < lines.length && _isTableRuleLine(lines[i + 1])) {
            flushProse();
            const header = _splitTableRow(line);
            const align = _splitTableRow(lines[i + 1]).map(_alignForRule);
            const rows = [];
            let j = i + 2;
            while (j < lines.length && lines[j].trim() !== "" && lines[j].includes("|")) {
                rows.push(_splitTableRow(lines[j]));
                j++;
            }
            blocks.push({
                type: "table",
                text: JSON.stringify({
                    header: header,
                    align: align,
                    rows: rows
                }),
                lang: "",
                open: false
            });
            i = j;
            continue;
        }

        if (/^\s{0,3}>/.test(line)) {
            flushProse();
            const quoteLines = [];
            while (i < lines.length && /^\s{0,3}>/.test(lines[i])) {
                quoteLines.push(lines[i].replace(/^\s{0,3}>\s?/, ""));
                i++;
            }
            blocks.push({
                type: "quote",
                text: quoteLines.join("\n"),
                lang: "",
                open: false
            });
            continue;
        }

        prose.push(line);
        i++;
    }

    if (fence)
        blocks.push({
            type: "code",
            text: fence.lines.join("\n"),
            lang: fence.lang,
            open: true
        });
    else
        flushProse();

    return blocks;
}

function langLabel(lang) {
    if (!lang)
        return "Code";
    const map = {
        js: "JavaScript",
        ts: "TypeScript",
        py: "Python",
        rs: "Rust",
        sh: "Shell",
        bash: "Bash",
        zsh: "Zsh",
        cpp: "C++",
        cs: "C#",
        qml: "QML",
        md: "Markdown",
        json: "JSON",
        yml: "YAML",
        yaml: "YAML",
        toml: "TOML",
        html: "HTML",
        css: "CSS",
        sql: "SQL"
    };
    const key = lang.toLowerCase();
    return map[key] ?? (key.charAt(0).toUpperCase() + key.slice(1));
}
