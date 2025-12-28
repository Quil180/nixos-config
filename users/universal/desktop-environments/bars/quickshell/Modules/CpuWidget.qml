import Quickshell.Io
import QtQuick

Item {
    id: root

    property int cpuUsage: 0
    property int refreshInterval: 2000

    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    Process {
        id: cpuProcess
        command: ["bash", "-c", "head -1 /proc/stat"]

        stdout: SplitParser {
            onRead: data => {
                var givenData = data.trim().split(/\s+/);
                var idle = parseInt(givenData[4]) + parseInt(givenData[5]);
                var total = givenData.slice(1, 8).reduce((a, b) => a + parseInt(b), 0);
                if (root.lastCpuTotal > 0) {
                    root.cpuUsage = Math.round(100 * (1 - (idle - root.lastCpuIdle) / (total - root.lastCpuTotal)));
                }
                root.lastCpuTotal = total;
                root.lastCpuIdle = idle;
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: cpuProcess.running = true
    }
}
