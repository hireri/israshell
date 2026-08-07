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

function _isHeadingLine(line) {
    return /^\s{0,3}#{1,6}(\s|$)/.test(line);
}

function _isFenceOpenLine(line) {
    return /^\s{0,3}(`{3,}|~{3,})/.test(line);
}

function _isQuoteLine(line) {
    return /^\s{0,3}>/.test(line);
}

function _isListMarkerLine(line) {
    return /^\s{0,3}([-*+]|\d{1,9}[.)])\s+\S/.test(line);
}

function _continuesList(line) {
    if (line.trim() === "")
        return false;
    if (_isHeadingLine(line) || _isFenceOpenLine(line) || _isQuoteLine(line))
        return false;
    return true;
}

function _isProseish(type) {
    return type === "paragraph" || type === "heading" || type === "list";
}

function parseBlocks(src) {
    const lines = (src ?? "").split("\n");
    const blocks = [];
    let prose = [];
    let fence = null;
    let prevType = null;

    function pushBlock(block) {
        if (prevType === null)
            block.gap = 0;
        else if (!_isProseish(prevType) || !_isProseish(block.type))
            block.gap = 24;
        else if (block.type === "heading")
            block.gap = 20;
        else
            block.gap = 12;
        blocks.push(block);
        prevType = block.type;
    }

    function flushProse() {
        const text = prose.join("\n");
        prose = [];
        const parts = text.split(/\n{2,}/);
        for (const part of parts) {
            const t = part.trim();
            if (t !== "")
                pushBlock({
                    type: "paragraph",
                    text: t,
                    lang: "",
                    open: false
                });
        }
    }

    let i = 0;
    while (i < lines.length) {
        const line = lines[i];

        if (fence) {
            const close = line.match(/^\s{0,3}(`{3,}|~{3,})\s*$/);
            if (close && close[1][0] === fence.marker && close[1].length >= fence.len) {
                pushBlock({
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
            const header = _splitTableRow(line);
            const rule = _splitTableRow(lines[i + 1]);

            if (rule.length === header.length) {
                flushProse();
                const align = rule.map(_alignForRule);
                const rows = [];
                let j = i + 2;
                while (j < lines.length && lines[j].trim() !== "" && lines[j].includes("|")) {
                    rows.push(_splitTableRow(lines[j]));
                    j++;
                }
                pushBlock({
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
        }

        if (_isQuoteLine(line)) {
            flushProse();
            const quoteLines = [];
            while (i < lines.length && _isQuoteLine(lines[i])) {
                quoteLines.push(lines[i].replace(/^\s{0,3}>\s?/, ""));
                i++;
            }
            pushBlock({
                type: "quote",
                text: quoteLines.join("\n"),
                lang: "",
                open: false
            });
            continue;
        }

        if (_isHeadingLine(line)) {
            flushProse();
            pushBlock({
                type: "heading",
                text: line.trim(),
                lang: "",
                open: false
            });
            i++;
            continue;
        }

        if (_isListMarkerLine(line)) {
            flushProse();
            const listLines = [line];
            i++;
            while (i < lines.length) {
                const next = lines[i];
                if (next.trim() === "") {
                    if (i + 1 < lines.length && _continuesList(lines[i + 1])) {
                        listLines.push(next);
                        i++;
                        continue;
                    }
                    break;
                }
                if (!_continuesList(next))
                    break;
                if (next.includes("|") && i + 1 < lines.length && _isTableRuleLine(lines[i + 1]))
                    break;
                listLines.push(next);
                i++;
            }
            pushBlock({
                type: "list",
                text: listLines.join("\n").trim(),
                lang: "",
                open: false
            });
            continue;
        }

        prose.push(line);
        i++;
    }

    if (fence)
        pushBlock({
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
        javascript: "JavaScript",
        jsx: "JSX",
        ts: "TypeScript",
        typescript: "TypeScript",
        tsx: "TSX",
        py: "Python",
        python: "Python",
        rs: "Rust",
        rb: "Ruby",
        go: "Go",
        kt: "Kotlin",
        kotlin: "Kotlin",
        sh: "Shell",
        bash: "Bash",
        zsh: "Zsh",
        fish: "Fish",
        ps1: "PowerShell",
        c: "C",
        h: "C",
        cpp: "C++",
        hpp: "C++",
        "c++": "C++",
        cs: "C#",
        csharp: "C#",
        java: "Java",
        php: "PHP",
        lua: "Lua",
        vim: "Vim",
        nix: "Nix",
        qml: "QML",
        md: "Markdown",
        json: "JSON",
        jsonc: "JSON",
        yml: "YAML",
        yaml: "YAML",
        toml: "TOML",
        ini: "INI",
        conf: "Config",
        xml: "XML",
        html: "HTML",
        css: "CSS",
        scss: "SCSS",
        sql: "SQL",
        diff: "Diff",
        patch: "Diff",
        dockerfile: "Dockerfile",
        make: "Makefile",
        makefile: "Makefile",
        tex: "LaTeX"
    };
    const key = lang.toLowerCase();
    return map[key] ?? (key.charAt(0).toUpperCase() + key.slice(1));
}
