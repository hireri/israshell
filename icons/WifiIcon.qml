import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color color: "white"
    property real iconSize: 24
    property int strength: 0
    property bool secured: false

    width: iconSize
    height: iconSize
    layer.enabled: true
    layer.samples: 4

    Shape {
        width: parent.width
        height: parent.height
        y: parent.height
        antialiasing: true

        ShapePath {
            strokeWidth: 0
            fillColor: root.color
            scale: Qt.size(root.width / 960, root.height / 960)

            PathSvg {
                path: root.strength >= 80 ? "M423-177 61-539q-12-12-18-27t-6-30q0-17 7-32.5T65-656q82-71 195-107.5T480-800q107 0 220 36.5T895-656q14 12 21 27.5t7 32.5q0 15-6 30t-18 27L537-177q-12 12-27 18t-30 6q-15 0-30-6t-27-18Z" : root.strength >= 50 ? "M423-177 61-539q-12-12-18-27t-6-30q0-17 7-32.5T65-656q82-71 195-107.5T480-800q107 0 220 36.5T895-656q14 12 21 27.5t7 32.5q0 15-6 30t-18 27L537-177q-12 12-27 18t-30 6q-15 0-30-6t-27-18ZM232-482q53-38 116-59.5T480-563q69 0 132 21.5T728-482l116-116q-78-59-170.5-90.5T480-720q-101 0-193.5 31.5T116-598l116 116Z" : root.strength >= 25 ? "M423-177 61-539q-12-12-18-27t-6-30q0-17 7-32.5T65-656q82-71 195-107.5T480-800q107 0 220 36.5T895-656q14 12 21 27.5t7 32.5q0 15-6 30t-18 27L537-177q-12 12-27 18t-30 6q-15 0-30-6t-27-18ZM299-415q38-28 84-43.5t97-15.5q51 0 97 15.5t84 43.5l183-183q-78-59-170.5-90.5T480-720q-101 0-193.5 31.5T116-598l183 183Z" : root.strength > 0 ? "M361-353q25-18 55.5-28t63.5-10q33 0 63.5 10t55.5 28l245-245q-78-59-170.5-90.5T480-720q-101 0-193.5 31.5T116-598l245 245Zm62 176L61-539q-12-12-18-27t-6-30q0-17 7-32.5T65-656q82-71 195-107.5T480-800q107 0 220 36.5T895-656q14 12 21 27.5t7 32.5q0 15-6 30t-18 27L537-177q-12 12-27 18t-30 6q-15 0-30-6t-27-18Z" : "m760-223-56 55q-11 11-27.5 11.5T648-168q-11-11-11-28t11-28l56-56-56-56q-11-11-11-28t11-28q11-11 28-11t28 11l56 56 56-56q11-11 27.5-11t28.5 11q12 12 12 28.5T872-335l-55 55 55 56q11 11 11.5 27.5T872-168q-11 11-28 11t-28-11l-56-55ZM480-800q113 0 219 35.5T893-660q15 11 22.5 27.5T923-599q0 17-6.5 33T897-537l-46 46q-12 11-28.5 11.5T794-491q-12-12-12-28.5t12-28.5l50-50q-79-60-172-91t-192-31q-99 0-192 31t-172 91l364 364 11-11q12-12 28.5-12t28.5 12q12 12 12 28.5T548-188l-11 11q-12 12-27 18t-30 6q-15 0-30-6t-27-18L63-537q-13-13-19-28.5T38-598q0-17 7-33.5T67-660q88-69 194-104.5T480-800Zm0 323Z"
            }
        }
    }

    Shape {
        width: parent.width
        height: parent.height
        y: parent.height
        antialiasing: true
        visible: root.secured && root.strength > 0

        ShapePath {
            strokeWidth: 0
            fillColor: root.color
            scale: Qt.size(root.width / 24, root.height / 24)

            PathSvg {
                path: "M22,16v-1c0-1.1-0.9-2-2-2s-2,0.9-2,2v1c-0.55,0-1,0.45-1,1v3c0,0.55,0.45,1,1,1h4c0.55,0,1-0.45,1-1v-3C23,16.45,22.55,16,22,16z M21,16h-2v-1c0-0.55,0.45-1,1-1s1,0.45,1,1V16z"
            }
        }
    }
}
