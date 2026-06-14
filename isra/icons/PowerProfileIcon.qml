import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property int profileMode: 1
    property color color: "white"
    property real iconSize: 24

    width: iconSize
    height: iconSize
    layer.enabled: true
    layer.samples: 4

    Shape {
        width: parent.width
        height: parent.height
        antialiasing: true
        y: parent.height

        ShapePath {
            strokeWidth: 0
            fillColor: root.color
            scale: Qt.size(root.width / 960, root.height / 960)

            PathSvg {
                path: {
                    if (root.profileMode === 0) return "M172-172q-11-11-11-28t11-28l55-55q-32-41-49.5-91T160-480q0-134 93-227t227-93h240q33 0 56.5 23.5T800-720v240q0 134-93 227t-227 93q-56 0-105.5-17.5T284-227l-56 55q-11 11-28 11t-28-11Zm162-162q11 13 28 12.5t29-12.5l157-157q12-12 12-28.5T548-548q-11-11-28-11t-28 11L334-390q-11 11-11 27.5t11 28.5Z"
                    if (root.profileMode === 2) return "M160-400q0-113 67-217t184-182q22-15 45.5-1.5T480-760v52q0 34 23.5 57t57.5 23q17 0 32.5-7.5T621-657q8-10 20.5-12.5T665-664q63 45 99 115t36 149q0 88-43 160.5T644-125q17-24 26.5-52.5T680-238q0-40-15-75.5T622-377L480-516 339-377q-29 29-44 64t-15 75q0 32 9.5 60.5T316-125q-70-42-113-114.5T160-400Zm320-4 85 83q17 17 26 38t9 45q0 49-35 83.5T480-120q-50 0-85-34.5T360-238q0-23 9-44.5t26-38.5l85-83Z"
                    return "M536-343q26-26 24-60.5T530-459q-60-47-122-87t-125-80q-14-9-26 3t-3 26q40 63 80 125.5T418-347q20 29 56 29.5t62-25.5ZM205-160q-22 0-40.5-9.5T135-198q-28-48-42-100.5T79-406q0-35 7-69t21-66q6-15 22-20.5t30 2.5q14 8 19.5 23.5T178-504q-9 24-14 49t-5 51q0 44 11.5 85.5T205-240h551q21-36 32.5-76.5T800-400q0-133-93.5-226.5T480-720q-27 0-53 5t-51 14q-16 5-31-.5T322-722q-8-15-2-30.5t21-21.5q33-13 68-19.5t71-6.5q83 0 155.5 31.5t127 86q54.5 54.5 86 127T880-400q0 54-14 105t-40 97q-11 19-30 28.5t-40 9.5H205Zm274-238Z"
                }
            }
        }
    }
}