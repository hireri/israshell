pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    function mix(c1, c2, t) {
        const a = Qt.color(c1), b = Qt.color(c2);
        return Qt.rgba(t * a.r + (1 - t) * b.r, t * a.g + (1 - t) * b.g, t * a.b + (1 - t) * b.b, t * a.a + (1 - t) * b.a);
    }

    function withAlpha(color, alpha) {
        const c = Qt.color(color);
        return Qt.rgba(c.r, c.g, c.b, Math.max(0, Math.min(1, alpha)));
    }

    function m3CardScheme(dominantColor, darkMode) {
        const d = Qt.color(dominantColor);
        const h = d.hslHue;
        const s = d.hslSaturation;

        const sHigh = Math.min(s, 0.95);
        const sMid = Math.min(s * 0.22, 0.12);
        const sSurf = Math.min(s * 0.30, 0.18);

        if (darkMode) {
            return {
                // tone 6–17: surfaces, lightness 7–15%, low chroma
                surface: Qt.hsla(h, sMid, 0.07, 1.0),
                surfaceContainer: Qt.hsla(h, sMid, 0.11, 1.0),
                surfaceContainerHigh: Qt.hsla(h, sMid, 0.15, 1.0),
                // tone 80: primary, light golden, high chroma
                primary: Qt.hsla(h, Math.min(sHigh * 0.75, 0.70), 0.65, 1.0),
                // tone 20: onPrimary, very dark, high chroma
                onPrimary: Qt.hsla(h, sHigh, 0.11, 1.0),
                // tone 30: primaryContainer, dark, full chroma
                primaryContainer: Qt.hsla(h, sHigh, 0.16, 1.0),
                // tone 90: onPrimaryContainer, very light, high chroma
                onPrimaryContainer: Qt.hsla(h, Math.min(sHigh * 0.90, 0.88), 0.76, 1.0),
                // tone 90: onSurface, very light, low chroma
                onSurface: Qt.hsla(h, sMid, 0.87, 1.0),
                // tone 80: onSurfaceVariant, light, abit more chroma
                onSurfaceVariant: Qt.hsla(h, sSurf, 0.75, 1.0),
                // tone 30ish: outline
                outline: Qt.hsla(h, sSurf, 0.26, 1.0)
            };
        } else {
            return {
                surface: Qt.hsla(h, sMid, 0.98, 1.0),
                surfaceContainer: Qt.hsla(h, sMid, 0.94, 1.0),
                surfaceContainerHigh: Qt.hsla(h, sMid, 0.90, 1.0),
                primary: Qt.hsla(h, Math.min(sHigh, 0.75), 0.30, 1.0),
                onPrimary: Qt.hsla(h, sMid, 0.98, 1.0),
                primaryContainer: Qt.hsla(h, Math.min(sHigh * 0.55, 0.55), 0.88, 1.0),
                onPrimaryContainer: Qt.hsla(h, sHigh, 0.09, 1.0),
                onSurface: Qt.hsla(h, sMid, 0.09, 1.0),
                onSurfaceVariant: Qt.hsla(h, sSurf, 0.28, 1.0),
                outline: Qt.hsla(h, sSurf, 0.72, 1.0)
            };
        }
    }
}
