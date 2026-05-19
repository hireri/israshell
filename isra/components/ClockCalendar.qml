import QtQuick
import Quickshell
import qs.style
import qs.icons

Item {
    id: root

    required property bool isOpen

    readonly property int todayDay: new Date().getDate()
    readonly property int todayMonth: new Date().getMonth()
    readonly property int todayYear: new Date().getFullYear()

    property int viewYear: todayYear
    property int viewMonth: todayMonth

    property int selDay: todayDay
    property int selMonth: todayMonth
    property int selYear: todayYear

    readonly property bool isTodaySel: selDay === todayDay && selMonth === todayMonth && selYear === todayYear

    property string liveTime: ""
    property string liveSecs: ""
    property string liveAmPm: ""
    property string liveDayName: ""
    property string liveFullDate: ""

    property string weatherTemp: "—"
    property string weatherHigh: "—"
    property string weatherLow: "—"
    property string weatherDesc: "loading..."
    property string weatherHumid: "—"
    property string weatherUvi: "—"
    property string weatherAqi: "32"
    property string weatherCode: "116"

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    function init() {
        const now = new Date();
        viewYear = now.getFullYear();
        viewMonth = now.getMonth();
        selDay = now.getDate();
        selMonth = now.getMonth();
        selYear = now.getFullYear();
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear--;
        } else
            viewMonth--;
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear++;
        } else
            viewMonth++;
    }

    function buildDays(year, month) {
        const days = [];
        const first = new Date(year, month, 1);
        const lastDate = new Date(year, month + 1, 0).getDate();
        let startDow = first.getDay();
        if (Config.weekMonday)
            startDow = (startDow + 6) % 7;
        const prevLastDate = new Date(year, month, 0).getDate();
        const prevM = month === 0 ? 11 : month - 1;
        const prevY = month === 0 ? year - 1 : year;
        for (let i = startDow - 1; i >= 0; i--)
            days.push({
                day: prevLastDate - i,
                month: prevM,
                year: prevY,
                isCurrentMonth: false
            });
        for (let d = 1; d <= lastDate; d++)
            days.push({
                day: d,
                month: month,
                year: year,
                isCurrentMonth: true
            });
        const nextM = month === 11 ? 0 : month + 1;
        const nextY = month === 11 ? year + 1 : year;
        let nd = 1;
        while (days.length < 42)
            days.push({
                day: nd++,
                month: nextM,
                year: nextY,
                isCurrentMonth: false
            });
        return days;
    }

    function isLeapYear(y) {
        return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;
    }

    function dayOfYear(d, m, y) {
        return Math.floor((new Date(y, m, d) - new Date(y, 0, 1)) / 86400000) + 1;
    }

    function weekNumber(d, m, y) {
        const dt = new Date(y, m, d), s = new Date(y, 0, 1);
        return Math.ceil(((dt - s) / 86400000 + s.getDay() + 1) / 7);
    }

    function dayName(d, m, y) {
        return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][new Date(y, m, d).getDay()];
    }

    function monthName(m) {
        return ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][m];
    }

    function weekCount(year, month) {
        let startDow = new Date(year, month, 1).getDay();
        if (Config.weekMonday)
            startDow = (startDow + 6) % 7;
        return Math.ceil((startDow + new Date(year, month + 1, 0).getDate()) / 7);
    }

    readonly property var currentDays: buildDays(viewYear, viewMonth)

    readonly property real selYearProgress: {
        const dy = dayOfYear(selDay, selMonth, selYear);
        const total = isLeapYear(selYear) ? 366 : 365;
        return dy / total;
    }

    readonly property var fixedHolidays: ({
            "01-01": "New Year's Day",
            "01-06": "Epiphany",
            "04-25": "Liberation Day",
            "05-01": "Labour Day",
            "06-02": "Republic Day",
            "08-15": "Ferragosto",
            "11-01": "All Saints' Day",
            "12-08": "Immaculate Conception",
            "12-25": "Christmas Day",
            "12-26": "St. Stephen's Day",
            "02-14": "Valentine's Day",
            "03-08": "Women's Day",
            "04-01": "April Fools'",
            "04-22": "Earth Day",
            "10-31": "Halloween",
            "12-31": "New Year's Eve"
        })

    function easterDate(year) {
        const a = year % 19, b = Math.floor(year / 100), c = year % 100;
        const d = Math.floor(b / 4), e = b % 4, f = Math.floor((b + 8) / 25);
        const g = Math.floor((b - f + 1) / 3), h = (19 * a + b - d - g + 15) % 30;
        const i = Math.floor(c / 4), k = c % 4;
        const l = (32 + 2 * e + 2 * i - h - k) % 7;
        const m = Math.floor((a + 11 * h + 22 * l) / 451);
        const month = Math.floor((h + l - 7 * m + 114) / 31) - 1;
        const day = ((h + l - 7 * m + 114) % 31) + 1;
        return new Date(year, month, day);
    }

    function holidayFor(day, month, year) {
        const key = String(month + 1).padStart(2, '0') + '-' + String(day).padStart(2, '0');
        if (fixedHolidays[key])
            return fixedHolidays[key];

        const e = easterDate(year || new Date().getFullYear());
        const fmt = d => String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
        const mon = new Date(e);
        mon.setDate(mon.getDate() + 1);

        if (key === fmt(e))
            return "Easter Sunday";
        if (key === fmt(mon))
            return "Easter Monday";
        return "";
    }

    readonly property string currentHoliday: holidayFor(selDay, selMonth, selYear)

    readonly property string selRelativeLabel: {
        const today = new Date(todayYear, todayMonth, todayDay);
        const sel = new Date(selYear, selMonth, selDay);
        const diff = Math.round((sel - today) / 86400000);
        if (diff === -1)
            return "yesterday";
        if (diff === 0)
            return "today";
        if (diff === 1)
            return "tomorrow";
        if (diff < 0)
            return Math.abs(diff) + " days ago";
        return "in " + diff + " days";
    }

    readonly property string selProseTop: {
        const d = new Date(selYear, selMonth, selDay);
        return dayName(selDay, selMonth, selYear) + ", " + Qt.formatDate(d, "dd MMMM yyyy");
    }

    readonly property string selProseBottom: {
        const dy = dayOfYear(selDay, selMonth, selYear);
        const total = isLeapYear(selYear) ? 366 : 365;
        const wn = weekNumber(selDay, selMonth, selYear);
        const rem = total - dy;
        return "Week " + wn + "  ·  " + rem + " day" + (rem !== 1 ? "s" : "") + " left.";
    }

    function getWeatherIconComponent() {
        const c = parseInt(root.weatherCode);
        if (c === 113)
            return sunnyComponent;
        if (c === 116)
            return partlyCloudyComponent;
        if (c === 119 || c === 122 || c === 143)
            return cloudyComponent;
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359].includes(c))
            return rainComponent;
        if ([200, 386, 389].includes(c))
            return stormComponent;
        if ([227, 230, 320, 323, 326, 329, 332, 335, 338, 368, 371].includes(c))
            return snowComponent;
        return partlyCloudyComponent;
    }

    Component {
        id: sunnyComponent
        WbSunnyIcon {
            iconSize: 42
            color: "#f9bc02"
        }
    }
    Component {
        id: partlyCloudyComponent
        PartlyCloudyDayIcon {
            iconSize: 42
            color: Colors.md3.primary
        }
    }
    Component {
        id: cloudyComponent
        CloudyIcon {
            iconSize: 42
            color: Qt.alpha(Colors.md3.on_surface, 0.7)
        }
    }
    Component {
        id: rainComponent
        RainyIcon {
            iconSize: 42
            color: "#a2c9ff"
        }
    }
    Component {
        id: stormComponent
        ThunderstormIcon {
            iconSize: 42
            color: "#dbe1ff"
        }
    }
    Component {
        id: snowComponent
        SnowyIcon {
            iconSize: 42
            color: "#ffffff"
        }
    }

    function updateWeather() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "https://wttr.in/?format=j1");
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    var cur = data.current_condition[0];
                    var today = data.weather[0];

                    root.weatherTemp = (Config.useFarenheit ? cur.temp_F : cur.temp_C) + "°";
                    root.weatherDesc = cur.weatherDesc[0].value;
                    root.weatherHigh = (Config.useFarenheit ? today.maxtempF : today.maxtempC) + "°";
                    root.weatherLow = (Config.useFarenheit ? today.mintempF : today.mintempC) + "°";
                    root.weatherHumid = cur.humidity + "%";
                    root.weatherUvi = cur.uvIndex || "0";
                    root.weatherCode = cur.weatherCode;
                } catch (e) {
                    console.log("Weather parse error:", e);
                }
            }
        };
        xhr.send();
    }

    Timer {
        interval: 100
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date();
            const fmt12 = Config.hourFormat !== 0;
            const h = now.getHours();
            const m = now.getMinutes();
            const hDisp = fmt12 ? (h % 12 || 12) : h;
            root.liveTime = String(hDisp).padStart(2, '0') + ":" + String(m).padStart(2, '0');
            root.liveSecs = String(now.getSeconds()).padStart(2, '0');

            root.liveAmPm = Config.hourFormat === 1 ? " am" : Config.hourFormat === 2 ? " AM" : "";
            root.liveDayName = Qt.formatDate(now, "dddd");
            root.liveFullDate = Qt.formatDate(now, "dd MMMM yyyy");
        }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateWeather()
    }

    Rectangle {
        id: card
        property bool _ready: false
        Component.onCompleted: Qt.callLater(() => _ready = true)

        y: {
            const open = _ready && root.isOpen;
            if (Config.barPosition === 0)
                return open ? 8 : -(height + 8);
            return open ? 0 : height + 8;
        }

        Behavior on y {
            NumberAnimation {
                duration: 360
                easing.type: Easing.OutExpo
            }
        }

        implicitWidth: 840
        implicitHeight: 480

        color: Colors.md3.surface_container
        radius: 20
        border.width: 1
        border.color: Colors.md3.outline_variant

        layer.enabled: true

        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Item {
                width: 254
                height: parent.height

                Column {
                    anchors.fill: parent
                    anchors.topMargin: 8
                    spacing: 16

                    Column {
                        width: parent.width
                        spacing: 0

                        Row {
                            width: parent.width
                            spacing: 6

                            Text {
                                id: timeText
                                text: root.liveTime
                                color: Colors.md3.on_surface
                                font.family: "Google Sans Display"
                                font.pixelSize: 56
                                font.weight: Font.Light
                                font.features: {
                                    "tnum": 1
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            Column {
                                anchors.verticalCenter: timeText.verticalCenter
                                spacing: 0

                                Text {
                                    id: ampmText
                                    opacity: root.liveAmPm !== "" ? 1.0 : 0.0
                                    text: root.liveAmPm !== "" ? root.liveAmPm.trim() : "am"
                                    color: Qt.alpha(Colors.md3.on_surface_variant, 0.55)
                                    font.family: "Google Sans Display"
                                    font.pixelSize: 22
                                    font.weight: Font.Light
                                    height: timeText.height / 2
                                    verticalAlignment: Text.AlignBottom

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }

                                Text {
                                    id: secsText
                                    text: ":" + root.liveSecs
                                    color: Qt.alpha(Colors.md3.on_surface_variant, 0.55)
                                    font.family: "Google Sans Display"
                                    font.pixelSize: 22
                                    font.weight: Font.Light
                                    font.features: {
                                        "tnum": 1
                                    }
                                    height: timeText.height / 2
                                    verticalAlignment: Text.AlignTop

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: root.liveDayName
                            color: Colors.md3.primary
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            topPadding: 4

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }

                        Text {
                            text: root.liveFullDate
                            color: Qt.alpha(Colors.md3.on_surface_variant, 0.55)
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            topPadding: 2

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6

                        Item {
                            width: parent.width
                            height: progressLabel.height

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Text {
                                    id: progressLabel
                                    text: root.selYear + " progress"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: Colors.md3.on_surface_variant

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }

                                Text {
                                    text: {
                                        const dy = root.dayOfYear(root.selDay, root.selMonth, root.selYear);
                                        const total = root.isLeapYear(root.selYear) ? 366 : 365;
                                        return dy + " / " + total;
                                    }
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Qt.alpha(Colors.md3.on_surface_variant, 0.55)
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.features: {
                                        "tnum": 1
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: progressLabel.verticalCenter
                                text: Math.round(root.selYearProgress * 100) + "%"
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: Colors.md3.primary
                                font.features: {
                                    "tnum": 1
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: progressTrack
                            width: parent.width
                            height: 5
                            radius: 3
                            color: Qt.alpha(Colors.md3.primary, 0.14)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }

                            Rectangle {
                                id: progressFill
                                width: Math.max(progressTrack.height, progressTrack.width * root.selYearProgress)
                                height: parent.height
                                radius: parent.radius
                                color: Colors.md3.primary

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 600
                                        easing.type: Easing.OutCubic
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 1

                        Row {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: root.selProseTop
                                color: Colors.md3.on_surface
                                font.family: Config.fontFamily
                                font.pixelSize: 13

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            Text {
                                text: "·"
                                color: Qt.alpha(Colors.md3.on_surface_variant, 0.35)
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.selRelativeLabel
                                color: Qt.alpha(Colors.md3.on_surface_variant, 0.55)
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            topPadding: 4
                            text: root.selProseBottom
                            color: Qt.alpha(Colors.md3.on_surface_variant, 0.55)
                            font.family: Config.fontFamily
                            font.pixelSize: 12

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }

                        Item {
                            visible: root.currentHoliday.length > 0
                            width: parent.width
                            height: chipPill.height + 6

                            Rectangle {
                                id: chipPill
                                anchors.bottom: parent.bottom
                                color: Colors.md3.secondary_container
                                radius: 8
                                width: chipRow.implicitWidth + 20
                                height: 28

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }

                                Row {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    CelebrationIcon {
                                        iconSize: 16
                                        color: Colors.md3.on_secondary_container
                                        anchors.verticalCenter: parent.verticalCenter

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }

                                    Text {
                                        text: root.currentHoliday
                                        color: Colors.md3.on_secondary_container
                                        font.family: Config.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 124
                    radius: 10
                    color: Colors.md3.surface_container_high

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    Column {
                        anchors {
                            fill: parent
                            leftMargin: 18
                            rightMargin: 18
                            topMargin: 16
                            bottomMargin: 14
                        }
                        spacing: 0

                        Row {
                            width: parent.width
                            spacing: 14

                            Loader {
                                id: weatherIconLoader
                                sourceComponent: root.getWeatherIconComponent()
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Row {
                                    spacing: 8

                                    Text {
                                        id: tempLabel
                                        text: root.weatherTemp
                                        font.pixelSize: 26
                                        color: Colors.md3.on_surface
                                        font.family: Config.fontFamily

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }

                                    Text {
                                        text: root.weatherHigh + " / " + root.weatherLow
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: Qt.alpha(Colors.md3.on_surface_variant, 0.55)
                                        font.family: Config.fontFamily
                                        anchors.baseline: tempLabel.baseline

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: root.weatherDesc
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Colors.md3.on_surface_variant
                                    font.family: Config.fontFamily

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: 1
                            height: 14
                        }

                        Item {
                            width: parent.width
                            height: 16

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                HeatIcon {
                                    iconSize: 15
                                    color: '#b287c7'
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.weatherUvi + " UVI"
                                    color: Colors.md3.on_surface_variant
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                WaterDropIcon {
                                    iconSize: 15
                                    color: "#a2c9ff"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.weatherHumid
                                    color: Colors.md3.on_surface_variant
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                AirIcon {
                                    iconSize: 15
                                    color: '#87b895'
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.weatherAqi + " AQI"
                                    color: Colors.md3.on_surface_variant
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - 254 - 16
                height: parent.height
                radius: 10
                color: Colors.md3.surface_container_high

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    Item {
                        id: calHeader
                        width: parent.width
                        height: 40

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: root.monthName(root.viewMonth) + " " + root.viewYear
                                font.family: Config.fontFamily
                                font.pixelSize: 20
                                font.weight: Font.Medium
                                color: Colors.md3.on_surface

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            Text {
                                text: root.weekCount(root.viewYear, root.viewMonth) + " weeks · " + new Date(root.viewYear, root.viewMonth + 1, 0).getDate() + " days"
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                color: Colors.md3.on_surface_variant

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 17
                                bottomRightRadius: 5
                                topRightRadius: 5
                                color: Colors.md3.surface_container_highest

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                ChevronLeftIcon {
                                    anchors.centerIn: parent
                                    iconSize: 22
                                    color: Colors.md3.on_surface_variant
                                }

                                MouseArea {
                                    id: prevMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.prevMonth()
                                }
                            }

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 17
                                bottomLeftRadius: 5
                                topLeftRadius: 5
                                color: Colors.md3.surface_container_highest

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                ChevronRightIcon {
                                    anchors.centerIn: parent
                                    iconSize: 22
                                    color: Colors.md3.on_surface_variant
                                }

                                MouseArea {
                                    id: nextMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.nextMonth()
                                }
                            }
                        }
                    }

                    Row {
                        id: dayLabels
                        anchors.top: calHeader.bottom
                        anchors.topMargin: 18
                        width: parent.width

                        Repeater {
                            model: Config.weekMonday ? ["M", "T", "W", "T", "F", "S", "S"] : ["S", "M", "T", "W", "T", "F", "S"]
                            Item {
                                width: dayLabels.width / 7
                                height: 20

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Colors.md3.on_surface_variant
                                    opacity: (Config.weekMonday ? index >= 5 : index === 0 || index === 6) ? 0.30 : 0.55

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Grid {
                        id: calGrid
                        anchors.top: dayLabels.bottom
                        anchors.topMargin: 6
                        anchors.bottom: parent.bottom
                        width: parent.width
                        columns: 7
                        spacing: 3

                        property real cellW: (width - (spacing * 6)) / 7
                        property real cellH: (height - (spacing * 5)) / 6

                        Repeater {
                            model: root.currentDays.length
                            delegate: Item {
                                required property int index
                                readonly property var dayData: root.currentDays[index]

                                readonly property bool isToday: dayData.isCurrentMonth && dayData.day === root.todayDay && dayData.month === root.todayMonth && dayData.year === root.todayYear
                                readonly property bool isSelected: !isToday && dayData.day === root.selDay && dayData.month === root.selMonth && dayData.year === root.selYear
                                readonly property bool isWeekend: {
                                    const dow = new Date(dayData.year, dayData.month, dayData.day).getDay();
                                    return dow === 0 || dow === 6;
                                }
                                readonly property bool hasHoliday: dayData.isCurrentMonth && holidayFor(dayData.day, dayData.month, dayData.year).length > 0

                                width: calGrid.cellW
                                height: calGrid.cellH

                                Rectangle {
                                    width: 38
                                    height: 38
                                    radius: 19
                                    anchors.centerIn: parent

                                    color: isToday ? Colors.md3.primary_container : isSelected ? Qt.alpha(Colors.md3.primary, 0.12) : (cellMA.containsMouse && dayData.isCurrentMonth ? Qt.alpha(Colors.md3.on_surface, 0.06) : "transparent")

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }

                                    border.width: isSelected ? 1.5 : 0
                                    border.color: isSelected ? Colors.md3.primary : "transparent"

                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: dayData.day
                                        font.family: Config.fontFamily
                                        font.pixelSize: 13
                                        font.features: {
                                            "tnum": 1
                                        }
                                        font.weight: (isToday || isSelected) ? Font.Medium : Font.Normal

                                        color: isToday ? Colors.md3.on_primary_container : isSelected ? Colors.md3.primary : !dayData.isCurrentMonth ? Qt.alpha(Colors.md3.on_surface, 0.25) : isWeekend ? Qt.alpha(Colors.md3.primary, 0.80) : Colors.md3.on_surface

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: hasHoliday && !isToday
                                        width: 4
                                        height: 4
                                        radius: 2
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 5
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: isSelected ? Colors.md3.primary : Qt.alpha(Colors.md3.primary, 0.55)

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: cellMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!dayData.isCurrentMonth) {
                                            root.selDay = dayData.day;
                                            root.selMonth = dayData.month;
                                            root.selYear = dayData.year;
                                            return;
                                        }

                                        if (isToday) {
                                            root.selDay = root.todayDay;
                                            root.selMonth = root.todayMonth;
                                            root.selYear = root.todayYear;
                                            return;
                                        }

                                        if (root.selDay === dayData.day && root.selMonth === dayData.month && root.selYear === dayData.year) {
                                            root.selDay = root.todayDay;
                                            root.selMonth = root.todayMonth;
                                            root.selYear = root.todayYear;
                                        } else {
                                            root.selDay = dayData.day;
                                            root.selMonth = dayData.month;
                                            root.selYear = dayData.year;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
