import Quickshell.Io
import QtQuick

Item {
    id: root

    property int tempCPU: 0
    property int refreshInterval: 200

    Process {
        id: tempProcess
        command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp"]

        stdout: SplitParser {
            onRead: data => {
                root.tempCPU = Math.round(data / 1000);
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: tempProcess.running = true
    }
}
