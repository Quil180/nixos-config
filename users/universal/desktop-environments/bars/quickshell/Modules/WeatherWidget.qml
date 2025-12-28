import Quickshell.Io
import QtQuick

Item {
    id: root

    property string temperature: ""
    property string conditions: ""
    property string location: ""
    property int refreshInterval: 600000  // 10 minutes

    Process {
        id: weatherProcess
        command: ["bash", "-c", "curl -s 'wttr.in/?format=%t|%C|%l' 2>/dev/null | head -1"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|");
                if (parts.length >= 2) {
                    root.temperature = parts[0] || "";
                    root.conditions = parts[1] || "";
                    root.location = parts[2] || "";
                }
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: weatherProcess.running = true
    }
}
