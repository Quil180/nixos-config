import Quickshell.Io
import QtQuick

Item {
    id: root

    property var notifications: []
    property int count: 0
    property int refreshInterval: 5000

    function clearAll() {
        clearProcess.running = true;
    }
    
    function dismissNotification(id) {
        dismissProcess.command = ["dunstctl", "history-rm", id.toString()];
        dismissProcess.running = true;
    }

    Process {
        id: historyProcess
        command: ["dunstctl", "history"]
        
        property string outputBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                historyProcess.outputBuffer += data;
            }
        }
        
        onRunningChanged: {
            if (!running) {
                try {
                    var json = JSON.parse(historyProcess.outputBuffer);
                    var items = json.data && json.data[0] ? json.data[0] : [];
                    var notifs = [];
                    for (var i = 0; i < Math.min(items.length, 10); i++) {
                        notifs.push({
                            id: items[i].id.data || i,
                            appName: items[i].appname.data || "Unknown",
                            summary: items[i].summary.data || "",
                            body: items[i].body.data || ""
                        });
                    }
                    root.notifications = notifs;
                    root.count = items.length;
                } catch (e) {
                    root.notifications = [];
                    root.count = 0;
                }
                historyProcess.outputBuffer = "";
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: clearProcess
        command: ["dunstctl", "history-clear"]
        onRunningChanged: {
            if (!running) {
                historyProcess.running = true;
            }
        }
    }
    
    Process {
        id: dismissProcess
        onRunningChanged: {
            if (!running) {
                historyProcess.running = true;
            }
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: historyProcess.running = true
    }
}
