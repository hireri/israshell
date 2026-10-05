import QtQuick
import qs.style

Item {
    id: root

    property var    cfg: Config.clock

    property var    currentTime
    property color  textColor
    property color  subColor
    property int    halign
    property bool   showSeconds
    property bool   is12h
    property int    analogSize
    property bool   immediateShapes: false

    property string clockFont: "Google Sans Flex"
    readonly property real size: root.cfg.size ?? 100
    readonly property real dateTextSize: Math.max(11, Math.round(root.size * 0.25 * (root.cfg.dateSize ?? 100) / 100))
    readonly property real textDateGap:  root.cfg.dateSpacing ?? -5

    property int    fontWeight:    root.cfg.hourWeight    ?? 500
    property real   subWeight:     root.cfg.minuteWeight  ?? 300
    property real   fontWidth:     root.cfg.fontWidth     ?? 100
    property real   fontRoundness: root.cfg.fontRoundness ?? 0
    property real   fontSlant:     root.cfg.fontSlant     ?? 0

    function tileFill(role)   { return Colors.md3[role + "_container"] ?? Colors.md3.surface_container_highest; }
    function tileOnFill(role) { return Colors.md3["on_" + role + "_container"] ?? Colors.md3.on_surface; }

    readonly property string digitStyle: root.cfg.digitStyle ?? "text"
    readonly property bool   grid:       root.digitStyle === "grid"
    readonly property bool   tiled:      root.digitStyle === "tiles"

    readonly property bool showPeriod: root.is12h && (root.cfg.showAmPm ?? true)
    readonly property bool pm: (root.currentTime?.getHours() ?? 0) >= 12

    function periodWord(isPm) {
        const word = Localization.t(isPm ? "clock.pm" : "clock.am");
        return Config.hourFormat === 2 ? word : word.toLowerCase();
    }

    readonly property bool isGoogleSansFlex: root.clockFont === "Google Sans Flex"

    readonly property var mainAxes: ({ "wght": root.fontWeight, "wdth": root.fontWidth, "ROND": root.fontRoundness, "slnt": -root.fontSlant })
    readonly property var subAxes:  ({ "wght": root.subWeight,  "wdth": root.fontWidth, "ROND": root.fontRoundness, "slnt": -root.fontSlant })
}
