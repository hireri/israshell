.pragma library

const ALL     = ["vertical", "horizontal", "word", "analog"];
const DIGITAL = ["vertical", "horizontal"];
const TEXT    = ["vertical", "horizontal", "word"];
const ANALOG  = ["analog"];

const LAYOUTS = [
    { id: "vertical",   icon: "vertical-clock",   label: "clockPage.vertical" },
    { id: "horizontal", icon: "horizontal-clock", label: "clockPage.horizontal" },
    { id: "word",       icon: "word-clock",       label: "clockPage.word" },
    { id: "analog",     icon: "analog-clock",     label: "clockPage.analog" }
];

const GROUPS = [
    { id: "look",  label: "clockPage.group_look" },
    { id: "font",  label: "clockPage.group_font" },
    { id: "show",  label: "clockPage.group_show" },
    { id: "place", label: "clockPage.group_place" }
];

const COLOR_ROLES = ["primary", "secondary", "tertiary", "on_surface"];

const GRID  = { digitStyle: "grid" };
const TILES = { digitStyle: "tiles" };
const FLEX = { fontFamily: "Google Sans Flex" };

function choices(prefix, values, iconPrefix) {
    return values.map(v => ({ value: v, label: prefix + v, icon: iconPrefix ? iconPrefix + v : undefined }));
}

const SHAPES = [
    { value: "none",      label: "clockPage.shape_none" },
    { value: "cookie12",  label: "clockPage.shape_cookie",  icon: "shape:cookie12",  iconOnly: true },
    { value: "cookie9",   label: "clockPage.shape_cookie9", icon: "shape:cookie9",   iconOnly: true },
    { value: "softBurst", label: "clockPage.shape_burst",   icon: "shape:softBurst", iconOnly: true },
    { value: "clover4",   label: "clockPage.shape_clover",  icon: "shape:clover4",   iconOnly: true },
    { value: "sunny",     label: "clockPage.shape_sunny",   icon: "shape:sunny",     iconOnly: true },
    { value: "circle",    label: "clockPage.shape_circle",  icon: "shape:circle",    iconOnly: true },
    { value: "square",    label: "clockPage.shape_square",  icon: "shape:square",    iconOnly: true }
];

const HAND_COLORS = [
    { value: "",           label: "clockPage.color_default" },
    { value: "primary",    label: "clockPage.color_primary" },
    { value: "secondary",  label: "clockPage.color_secondary" },
    { value: "tertiary",   label: "clockPage.color_tertiary" },
    { value: "on_surface", label: "clockPage.color_on_surface" }
];

function handOptions(hand, styles, extra) {
    return [
        Object.assign({
            key: hand + "HandStyle", kind: "chips", group: "look", layouts: ANALOG, default: styles[0],
            label: "clockPage." + hand + "_hand_style", sub: "clockPage.hand_style_sub",
            choices: choices("clockPage.hand_", styles, "hand:")
        }, extra),
        Object.assign({
            key: hand + "HandColor", kind: "select", group: "look", layouts: ANALOG, default: "",
            label: "clockPage." + hand + "_hand_color", sub: "clockPage.hand_color_sub",
            choices: HAND_COLORS
        }, extra),
        Object.assign({
            key: hand + "HandWidth", kind: "slider", group: "look", layouts: ANALOG, default: 100,
            label: "clockPage." + hand + "_hand_width", sub: "clockPage.hand_width_sub",
            range: { min: 50, max: 200, step: 5, unit: "%" }
        }, extra)
    ];
}

const DATE_GATE    = { gate: { showDate: true } };
const FACE_GATE    = { gate: { showFace: true } };
const SECONDS_GATE = { gate: { showSeconds: true } };
const SHADOW_GATE  = { gate: { showShadow: true } };
const FLEX_GATE    = { gate: FLEX };

