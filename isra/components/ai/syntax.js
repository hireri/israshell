.pragma library

const MAX_LENGTH = 40000;

const KW_JS = "const let var function return if else for while do switch case break continue new class extends super this typeof instanceof in of delete void null undefined true false async await yield try catch finally throw import export from default static get set enum interface type implements public private protected readonly abstract declare namespace satisfies as is keyof infer never unknown any";
const KW_QML = "property signal readonly alias pragma component required on default";
const KW_C = "alignas auto bool break case catch char class const constexpr continue default delete do double else enum explicit extern false float for friend goto if inline int long mutable namespace new noexcept nullptr operator private protected public register return short signed sizeof static struct switch template this throw true try typedef typename union unsigned using virtual void volatile while size_t uint8_t uint16_t uint32_t uint64_t int8_t int16_t int32_t int64_t";
const KW_RUST = "fn let mut impl trait pub use mod match crate self super where dyn ref move as loop unsafe enum struct type const static async await box yield if else for while return break continue true false Some None Ok Err";
const KW_GO = "func package import var const type struct interface map chan go defer select range if else for switch case break continue return fallthrough nil true false make new len cap append";
const KW_JVM = "public private protected class interface extends implements static final void return if else for while switch case try catch finally throw throws import package abstract enum var val fun object override suspend companion data sealed init this super new null true false instanceof synchronized";
const KW_PY = "def class lambda return yield if elif else for while break continue pass import from as with try except finally raise global nonlocal assert del in is not and or None True False async await self match case print len range";
const KW_SH = "if then else elif fi for while until do done case esac function select in return exit export local readonly declare source alias unset shift eval exec trap set echo cd test true false sudo";
const KW_SQL = "select insert update delete from where join inner left right outer full cross on group order by having limit offset distinct as into values set create table drop alter add column primary key foreign references index view union all and or not null is like between case when then else end asc desc count sum avg min max";
const KW_LUA = "local function end if then else elseif for while do repeat until return break nil true false and or not in pairs ipairs require";
const KW_RUBY = "def end class module if elsif else unless while until do return yield nil true false self require attr_accessor begin rescue ensure raise puts";
const KW_DATA = "true false null yes no on off none";

function _set(words) {
    const s = {};
    for (const w of words.split(" "))
        s[w] = true;
    return s;
}

const SPECS = {
    js: {
        line: ["//"],
        block: ["/*", "*/"],
        quotes: "\"'`",
        keywords: _set(KW_JS)
    },
    qml: {
        line: ["//"],
        block: ["/*", "*/"],
        quotes: "\"'`",
        keywords: _set(KW_JS + " " + KW_QML)
    },
    c: {
        line: ["//"],
        block: ["/*", "*/"],
        quotes: "\"'",
        preproc: true,
        keywords: _set(KW_C)
    },
    rust: {
        line: ["//"],
        block: ["/*", "*/"],
        quotes: "\"'",
        keywords: _set(KW_RUST)
    },
    go: {
        line: ["//"],
        block: ["/*", "*/"],
        quotes: "\"'`",
        keywords: _set(KW_GO)
    },
    jvm: {
        line: ["//"],
        block: ["/*", "*/"],
        quotes: "\"'",
        keywords: _set(KW_JVM)
    },
    python: {
        line: ["#"],
        block: null,
        quotes: "\"'",
        triple: true,
        keywords: _set(KW_PY)
    },
    shell: {
        line: ["#"],
        block: null,
        quotes: "\"'`",
        keywords: _set(KW_SH)
    },
    sql: {
        line: ["--"],
        block: ["/*", "*/"],
        quotes: "'\"",
        caseInsensitive: true,
        keywords: _set(KW_SQL)
    },
    lua: {
        line: ["--"],
        block: null,
        quotes: "\"'",
        keywords: _set(KW_LUA)
    },
    ruby: {
        line: ["#"],
        block: null,
        quotes: "\"'",
        keywords: _set(KW_RUBY)
    },
    css: {
        line: [],
        block: ["/*", "*/"],
        quotes: "\"'",
        keywords: {}
    },
    markup: {
        line: [],
        block: ["<!--", "-->"],
        quotes: "\"'",
        keywords: {}
    },
    data: {
        line: ["#"],
        block: null,
        quotes: "\"'",
        keywords: _set(KW_DATA)
    },
    plain: {
        line: ["#", "//"],
        block: ["/*", "*/"],
        quotes: "\"'`",
        keywords: {}
    }
};

