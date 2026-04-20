import QtQuick
import QtQuick.Layouts
import qs.style

ColumnLayout {
    id: root

    property int currentPage: 0
    property real outerRadius: 18
    property real innerRadius: 6

    signal navigate(int page)

    default property alias items: root.children

    spacing: 3

    onCurrentPageChanged: _update()
    onChildrenChanged: _update()
    Component.onCompleted: _update()

    function _sidebarKids() {
        const kids = [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].hasOwnProperty("page"))
                kids.push(children[i]);
        }
        return kids;
    }

    function _update() {
        const kids = _sidebarKids();
        for (let i = 0; i < kids.length; i++) {
            const k = kids[i];
            const isOnly = kids.length === 1;
            const isFirst = i === 0;
            const isLast = i === kids.length - 1;

            k.topRadius = (isOnly || isFirst) ? root.outerRadius : root.innerRadius;
            k.bottomRadius = (isOnly || isLast) ? root.outerRadius : root.innerRadius;
            k.active = (k.page === root.currentPage);
        }
    }
}