const OPTIONS = [].concat(
    [{ key: "layout", kind: "hidden", group: "", layouts: ALL, default: "vertical" }],

    [
        { key: "digitStyle", kind: "chips", group: "look", layouts: DIGITAL, default: "text",
          label: "clockPage.digit_style", sub: "clockPage.digit_style_sub",
          choices: [
              { value: "text",  label: "clockPage.digit_style_text" },
              { value: "tiles", label: "clockPage.digit_style_tiles" },
              { value: "grid",  label: "clockPage.digit_style_grid" }
          ] },
        { key: "hourShape", kind: "chips", group: "look", layouts: DIGITAL, default: "cookie12", when: TILES,
          label: "clockPage.hour_shape", sub: "clockPage.hour_shape_sub", choices: SHAPES },
        { key: "minuteShape", kind: "chips", group: "look", layouts: DIGITAL, default: "square", when: TILES,
          label: "clockPage.minute_shape", sub: "clockPage.minute_shape_sub", choices: SHAPES },
        { key: "tileSpacing", kind: "slider", group: "look", layouts: DIGITAL, default: 6, when: TILES,
          label: "clockPage.tile_spacing", sub: "clockPage.tile_spacing_sub",
          range: { min: -20, max: 40, step: 1 }, scaled: true },
        { key: "gridColumnSpacing", kind: "slider", group: "look", layouts: DIGITAL, default: 0, when: GRID,
          label: "clockPage.grid_column_spacing", sub: "clockPage.grid_column_spacing_sub",
          range: { min: -60, max: 40, step: 1 }, scaled: true },
        { key: "gridRowSpacing", kind: "slider", group: "look", layouts: ["vertical"], default: 0, when: GRID,
          label: "clockPage.grid_row_spacing", sub: "clockPage.grid_row_spacing_sub",
          range: { min: -60, max: 40, step: 1 }, scaled: true },
        { key: "digitOutline", kind: "slider", group: "look", layouts: DIGITAL, default: 0, when: GRID,
          label: "clockPage.digit_outline", sub: "clockPage.digit_outline_sub",
          range: { min: 0, max: 24, step: 1 }, scaled: true }
    ],

    [
        { key: "dialStyle", kind: "chips", group: "look", layouts: ANALOG, default: "digital",
          label: "clockPage.dial_style", sub: "clockPage.dial_style_sub",
          choices: [
              { value: "ticks",    label: "clockPage.dial_ticks" },
              { value: "digital",  label: "clockPage.dial_digital" },
              { value: "numerals", label: "clockPage.dial_numerals" }
          ] },
        { key: "showFace", kind: "switch", group: "look", layouts: ANALOG, default: true,
          label: "clockPage.show_face", sub: "clockPage.show_face_sub" },
        Object.assign({ key: "ringSides", kind: "slider", group: "look", layouts: ANALOG, default: 12,
          label: "clockPage.face_wobble", sub: "clockPage.number_of_lobes_on_the", range: { min: 2, max: 20, step: 1 } }, FACE_GATE),
        Object.assign({ key: "ringAmplitude", kind: "slider", group: "look", layouts: ANALOG, default: 4,
          label: "clockPage.wobble_depth", sub: "clockPage.how_far_the_edge_undulates", range: { min: 0, max: 30, step: 1 } }, FACE_GATE),
        Object.assign({ key: "outlineWidth", kind: "slider", group: "look", layouts: ANALOG, default: 2,
          label: "clockPage.outline_width", sub: "clockPage.colored_outline_around_the_clock",
          range: { min: 0, max: 10, step: 1 }, scaled: true }, FACE_GATE)
    ],

    handOptions("hour",   ["capsule", "tapered", "hollow", "needle"]),
    handOptions("minute", ["capsule", "tapered", "hollow", "needle"]),

    [
        { key: "fontFamily", kind: "font", group: "font", layouts: ALL, default: "Google Sans Flex",
          label: "clockPage.font_family", sub: "clockPage.leave_empty_to_use_the" },
        { key: "hourWeight", kind: "slider", group: "font", layouts: ALL, default: 500,
          label: "clockPage.weight", range: { min: 100, max: 1000, step: 10 } },
        { key: "minuteWeight", kind: "slider", group: "font", layouts: ALL, default: 300,
          label: "clockPage.sub_weight", sub: "clockPage.minutes_seconds_date", range: { min: 100, max: 1000, step: 10 } },
        Object.assign({ key: "fontWidth", kind: "slider", group: "font", layouts: ALL, default: 100,
          label: "clockPage.width", sub: "clockPage.condensed_normal_expanded", range: { min: 25, max: 150, step: 1 } }, FLEX_GATE),
        Object.assign({ key: "fontRoundness", kind: "slider", group: "font", layouts: ALL, default: 0,
          label: "clockPage.roundness", sub: "clockPage.corner_radius_of_letterforms_rond", range: { min: 0, max: 100, step: 1 } }, FLEX_GATE),
        Object.assign({ key: "fontSlant", kind: "slider", group: "font", layouts: ALL, default: 0,
          label: "clockPage.slant", sub: "clockPage.slant_sub", range: { min: 0, max: 10, step: 1 } }, FLEX_GATE)
    ],

    [
        { key: "showDate", kind: "switch", group: "show", layouts: ALL, default: true,
          label: "clockPage.show_date", sub: "clockPage.include_date_information_below_the" },
        Object.assign({ key: "dateStyle", kind: "chips", group: "show", layouts: ANALOG, default: "badges",
          label: "clockPage.date_style", sub: "clockPage.date_style_sub",
          choices: [{ value: "badges", label: "clockPage.date_badges" }, { value: "rim", label: "clockPage.date_rim" }] }, DATE_GATE),
        Object.assign({ key: "dateFormat", kind: "chips", group: "show", layouts: TEXT, default: "short",
          label: "clockPage.date_format", sub: "clockPage.date_format_sub",
          choices: [{ value: "short", label: "clockPage.date_format_short" }, { value: "long", label: "clockPage.date_format_long" }] }, DATE_GATE),
        Object.assign({ key: "dateSize", kind: "slider", group: "show", layouts: ALL, default: 100,
          label: "clockPage.date_size", range: { min: 40, max: 250, step: 5, unit: "%" } }, DATE_GATE),
        Object.assign({ key: "dateSpacing", kind: "slider", group: "show", layouts: TEXT, default: -5, unless: TILES,
          label: "clockPage.date_spacing", range: { min: -60, max: 40, step: 1 }, scaled: true }, DATE_GATE),
        { key: "showSeconds", kind: "switch", group: "show", layouts: ["horizontal", "vertical", "analog"], default: false,
          label: { _: "clockPage.show_seconds", analog: "clockPage.show_seconds_hand" },
          sub: { _: "clockPage.displays_ticking_seconds", analog: "clockPage.adds_a_sweeping_seconds_hand" } }
    ],
    handOptions("second", ["dot", "needle", "tail"], Object.assign({ group: "show" }, SECONDS_GATE)),
    [
        { key: "showAmPm", kind: "switch", group: "show", layouts: DIGITAL, default: true,
          label: "clockPage.show_am_pm", sub: "clockPage.show_am_pm_sub" }
    ],

    [
        { key: "size", kind: "slider", group: "place", layouts: ALL, default: 100,
          label: "clockPage.size",
          range: { min: 40, max: 200, step: 1 }, ranges: { word: { min: 20, max: 120, step: 1 }, analog: { min: 40, max: 250, step: 1 } },
          resize: ALL, scaled: true },
        { key: "minuteSize", kind: "slider", group: "place", layouts: ["vertical"], default: 100, unless: GRID,
          label: "clockPage.minute_size", range: { min: 40, max: 200, step: 1, unit: "%" } },
        { key: "timeSpacing", kind: "slider", group: "place", layouts: ["vertical"], default: -30, when: { digitStyle: "text" },
          label: "clockPage.time_spacing", range: { min: -100, max: 40, step: 1 }, scaled: true },
        { key: "wordSpacing", kind: "slider", group: "place", layouts: ["word"], default: -6,
          label: "clockPage.line_spacing", range: { min: -40, max: 40, step: 1 }, scaled: true },
        { key: "align", kind: "chips", group: "place", layouts: TEXT, default: "left",
          label: "clockPage.content_alignment", sub: "clockPage.flow_layout_of_the_time",
          choices: [
              { value: "auto",   label: "barPage.auto",            icon: "align-auto" },
              { value: "left",   label: "barPage.left",            icon: "align-left" },
              { value: "center", label: "backgroundPage.center",   icon: "align-center" },
              { value: "right",  label: "barPage.right",           icon: "align-right" }
          ] },
        { key: "showShadow", kind: "switch", group: "place", layouts: ALL, default: true,
          label: "clockPage.show_shadow", sub: "clockPage.show_shadow_sub" },
        Object.assign({ key: "shadowBlur", kind: "slider", group: "place", layouts: ALL, default: 16,
          label: "clockPage.shadow_blur", range: { min: 0, max: 64, step: 1 } }, SHADOW_GATE),
        Object.assign({ key: "shadowX", kind: "slider", group: "place", layouts: ALL, default: 0,
          label: "clockPage.shadow_x", range: { min: -40, max: 40, step: 1 } }, SHADOW_GATE),
        Object.assign({ key: "shadowY", kind: "slider", group: "place", layouts: ALL, default: 0,
          label: "clockPage.shadow_y", range: { min: -40, max: 40, step: 1 } }, SHADOW_GATE),
        Object.assign({ key: "shadowOpacity", kind: "slider", group: "place", layouts: ALL, default: 0.2,
          label: "clockPage.shadow_opacity", range: { min: 0, max: 100, step: 1 }, display: 100 }, SHADOW_GATE)
    ],

    [
        { key: "manualPos", kind: "switch", group: "top", layouts: ALL, default: false,
          label: "clockPage.manual_positioning", sub: "clockPage.drag_the_clock_freely_instead" },
        { key: "colorRole", kind: "color", group: "preview", layouts: ALL, default: "primary",
          label: "backgroundPage.main_color", roles: COLOR_ROLES },
        { key: "subColorRole", kind: "color", group: "preview", layouts: ALL, default: "secondary",
          label: "backgroundPage.accent_color", roles: COLOR_ROLES }
    ]
);

