.pragma library

function forName(name) {
    const ext = ((name ?? "").split(".").pop() ?? "").toLowerCase();
    if (["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "avif", "tiff", "ico"].includes(ext))
        return "image";
    if (["mp4", "mkv", "webm", "mov", "avi", "m4v"].includes(ext))
        return "video";
    if (["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac"].includes(ext))
        return "queue-music";
    if (["sh", "py", "js", "ts", "qml", "c", "cpp", "h", "rs", "go", "json", "yaml", "yml", "toml", "html", "css"].includes(ext))
        return "terminal";
    if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].includes(ext))
        return "folder-zip";
    if (["pdf", "txt", "md", "doc", "docx", "odt", "rtf"].includes(ext))
        return "description";
    return "question-mark";
}
