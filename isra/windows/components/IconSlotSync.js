.pragma library

function syncIconSlot(children, iconSize, color, filled) {
    for (let i = 0; i < children.length; i++) {
        const ico = children[i];
        if (ico.hasOwnProperty("iconSize"))
            ico.iconSize = iconSize;
        if (ico.hasOwnProperty("color"))
            ico.color = color;
        if (ico.hasOwnProperty("filled"))
            ico.filled = filled;
    }
}
