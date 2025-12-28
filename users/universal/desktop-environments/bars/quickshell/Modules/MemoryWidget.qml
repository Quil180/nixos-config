import Quickshell.Io
import QtQuick

Item {
    id: root

    property int memUsage: 0
    property int memUsed: 0
    property int memTotal: 0
    property int refreshInterval: 2000

    Process {
        id: memProcess
        command: ["bash", "-c", "free | grep Mem"]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/);
                var total = parseInt(parts[1]) || 1;
                var used = parseInt(parts[2]) || 0;
                root.memUsage = Math.round(100 * used / total);
                root.memUsed = Math.round(used / 1024);
                root.memTotal = total;
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: memProcess.running = true
    }
}
