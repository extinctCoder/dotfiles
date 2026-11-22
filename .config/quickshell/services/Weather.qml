pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Real forecast from Open-Meteo (free, no account). Refreshes every 15 min,
// retries every 5 min while offline. `ok` is false until real data arrives.
Singleton {
    id: root
    readonly property string place: "dhaka"
    readonly property real lat: 23.8103
    readonly property real lon: 90.4125

    property bool ok: false
    property real temp: NaN
    property real feels: NaN
    property int code: -1
    property var hours: []      // [{ hour: "14", temp: 26.1 }], next 12 hours
    property string sunrise: "" // "06:14"
    property string sunset: ""
    readonly property string condition: describe(code)

    readonly property string url: "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
        + "&current=temperature_2m,apparent_temperature,weather_code"
        + "&hourly=temperature_2m&daily=sunrise,sunset&timezone=auto&forecast_days=2&forecast_hours=12"

    function describe(c) { // WMO weather codes
        if (c < 0) return "--";
        if (c === 0) return "clear";
        if (c <= 2) return "partly cloudy";
        if (c === 3) return "overcast";
        if (c <= 48) return "fog";
        if (c <= 57) return "drizzle";
        if (c <= 67) return "rain";
        if (c <= 77) return "snow";
        if (c <= 82) return "showers";
        if (c <= 86) return "snow showers";
        return "thunderstorm";
    }
    function deg(v) { return isNaN(v) ? "--" : Math.round(v) + "°"; }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "15", root.url]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
        onExited: (exitCode, exitStatus) => { if (exitCode !== 0) root.ok = false; }
    }
    Timer {
        interval: root.ok ? 900000 : 300000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: fetch.running = true
    }

    function parse(text) {
        try {
            const d = JSON.parse(text);
            root.temp = d.current.temperature_2m;
            root.feels = d.current.apparent_temperature;
            root.code = d.current.weather_code;
            root.hours = d.hourly.time.map((t, i) => ({ hour: t.slice(11, 13), temp: d.hourly.temperature_2m[i] }));
            root.sunrise = d.daily.sunrise[0].slice(11, 16);
            root.sunset = d.daily.sunset[0].slice(11, 16);
            root.ok = true;
        } catch (e) {
            root.ok = false;
        }
    }
}
