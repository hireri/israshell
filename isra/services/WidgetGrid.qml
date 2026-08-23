pragma Singleton
import QtQuick
import Quickshell
import qs.style
import qs.services

Singleton {
    id: root

    readonly property real cellSize: Config.desktopGrid?.cellSize ?? 50
    readonly property real gutter: Config.desktopGrid?.gutter ?? 8
    readonly property real margin: Config.desktopGrid?.margin ?? 24

    function _w(screen): real {
        return screen?.width ?? 1920;
    }
    function _h(screen): real {
        return screen?.height ?? 1080;
    }

    function _barReservation(): real {
        const barMode = Config.bar.transparency === 2 ? (Config.bar.mode === 2 ? 2 : 0) : Config.bar.mode;
        if (barMode === 2)
            return 56;
        if (Config.bar.transparency === 2 && !GameModeService.active)
            return 34;
        return 44;
    }

    function _dockReservation(): real {
        if (!Config.floatingDock.enabled || !Config.floatingDock.exclusiveZone)
            return 0;
        const hasContent = Config.floatingDock.showLauncher || Config.floatingDock.showTrash || Config.floatingDock.showMusicPlayer || (Config.pinnedApps ?? []).length > 0;
        if (!hasContent)
            return 0;
        const iconSize = Config.floatingDock.iconSize ?? 32;
        const itemCellSize = iconSize + 12;
        const pillThickness = itemCellSize + 6 * 2;
        return pillThickness + 8;
    }

    function insets(screen): var {
        const barR = root._barReservation();
        const dockR = root._dockReservation();
        const dockEdge = Config.floatingDock.edge;
        return {
            top: root.margin + (Config.bar.position === 0 ? barR : 0) + (dockEdge === 0 ? dockR : 0),
            bottom: root.margin + (Config.bar.position === 1 ? barR : 0) + (dockEdge === 1 ? dockR : 0),
            left: root.margin + (dockEdge === 2 ? dockR : 0),
            right: root.margin + (dockEdge === 3 ? dockR : 0)
        };
    }

    function columns(screen): int {
        const ins = root.insets(screen);
        const usable = root._w(screen) - ins.left - ins.right + root.gutter;
        return Math.max(1, Math.floor(usable / (root.cellSize + root.gutter)));
    }
    function rows(screen): int {
        const ins = root.insets(screen);
        const usable = root._h(screen) - ins.top - ins.bottom + root.gutter;
        return Math.max(1, Math.floor(usable / (root.cellSize + root.gutter)));
    }

    function cellWidth(screen): real {
        return root.cellSize;
    }
    function cellHeight(screen): real {
        return root.cellSize;
    }

    function cellX(screen, col): real {
        return root.insets(screen).left + col * (root.cellSize + root.gutter);
    }
    function cellY(screen, row): real {
        return root.insets(screen).top + row * (root.cellSize + root.gutter);
    }
    function spanWidth(screen, w): real {
        const n = Math.max(1, w);
        return n * root.cellSize + (n - 1) * root.gutter;
    }
    function spanHeight(screen, h): real {
        const n = Math.max(1, h);
        return n * root.cellSize + (n - 1) * root.gutter;
    }
    function cellRect(screen, col, row, w, h): rect {
        return Qt.rect(root.cellX(screen, col), root.cellY(screen, row), root.spanWidth(screen, w), root.spanHeight(screen, h));
    }

    function nearestCol(screen, px): int {
        return Math.round((px - root.insets(screen).left) / (root.cellSize + root.gutter));
    }
    function nearestRow(screen, py): int {
        return Math.round((py - root.insets(screen).top) / (root.cellSize + root.gutter));
    }

    function spanFromPixels(screen, pxW, pxH): var {
        return {
            w: Math.max(1, Math.round((pxW + root.gutter) / (root.cellSize + root.gutter))),
            h: Math.max(1, Math.round((pxH + root.gutter) / (root.cellSize + root.gutter)))
        };
    }

    function clampCell(screen, col, row, w, h): var {
        return {
            col: Math.max(0, Math.min(col, Math.max(0, root.columns(screen) - w))),
            row: Math.max(0, Math.min(row, Math.max(0, root.rows(screen) - h)))
        };
    }

    function clampSpan(screen, w, h): var {
        return {
            w: Math.max(1, Math.min(w, root.columns(screen))),
            h: Math.max(1, Math.min(h, root.rows(screen)))
        };
    }


    function placementOf(entry, screen): var {
        if (!entry)
            return { col: 0, row: 0, w: 1, h: 1 };
        const w = entry.span?.w ?? 1;
        const h = entry.span?.h ?? 1;
        return root._clampPlacement({ col: entry.cell?.col ?? 0, row: entry.cell?.row ?? 0, w: w, h: h }, screen);
    }

    function _clampPlacement(p, screen): var {
        const span = root.clampSpan(screen, p.w, p.h);
        const cell = root.clampCell(screen, p.col, p.row, span.w, span.h);
        return { col: cell.col, row: cell.row, w: span.w, h: span.h };
    }

    function _entries(screen): var {
        return (Config.desktopWidgets ?? []).filter(e => e && e.enabled !== false && e.cell && e.screen === screen?.name && !DesktopWidgetService.isFreeform(e));
    }

    function occupancy(screen, excludeId): var {
        const map = ({});
        for (const entry of root._entries(screen)) {
            if (entry.id === excludeId)
                continue;
            const p = root.placementOf(entry, screen);
            for (let c = p.col; c < p.col + p.w; c++)
                for (let r = p.row; r < p.row + p.h; r++)
                    map[c + "," + r] = entry.id;
        }
        return map;
    }

    function fitsIn(screen, col, row, w, h, occupied): bool {
        if (col < 0 || row < 0 || col + w > root.columns(screen) || row + h > root.rows(screen))
            return false;
        for (let c = col; c < col + w; c++)
            for (let r = row; r < row + h; r++)
                if (occupied[c + "," + r] !== undefined)
                    return false;
        return true;
    }

    function fits(screen, col, row, w, h, excludeId): bool {
        return root.fitsIn(screen, col, row, w, h, root.occupancy(screen, excludeId));
    }

    function nearestFreeCell(screen, col, row, w, h, excludeId): var {
        const occupied = root.occupancy(screen, excludeId);
        const start = root.clampCell(screen, col, row, w, h);
        if (root.fitsIn(screen, start.col, start.row, w, h, occupied))
            return start;

        const maxRing = Math.max(root.columns(screen), root.rows(screen));
        for (let ring = 1; ring <= maxRing; ring++) {
            for (let dc = -ring; dc <= ring; dc++) {
                for (let dr = -ring; dr <= ring; dr++) {
                    if (Math.abs(dc) !== ring && Math.abs(dr) !== ring)
                        continue;
                    if (root.fitsIn(screen, start.col + dc, start.row + dr, w, h, occupied))
                        return { col: start.col + dc, row: start.row + dr };
                }
            }
        }
        return null;
    }

    function firstFreeCell(screen, w, h, excludeId): var {
        const occupied = root.occupancy(screen, excludeId);
        for (let r = 0; r + h <= root.rows(screen); r++)
            for (let c = 0; c + w <= root.columns(screen); c++)
                if (root.fitsIn(screen, c, r, w, h, occupied))
                    return { col: c, row: r };
        return { col: 0, row: 0 };
    }
}
