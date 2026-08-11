.pragma library

function getIconSource(player, desktopEntries) {
    if (!player)
        return "";
    const de = (player.desktopEntry ?? "").trim();
    const identity = (player.identity ?? "").trim().toLowerCase().replace(/\s+/g, "-");
    const id = de !== "" ? de : identity;
    if (id === "")
        return "";
    const entry = desktopEntries.heuristicLookup(id);
    if (entry && entry.icon)
        return "image://icon/" + entry.icon + "?fallback=application-x-executable";
    return "image://icon/" + id + "?fallback=application-x-executable";
}
