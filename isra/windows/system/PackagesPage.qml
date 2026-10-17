pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.style
import qs.services
import qs.windows
import qs.windows.components
import "format.js" as Fmt

PageBase {
    id: page

    title: Localization.t("systemApp.packages")
    subtitle: Localization.t("systemApp.packages_sub")

    property bool newsLatched: false
    property bool newsFirst: false
    property real lastUpdate: 0

    readonly property var sources: [
        { id: "updates.repo", key: "repo", name: "Repo", shape: "cookie6", badge: "R" },
        { id: "updates.aur", key: "aur", name: "AUR", shape: "sunny", badge: "A" },
        { id: "updates.flatpak", key: "flatpak", name: "Flatpak", shape: "clover4", badge: "F" }
    ]
    readonly property var liveSources: page.sources.filter(s => page.live(s.id))
    readonly property var pending: {
        const out = [];
        for (const s of page.liveSources)
            for (const it of (HealthService.result(s.id)?.items ?? []))
                out.push({ name: it.name, from: it.from, to: it.to, source: s.key });
        return out;
    }
    readonly property var counts: ({
            repo: HealthService.result("updates.repo")?.count ?? 0,
            aur: HealthService.result("updates.aur")?.count ?? 0,
            flatpak: HealthService.result("updates.flatpak")?.count ?? 0
        })

    readonly property var newsResult: HealthService.result("pkg.news")
    readonly property var news: page.newsResult?.items ?? []
    readonly property int unreadCount: page.news.filter(n => n.unread).length
    readonly property bool manual: page.news.some(n => n.unread && n.kind === "manual")
    readonly property bool restart: page.pending.some(u => Fmt.needsRestart(u.name))
    readonly property bool checking: !HealthService.probed || (!HealthService.result("updates.repo") && HealthService.running)

    function live(id: string): bool {
        return HealthService.isApplicable(id) && HealthService.isEnabled(id);
    }

    function latchNews(): void {
        if (page.newsLatched || !page.newsResult)
            return;
        page.newsLatched = true;
        page.newsFirst = page.news.some(n => n.unread);
    }

    onNewsResultChanged: page.latchNews()
    onPendingChanged: lastProc.running = true

    Component.onCompleted: {
        HealthService.registerView();
        page.latchNews();
    }
    Component.onDestruction: HealthService.unregisterView()

    Process {
        id: lastProc
        running: true
        command: ["sh", "-c", "grep -a 'starting full system upgrade' /var/log/pacman.log 2>/dev/null | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: page.lastUpdate = Fmt.pacmanTime(this.text)
        }
    }

    HealthOffTile {
        Layout.fillWidth: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 1
        rowSpacing: 16
        columnSpacing: 0
        visible: HealthService.enabled

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: page.newsFirst ? 0 : 1
            spacing: 8
            visible: page.news.length > 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                SectionLabel {
                    Layout.fillWidth: true
                    text: Localization.t("systemApp.news")
                }

                ActionButton {
                    visible: page.unreadCount > 0
                    icon: "check"
                    label: Localization.t("systemApp.mark_all_read")
                    onClicked: HealthService.markNewsSeen()
                }

                ActionButton {
                    visible: carousel.contentWidth > carousel.width
                    icon: "chevron-left"
                    enabled: carousel.contentX > 0
                    onClicked: page.scrollNews(-1)
                }

                ActionButton {
                    visible: carousel.contentWidth > carousel.width
                    icon: "chevron-right"
                    enabled: carousel.contentX < carousel.contentWidth - carousel.width - 1
                    onClicked: page.scrollNews(1)
                }
            }

            ListView {
                id: carousel
                Layout.fillWidth: true
                Layout.preferredHeight: 156
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                model: page.news
                boundsBehavior: Flickable.StopAtBounds

                delegate: NewsCard {
                    id: card
                    required property var modelData
                    required property int index

                    width: card.index === 0 ? Math.min(360, ListView.view.width) : 236
                    height: ListView.view.height
                    featured: card.index === 0
                    title: card.modelData.title
                    summary: card.modelData.summary ?? ""
                    kind: card.modelData.kind ?? "other"
                    unread: card.modelData.unread
                    date: card.modelData.date
                    onClicked: HealthService.runAction("openNews", card.modelData.link)
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.row: page.newsFirst ? 1 : 0
            columns: width > 640 ? 2 : 1
            columnSpacing: 10
            rowSpacing: 10

            Hero {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.horizontalStretchFactor: 3
                Layout.preferredWidth: 1
                tone: page.checking ? "neutral" : page.manual ? "warn" : "ok"
                shape: "cookie6"
                icon: page.pending.length === 0 && !page.checking ? "check" : "inventory-2"
                title: page.checking ? Localization.t("systemApp.sub_checking") : page.pending.length === 0 ? Localization.t("systemApp.pkg_up_to_date") : page.pending.length === 1 ? Localization.t("systemApp.pkg_updates_one") : Localization.t("systemApp.pkg_updates_many").replace("%1", page.pending.length)
                sublabel: page.manual ? Localization.t("systemApp.pkg_read_news") : page.lastUpdate > 0 ? Localization.t("systemApp.pkg_last_updated").replace("%1", Fmt.ago(page.lastUpdate)) : ""

                Pill {
                    visible: page.restart
                    implicitHeight: 24
                    dot: false
                    tone: "warn"
                    text: Localization.t("systemApp.pkg_restart_after")
                }

                Pill {
                    visible: depsInfo.sev === "warn" || depsInfo.sev === "bad"
                    implicitHeight: 24
                    dot: false
                    tone: depsInfo.tone
                    text: depsInfo.label + " · " + depsInfo.text

                    CheckInfo {
                        id: depsInfo
                        checkId: "pkg.deps"
                    }
                }

                actions: [
                    ActionButton {
                        visible: page.pending.length > 0
                        primary: true
                        icon: "download-for-offline"
                        label: Localization.t("systemApp.update_all")
                        onClicked: HealthService.runAction("update", "")
                    },
                    ActionButton {
                        icon: "restart"
                        enabled: !HealthService.running
                        onClicked: HealthService.refresh()
                    }
                ]
            }

            SourcesCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.horizontalStretchFactor: 2
                Layout.preferredWidth: 1
                Layout.preferredHeight: 132
                sources: page.liveSources.map(s => ({ name: s.name, shape: s.shape, n: page.counts[s.key] }))
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: 2
            spacing: 6
            visible: page.pending.length > 0

            SectionLabel {
                text: Localization.t("systemApp.pending_updates")
            }

            GridLayout {
                Layout.fillWidth: true
                columns: Math.max(1, Math.min(page.liveSources.length, width > 700 ? 3 : width > 460 ? 2 : 1))
                columnSpacing: 10
                rowSpacing: 10
                uniformCellWidths: true
                uniformCellHeights: true

                Repeater {
                    model: page.liveSources

                    UpdateGroup {
                        id: group
                        required property var modelData
                        readonly property var res: HealthService.result(group.modelData.id)

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        name: group.modelData.name
                        shape: group.modelData.shape
                        items: page.pending.filter(u => u.source === group.modelData.key)
                        note: group.modelData.key === "flatpak" && group.res?.apps !== undefined ? Localization.t("systemApp.pkg_flatpak_installed").replace("%1", group.res.apps).replace("%2", group.res.runtimes) : ""
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: 3
            spacing: 6

            SectionLabel {
                text: Localization.t("systemApp.pkg_maintenance")
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width > 560 ? 2 : 1
                columnSpacing: 10
                rowSpacing: 10
                uniformCellWidths: true

                MaintCard {
                    id: orphans
                    readonly property var res: HealthService.result("pkg.orphans")
                    Layout.fillWidth: true
                    visible: page.live("pkg.orphans")
                    checkId: "pkg.orphans"
                    icon: "delete"
                    value: !orphans.res ? "—" : orphans.res.count > 0 ? (orphans.res.bytes === null ? String(orphans.res.count) : Fmt.bytes(orphans.res.bytes)) : Localization.t("systemApp.det_none")
                    sublabel: (orphans.res?.count ?? 0) === 1 ? Localization.t("systemApp.pkg_unused_one") : (orphans.res?.count ?? 0) > 1 ? Localization.t("systemApp.pkg_unused_many").replace("%1", orphans.res.count) : ""

                    ActionButton {
                        visible: (orphans.res?.count ?? 0) > 0
                        icon: "delete"
                        label: Localization.t("systemApp.remove")
                        onClicked: HealthService.runAction("removeOrphans", "")
                    }
                }

                MaintCard {
                    id: pacnew
                    readonly property var res: HealthService.result("pkg.pacnew")
                    Layout.fillWidth: true
                    visible: page.live("pkg.pacnew")
                    checkId: "pkg.pacnew"
                    icon: "edit"
                    value: pacnew.res ? String(pacnew.res.count) : "—"
                    sublabel: (pacnew.res?.count ?? 0) === 1 ? Localization.t("systemApp.pkg_review_one") : (pacnew.res?.count ?? 0) > 1 ? Localization.t("systemApp.pkg_review_many") : ""

                    ActionButton {
                        visible: (pacnew.res?.count ?? 0) > 0
                        icon: "open-with"
                        label: Localization.t("systemApp.review")
                        onClicked: HealthService.runAction("pacdiff", "")
                    }
                }

                MaintCard {
                    id: cache
                    readonly property var res: HealthService.result("pkg.cache")
                    Layout.fillWidth: true
                    visible: page.live("pkg.cache")
                    checkId: "pkg.cache"
                    icon: "inventory-2"
                    value: cache.res ? Fmt.bytes(cache.res.bytes) : "—"

                    ActionButton {
                        visible: (cache.res?.bytes ?? 0) > 0
                        icon: "clear-all"
                        label: Localization.t("systemApp.clean")
                        onClicked: HealthService.runAction("cleanCache", "")
                    }
                }

                MaintCard {
                    id: deps
                    readonly property var res: HealthService.result("pkg.deps")
                    Layout.fillWidth: true
                    visible: page.live("pkg.deps")
                    checkId: "pkg.deps"
                    icon: "check"
                    value: !deps.res ? "—" : (deps.res.issues ?? []).length > 0 ? Localization.t("systemApp.det_dep_issues").replace("%1", deps.res.issues.length) : "OK"
                }
            }
        }
    }

    function scrollNews(dir: int): void {
        scrollAnim.to = Math.max(0, Math.min(carousel.contentWidth - carousel.width, carousel.contentX + dir * 260));
        scrollAnim.restart();
    }

    NumberAnimation {
        id: scrollAnim
        target: carousel
        property: "contentX"
        duration: 260
        easing.type: Easing.OutCubic
    }
}
