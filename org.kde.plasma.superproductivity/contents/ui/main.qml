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
    property bool isAppRunning: false
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

    // Only show on KDE panel when Super Productivity is running AND a session is active
    readonly property bool isActive: isAppRunning && isConnected && (timerStatus === "running" || timerStatus === "paused")
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
                    if (root.token && root.isAppRunning) {
                        fetchStatus();
                    }
                } else if (sourceName.indexOf("pgrep ") === 0) {
                    var running = stdout.trim().length > 0;
                    if (root.isAppRunning !== running) {
                        root.isAppRunning = running;
                        if (!running) {
                            root.isConnected = false;
                            root.timerStatus = "idle";
                            root.currentTaskTitle = "";
                        } else {
                            if (!root.token) {
                                loadToken();
                            } else {
                                fetchStatus();
                            }
                        }
                    }
                }
            }
        }
    }

    // 1. Process check timer: Runs every 4s to check if superproductivity is open
    // If NOT running, zero HTTP requests are sent!
    Timer {
        id: appCheckTimer
        interval: 4000
        running: true
        repeat: true
        onTriggered: checkAppRunning()
    }

    // 2. Poll timer for Pomodoro status: Only runs when App is actually running
    Timer {
        id: statusPollTimer
        interval: (root.timerStatus === "running") ? 1000 : 3000
        running: root.isAppRunning
        repeat: true
        onTriggered: {
            if (!root.token) {
                loadToken();
            } else {
                fetchStatus();
            }
        }
    }

    function checkAppRunning() {
        executableDataSource.connectSource("pgrep -fa 'super-productivity|superproductivity' | grep -v 'plasma-widget' | grep -v 'grep' | head -n 1 2>/dev/null");
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
        if (!root.token || !root.isAppRunning) return;

        // 1. Fetch Focus / Pomodoro info
        var xhr = new XMLHttpRequest();
        xhr.open("GET", root.apiBaseUrl + "/focus");
        xhr.setRequestHeader("Authorization", "Bearer " + root.token);
        xhr.timeout = 1500;
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
                }
            }
        };
        xhr.send();

        // 2. Fetch Current Task info
        var xhrTask = new XMLHttpRequest();
        xhrTask.open("GET", root.apiBaseUrl + "/task-control/current");
        xhrTask.setRequestHeader("Authorization", "Bearer " + root.token);
        xhrTask.timeout = 1500;
        xhrTask.onreadystatechange = function() {
            if (xhrTask.readyState === XMLHttpRequest.DONE) {
                if (xhrTask.status === 200) {
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
            }
        };
        xhrTask.send();
    }

    function stopCurrentTask() {
        if (!root.token || !root.isAppRunning) return;
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

    function raiseSuperProductivityWindow() {
        executableDataSource.connectSource("kdotool search --class superProductivity windowactivate 2>/dev/null || wmctrl -x -a superproductivity 2>/dev/null || gtk-launch superproductivity 2>/dev/null");
    }

    Component.onCompleted: {
        checkAppRunning();
        loadToken();
    }
}
