import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.style

Item {
    id: root

    property string query: ""
    signal launched

    property int selectedIndex: 0
    onQueryChanged: selectedIndex = 0

    function moveUp() {
        if (selectedIndex > 0)
            selectedIndex--;
    }
    function moveDown() {
        if (selectedIndex < list.count - 1)
            selectedIndex++;
    }
    function activateCurrent() {
        const entry = filteredApps.values[selectedIndex];
        if (entry) {
            entry.execute();
            root.launched();
        }
    }

    ScriptModel {
        id: filteredApps
        objectProp: "id"
        values: {
            const all = [...DesktopEntries.applications.values];
            const q = root.query.trim().toLowerCase();
            if (q === "")
                return all.sort((a, b) => a.name.localeCompare(b.name));
            return all.filter(d => d.name?.toLowerCase().includes(q) || d.genericName?.toLowerCase().includes(q) || d.keywords?.some(k => k.toLowerCase().includes(q)) || d.categories?.some(c => c.toLowerCase().includes(q))).sort((a, b) => {
                const an = a.name.toLowerCase(), bn = b.name.toLowerCase();
                const aS = an.startsWith(q), bS = bn.startsWith(q);
                if (aS && !bS)
                    return -1;
                if (!aS && bS)
                    return 1;
                return an.localeCompare(bn);
            });
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        model: filteredApps
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds

        currentIndex: root.selectedIndex
        highlightMoveDuration: 150
        highlightMoveVelocity: -1
        highlightFollowsCurrentItem: true

        highlight: Rectangle {
            radius: 10
            color: Colors.md3.secondary_container

            Rectangle {
                width: 3
                height: 22
                radius: 2
                color: Colors.md3.primary
                anchors {
                    left: parent.left
                    leftMargin: 4
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        delegate: Item {
            id: del
            required property var modelData
            required property int index

            width: list.width
            height: 48

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 0
                radius: 10
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.md3.on_surface
                    opacity: hov.pressed ? 0.12 : hov.containsMouse ? 0.06 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 80
                        }
                    }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 14

                    Item {
                        width: 32
                        height: 32
                        Layout.alignment: Qt.AlignVCenter

                        IconImage {
                            anchors.fill: parent
                            source: Quickshell.iconPath(del.modelData.icon ?? "", true)
                            visible: (del.modelData.icon ?? "") !== ""
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "󰘔"
                            color: Colors.md3.primary
                            font.pixelSize: 22
                            font.family: Config.fontFamily
                            visible: (del.modelData.icon ?? "") === ""
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: del.modelData.name ?? ""
                            color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            font.bold: root.selectedIndex === del.index
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: del.modelData.genericName ?? del.modelData.comment ?? ""
                            color: root.selectedIndex === del.index ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                            font.pixelSize: 11
                            font.family: Config.fontFamily
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: text !== ""
                            opacity: 0.8
                        }
                    }
                }

                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        del.modelData.execute();
                        root.launched();
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "No applications found"
            color: Colors.md3.on_surface_variant
            font.pixelSize: 13
            font.family: Config.fontFamily
            visible: list.count === 0 && root.query !== ""
            opacity: 0.5
        }
    }
}
