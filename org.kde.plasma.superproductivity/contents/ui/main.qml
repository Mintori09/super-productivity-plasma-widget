import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    // States
    property bool isConnected: false
    property string currentTaskTitle: ""
    property string currentTaskId: ""
    property string timerStatus: "idle" // idle, running, paused, done
    property string timerPurpose: ""
    property bool isBreak: false
    property bool isLongBreak: false
    property int remainingMs: 0
    property int durationMs: 0
    property int cycle: 0
    property string token: ""

    // Auto-hide when idle or app closed
    readonly property bool isActive: isConnected && (timerStatus === "running" || timerStatus === "paused")
    Plasmoid.status: isActive ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus

    readonly property string apiBaseUrl: "http://127.0.0.1:3876"

    P5Support.DataSource {
        id: executableDataSource
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            if (data["exit code"] !== undefined) {
                var stdout = data["stdout"] || "";
                disconnectSource(sourceName);
                if (sourceName.indexOf("cat ") === 0) {
                    root.token = stdout.trim();
                    if (root.token) {
                        fetchStatus();
                    }
                }
            }
        }
    }

    // Adaptive Timer: 
    // - 1s interval when Pomodoro is actively ticking (smooth countdown)
    // - 3s interval when Idle / App closed (ultra lightweight, near zero CPU)
    Timer {
        id: pollTimer
        interval: (root.timerStatus === "running") ? 1000 : 3000
        running: true
        repeat: true
        onTriggered: {
            if (!root.token) {
                loadToken();
            } else {
                fetchStatus();
            }
        }
    }

    function loadToken() {
        executableDataSource.connectSource("cat \"$HOME/.config/superProductivity/local-rest-api-token\" 2>/dev/null");
    }

    function formatTime(ms) {
        if (!ms || ms <= 0) return "00:00";
        var totalSecs = Math.floor(ms / 1000);
        var mins = Math.floor(totalSecs / 60);
        var secs = totalSecs % 60;
        var mStr = mins < 10 ? "0" + mins : mins.toString();
        var sStr = secs < 10 ? "0" + secs : secs.toString();
        return mStr + ":" + sStr;
    }

    function fetchStatus() {
        if (!root.token) return;

        // 1. Fetch Focus / Pomodoro info
        var xhr = new XMLHttpRequest();
        xhr.open("GET", root.apiBaseUrl + "/focus");
        xhr.setRequestHeader("Authorization", "Bearer " + root.token);
        xhr.timeout = 1000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText);
                        var res = json.data || json;
                        root.isConnected = true;
                        root.cycle = res.cycle || 0;
                        if (res.timer) {
                            root.timerStatus = res.timer.status || "idle";
                            root.timerPurpose = res.timer.purpose || "";
                            root.isBreak = (root.timerPurpose.toLowerCase().indexOf("break") !== -1);
                            root.isLongBreak = !!res.timer.isLongBreak;
                            root.remainingMs = res.timer.remainingMs || 0;
                            root.durationMs = res.timer.durationMs || 0;
                        } else {
                            root.timerStatus = "idle";
                            root.timerPurpose = "";
                            root.remainingMs = 0;
                        }
                    } catch (e) {
                        console.warn("[SuperProd-Plasmoid] JSON parse error:", e);
                    }
                } else {
                    root.isConnected = false;
                    root.timerStatus = "idle";
                }
            }
        };
        xhr.ontimeout = function() {
            root.isConnected = false;
            root.timerStatus = "idle";
        };
        xhr.onerror = function() {
            root.isConnected = false;
            root.timerStatus = "idle";
        };
        xhr.send();

        // 2. Fetch Current Task info (only when connected)
        if (root.isConnected) {
            var xhrTask = new XMLHttpRequest();
            xhrTask.open("GET", root.apiBaseUrl + "/task-control/current");
            xhrTask.setRequestHeader("Authorization", "Bearer " + root.token);
            xhrTask.timeout = 1000;
            xhrTask.onreadystatechange = function() {
                if (xhrTask.readyState === XMLHttpRequest.DONE && xhrTask.status === 200) {
                    try {
                        var taskJson = JSON.parse(xhrTask.responseText);
                        var taskRes = taskJson.data || taskJson;
                        if (taskRes && taskRes.title) {
                            root.currentTaskTitle = taskRes.title;
                            root.currentTaskId = taskRes.id || "";
                        } else {
                            root.currentTaskTitle = "";
                            root.currentTaskId = "";
                        }
                    } catch (e) {}
                }
            };
            xhrTask.send();
        }
    }

    function stopCurrentTask() {
        if (!root.token) return;
        var xhr = new XMLHttpRequest();
        xhr.open("POST", root.apiBaseUrl + "/task-control/stop");
        xhr.setRequestHeader("Authorization", "Bearer " + root.token);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                fetchStatus();
            }
        };
        xhr.send();
    }

    Component.onCompleted: {
        loadToken();
    }
}
