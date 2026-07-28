import Quickshell.Io
import QtQuick

Item {
    id: root

    property int brightnessMain: 0
    property int refreshInterval: 200

    function brightnessUp() {
        brightUpProcess.running = false;
        brightUpProcess.running = true;
    }

    function brightnessDown() {
        brightDownProcess.running = false;
        brightDownProcess.running = true;
    }

    Process {
        id: brightUpProcess
        command: ["brightnessctl", "set", "+1%"]
        onRunningChanged: {
            if (!running) {
                brightnessProcess.running = true;
            }
        }
    }

    Process {
        id: brightDownProcess
        command: ["brightnessctl", "set", "1%-"]
        onRunningChanged: {
            if (!running) {
                brightnessProcess.running = true;
            }
        }
    }

    Process {
        id: brightnessProcess
        command: ["bash", "-c", "brightnessctl -m"]

        stdout: SplitParser {
            onRead: data => {
                const cleanData = data.trim();
                if (!cleanData) {
                    return;
                }
                // Split by comma
                const parts = cleanData.split(",");
                // The percentage is usually the 4th item (index 3) -> "50%"
                if (parts.length >= 4) {
                    // parseInt handles "50%" correctly by ignoring the non-digit at the end
                    root.brightnessMain = parseInt(parts[3]);
                }
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: brightnessProcess.running = true
    }
}
