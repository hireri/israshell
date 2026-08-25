import QtQuick
import Quickshell.Widgets
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property string username: ""

    readonly property var _state: GithubService.stateFor(root.username)
    readonly property var _weeks: root._state.weeks ?? []
    readonly property string _error: root._state.error
    readonly property int _totalContributions: root._state.totalContributions ?? 0

    onUsernameChanged: GithubService.ensureFetched(root.username)
    Component.onCompleted: GithubService.ensureFetched(root.username)

    readonly property int _cols: root._weeks.length
    readonly property real _gap: 3
    readonly property real _padding: 16
    readonly property real _footerH: 16
    readonly property real _footerGap: 10

    readonly property real _minCell: 8
    readonly property real _maxCell: 15

    readonly property real _cell: {
        if (root._cols === 0)
            return 0;
        const availH = root.height - root._padding * 2 - root._footerH - root._footerGap;
        const rawCell = (availH - 6 * root._gap) / 7;
        return Math.max(root._minCell, Math.min(rawCell, root._maxCell));
    }

    readonly property int _visibleCols: {
        if (root._cols === 0 || root._cell === 0)
            return 0;
        const availW = root.width - root._padding * 2;
        const fit = Math.floor((availW + root._gap) / (root._cell + root._gap));
        return Math.max(1, Math.min(fit, root._cols));
    }

    readonly property var _visibleWeeks: root._visibleCols > 0 ? root._weeks.slice(-root._visibleCols) : []

    readonly property int _streak: {
        const days = [];
        for (const week of root._weeks)
            for (const day of week.contributionDays)
                days.push(day);

        let streak = 0;
        for (let i = days.length - 1; i >= 0; i--) {
            const count = days[i].contributionCount ?? 0;
            if (count > 0) {
                streak++;
            } else if (i === days.length - 1) {
                continue;
            } else {
                break;
            }
        }
        return streak;
    }

    function _levelColor(level) {
        if (level <= 0)
            return Qt.alpha(Colors.md3.on_surface, 0.08);
        return Qt.alpha(Colors.md3.primary, 0.25 + level * 0.1875);
    }

    function _colorFor(count) {
        if (count <= 0)
            return root._levelColor(0);
        const level = count >= 10 ? 4 : count >= 6 ? 3 : count >= 3 ? 2 : 1;
        return root._levelColor(level);
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Colors.md3.surface_container_high
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)
    }

    Text {
        anchors.centerIn: parent
        anchors.margins: 8
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: root.username === ""
        text: Localization.t("githubHeatmap.set_username")
        color: Colors.md3.on_surface_variant
        font.family: Config.fontFamily
        font.pixelSize: 12
    }

    Text {
        anchors.centerIn: parent
        anchors.margins: 8
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: root.username !== "" && root._error === "no_token"
        text: Localization.t("githubHeatmap.no_token")
        color: Colors.md3.on_surface_variant
        font.family: Config.fontFamily
        font.pixelSize: 12
    }

    Text {
        anchors.centerIn: parent
        anchors.margins: 8
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: root.username !== "" && root._error !== "" && root._error !== "no_token"
        text: Localization.t("githubHeatmap.fetch_failed")
        color: Colors.md3.on_surface_variant
        font.family: Config.fontFamily
        font.pixelSize: 12
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root._padding
        visible: root._error === "" && root._cols > 0

        Item {
            id: grid
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: root._visibleCols * root._cell + Math.max(0, root._visibleCols - 1) * root._gap
            height: 7 * root._cell + 6 * root._gap

            Repeater {
                model: root._visibleWeeks

                delegate: Item {
                    id: weekCol
                    required property var modelData
                    required property int index

                    width: root._cell
                    height: grid.height
                    x: weekCol.index * (root._cell + root._gap)

                    Repeater {
                        model: weekCol.modelData.contributionDays

                        delegate: Rectangle {
                            id: dayCell
                            required property var modelData

                            width: root._cell
                            height: root._cell
                            radius: Math.max(1, root._cell * 0.25)
                            y: dayCell.modelData.weekday * (root._cell + root._gap)
                            color: root._colorFor(dayCell.modelData.contributionCount)
                        }
                    }
                }
            }
        }

        Item {
            id: footer
            anchors.top: grid.bottom
            anchors.topMargin: root._footerGap
            anchors.left: parent.left
            anchors.right: parent.right
            height: root._footerH

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                ClippingRectangle {
                    id: avatar
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: Colors.md3.surface_container_highest
                    visible: root.username !== ""

                    Image {
                        anchors.fill: parent
                        source: root.username !== "" ? "https://github.com/" + root.username + ".png?size=32" : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                    }
                }

                Text {
                    text: root.username
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                Text {
                    text: root._totalContributions + " " + Localization.t("githubHeatmap.contributions")
                    color: Colors.md3.primary
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "local-fire-department"
                    filled: root._streak > 0
                    iconSize: 12
                    color: Colors.md3.primary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root._streak + " " + Localization.t("githubHeatmap.day_streak")
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }

            Row {
                id: legend
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Localization.t("githubHeatmap.less")
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 9
                }

                Repeater {
                    model: 5
                    delegate: Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 2
                        color: root._levelColor(index)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Localization.t("githubHeatmap.more")
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 9
                }
            }
        }
    }
}