const PRESETS = [
    { id: "cookieTiles", label: "clockPage.preset_cookie_tiles", patch: {
        layout: "horizontal", digitStyle: "tiles", hourShape: "cookie12", minuteShape: "square",
        size: 56, hourWeight: 700, minuteWeight: 500 } },
    { id: "stackedTiles", label: "clockPage.preset_stacked_tiles", patch: {
        layout: "vertical", digitStyle: "tiles", hourShape: "cookie12", minuteShape: "square",
        size: 50, hourWeight: 700, minuteWeight: 500 } },
    { id: "flexStack", label: "clockPage.preset_flex_stack", patch: {
        layout: "vertical", digitStyle: "grid",
        size: 120, hourWeight: 1000, minuteWeight: 1000, fontWidth: 125,
        gridColumnSpacing: -16, gridRowSpacing: -16, digitOutline: 6 } },
    { id: "numerals", label: "clockPage.preset_numerals", patch: {
        layout: "analog", dialStyle: "numerals", showFace: true, ringAmplitude: 0, dateStyle: "rim",
        hourWeight: 700,
        hourHandStyle: "capsule", minuteHandStyle: "capsule" } }
];

const BY_KEY = {};
for (const o of OPTIONS)
    BY_KEY[o.key] = o;

function option(key) {
    return BY_KEY[key] ?? null;
}

