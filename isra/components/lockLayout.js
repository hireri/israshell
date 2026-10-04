.pragma library

const layouts = ["dock", "corners", "center"];
const margin = 64;

function valid(name) {
    return layouts.indexOf(name) >= 0 ? name : "dock";
}

function clockCenter(layout, W, H, cw, ch) {
    switch (valid(layout)) {
    case "corners":
        return { x: margin + cw / 2, y: H - 96 - ch / 2 };
    case "center":
        return { x: W / 2, y: H / 2 - 40 };
    default:
        return { x: W / 2, y: (72 + H - 200) / 2 };
    }
}
