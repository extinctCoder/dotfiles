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
    property var hours: []      // [{ hour: "14", temp: 26.1, code: 2, rain: 10 }], next 24 hours
    property var days: []       // [{ day: "fri", min: 21, max: 30, code: 3, rain: 40, uv: 6 }], 7 days (today first)
    property real humidity: NaN // %
    property real wind: NaN     // km/h
    property real uv: NaN       // today's max
    property real rainChance: NaN // % in the coming hour
    property string sunrise: "" // "06:14"
    property string sunset: ""
    readonly property string condition: describe(code)

    readonly property string url: "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
        + "&current=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m"
        + "&hourly=temperature_2m,weather_code,precipitation_probability"
        + "&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,uv_index_max"
        + "&timezone=auto&forecast_days=7&forecast_hours=24"

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
            root.hours = d.hourly.time.map((t, i) => ({
                hour: t.slice(11, 13), temp: d.hourly.temperature_2m[i],
                code: d.hourly.weather_code[i], rain: d.hourly.precipitation_probability[i]
            }));
            root.humidity = d.current.relative_humidity_2m;
            root.wind = d.current.wind_speed_10m;
            root.rainChance = d.hourly.precipitation_probability[0];
            root.uv = d.daily.uv_index_max[0];
            const names = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
            root.days = d.daily.time.map((t, i) => ({
                day: i === 0 ? "today" : names[new Date(t + "T12:00:00").getDay()],
                min: d.daily.temperature_2m_min[i], max: d.daily.temperature_2m_max[i],
                code: d.daily.weather_code[i], rain: d.daily.precipitation_probability_max[i], uv: d.daily.uv_index_max[i]
            }));
            root.sunrise = d.daily.sunrise[0].slice(11, 16);
            root.sunset = d.daily.sunset[0].slice(11, 16);
            root.ok = true;
        } catch (e) {
            root.ok = false;
        }
    }
}