function defaults() {
    const out = {};
    for (const o of OPTIONS)
        out[o.key] = o.default;
    return out;
}

function appliesTo(opt, layout) {
    return opt.layouts.indexOf(layout) !== -1;
}

function _matches(cond, cfg) {
    for (const k in cond)
        if ((cfg[k] ?? BY_KEY[k]?.default) !== cond[k])
            return false;
    return true;
}

function isVisible(opt, layout, cfg) {
    if (!appliesTo(opt, layout))
        return false;
    const state = DIGITAL.indexOf(layout) !== -1 ? cfg : Object.assign({}, cfg, { digitStyle: "text" });
    if (opt.when && !_matches(opt.when, state))
        return false;
    if (opt.unless && _matches(opt.unless, state))
        return false;
    return true;
}

function isLocked(opt, cfg) {
    return !!opt.gate && !_matches(opt.gate, cfg);
}

function groups() {
    return GROUPS.map(g => ({
        id: g.id,
        label: g.label,
        options: OPTIONS.filter(o => o.group === g.id && o.kind !== "hidden")
    })).filter(g => g.options.length > 0);
}

function groupVisible(group, layout, cfg) {
    return group.options.some(o => isVisible(o, layout, cfg));
}

function text(opt, field, layout) {
    const v = opt[field];
    if (v === undefined)
        return "";
    return typeof v === "string" ? v : (v[layout] ?? v._);
}

function range(opt, layout) {
    return (opt.ranges && opt.ranges[layout]) || opt.range;
}

function fieldsForLayout(layout) {
    return OPTIONS.filter(o => o.scaled && appliesTo(o, layout)).map(o => o.key);
}

function resizableFieldsForLayout(layout) {
    return OPTIONS.filter(o => o.resize && o.resize.indexOf(layout) !== -1).map(o => o.key);
}

function boundsFor(layout, key) {
    const o = BY_KEY[key];
    if (!o || !o.scaled || !appliesTo(o, layout))
        return null;
    const r = range(o, layout);
    return { min: r.min, max: r.max };
}

function scaledFields() {
    return OPTIONS.filter(o => o.scaled).map(o => o.key);
}

function scaledBoundsFor(key) {
    const o = BY_KEY[key];
    if (!o || !o.scaled)
        return null;
    let min = Infinity, max = -Infinity;
    for (const l of o.layouts) {
        const r = range(o, l);
        min = Math.min(min, r.min);
        max = Math.max(max, r.max);
    }
    return { min: min, max: max };
}

function scaledDefaultFor(key) {
    return BY_KEY[key]?.default ?? 100;
}

function activePreset(cfg) {
    const hit = PRESETS.find(p => Object.keys(p.patch).every(k => cfg[k] === p.patch[k]));
    return hit ? hit.id : "";
}

function layouts() {
    return LAYOUTS;
}

function presets() {
    return PRESETS;
}