const ALIASES = {
    js: "js",
    jsx: "js",
    javascript: "js",
    ts: "js",
    tsx: "js",
    typescript: "js",
    mjs: "js",
    json: "data",
    json5: "js",
    qml: "qml",
    c: "c",
    h: "c",
    cpp: "c",
    "c++": "c",
    hpp: "c",
    cc: "c",
    objc: "c",
    glsl: "c",
    frag: "c",
    vert: "c",
    rs: "rust",
    rust: "rust",
    go: "go",
    golang: "go",
    java: "jvm",
    kt: "jvm",
    kotlin: "jvm",
    cs: "jvm",
    csharp: "jvm",
    scala: "jvm",
    swift: "jvm",
    dart: "jvm",
    py: "python",
    python: "python",
    python3: "python",
    sh: "shell",
    bash: "shell",
    zsh: "shell",
    fish: "shell",
    shell: "shell",
    console: "shell",
    sql: "sql",
    psql: "sql",
    lua: "lua",
    rb: "ruby",
    ruby: "ruby",
    css: "css",
    scss: "css",
    less: "css",
    html: "markup",
    xml: "markup",
    svg: "markup",
    yaml: "data",
    yml: "data",
    toml: "data",
    ini: "data",
    conf: "data",
    env: "data"
};

function specFor(lang) {
    const key = (lang ?? "").toLowerCase().trim();
    return SPECS[ALIASES[key] ?? "plain"];
}

function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function _pre(s) {
    return escapeHtml(s).replace(/\t/g, "    ").replace(/ /g, "&nbsp;").replace(/\n/g, "<br/>");
}

function _isIdentStart(c) {
    return /[A-Za-z_$]/.test(c);
}

function _isIdent(c) {
    return /[A-Za-z0-9_$]/.test(c);
}

function _isDigit(c) {
    return c >= "0" && c <= "9";
}

function highlight(code, lang, palette) {
    const src = code ?? "";
    if (src.length > MAX_LENGTH)
        return _pre(src);

    const spec = specFor(lang);
    const out = [];

    function push(text, color) {
        if (text === "")
            return;
        if (!color) {
            out.push(_pre(text));
            return;
        }
        out.push("<span style=\"color:" + color + "\">" + _pre(text) + "</span>");
    }

    let i = 0;
    const n = src.length;

    while (i < n) {
        const c = src[i];

        if (spec.block && src.startsWith(spec.block[0], i)) {
            const close = src.indexOf(spec.block[1], i + spec.block[0].length);
            const end = close === -1 ? n : close + spec.block[1].length;
            push(src.slice(i, end), palette.comment);
            i = end;
            continue;
        }

        let lineComment = null;
        for (const marker of spec.line ?? []) {
            if (src.startsWith(marker, i)) {
                lineComment = marker;
                break;
            }
        }
        if (lineComment !== null) {
            let end = src.indexOf("\n", i);
            if (end === -1)
                end = n;
            push(src.slice(i, end), palette.comment);
            i = end;
            continue;
        }

        if (spec.preproc && c === "#" && (i === 0 || src[i - 1] === "\n")) {
            let end = src.indexOf("\n", i);
            if (end === -1)
                end = n;
            push(src.slice(i, end), palette.keyword);
            i = end;
            continue;
        }

        if (spec.quotes.includes(c)) {
            const triple = spec.triple && src.startsWith(c + c + c, i);
            const delim = triple ? c + c + c : c;
            let j = i + delim.length;
            while (j < n) {
                if (src[j] === "\\") {
                    j += 2;
                    continue;
                }
                if (src.startsWith(delim, j)) {
                    j += delim.length;
                    break;
                }
                if (!triple && src[j] === "\n")
                    break;
                j++;
            }
            push(src.slice(i, Math.min(j, n)), palette.string);
            i = Math.min(j, n);
            continue;
        }

        if (_isDigit(c) || (c === "." && _isDigit(src[i + 1] ?? ""))) {
            let j = i;
            while (j < n && /[0-9a-fA-FxXbBoO_.]/.test(src[j]))
                j++;
            if (src[j] === "e" || src[j] === "E") {
                j++;
                if (src[j] === "+" || src[j] === "-")
                    j++;
                while (j < n && _isDigit(src[j]))
                    j++;
            }
            push(src.slice(i, j), palette.number);
            i = j;
            continue;
        }

        if (_isIdentStart(c)) {
            let j = i;
            while (j < n && _isIdent(src[j]))
                j++;
            const word = src.slice(i, j);
            const lookup = spec.caseInsensitive ? word.toLowerCase() : word;

            let k = j;
            while (k < n && (src[k] === " " || src[k] === "\t"))
                k++;

            let color = null;
            if (spec.keywords[lookup] === true)
                color = palette.keyword;
            else if (src[k] === "(")
                color = palette.func;
            else if (/^[A-Z]/.test(word) && word.length > 1)
                color = palette.type;

            push(word, color);
            i = j;
            continue;
        }

        let j = i;
        while (j < n && !_isIdentStart(src[j]) && !_isDigit(src[j]) && !spec.quotes.includes(src[j]) && !(spec.block && src.startsWith(spec.block[0], j))) {
            if ((spec.line ?? []).some(m => src.startsWith(m, j)))
                break;
            j++;
        }
        if (j === i)
            j++;
        push(src.slice(i, j), null);
        i = j;
    }

    return out.join("");
}
