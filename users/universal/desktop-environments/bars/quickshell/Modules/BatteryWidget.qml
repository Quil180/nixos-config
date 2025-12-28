import Quickshell.Io
import QtQuick

Item {
    id: root

    property int percentage: 0
    property bool charging: false
    property string status: "Unknown"
    property string timeRemaining: ""
    property int refreshInterval: 5000

    Process {
        id: batteryProcess
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1"]

        stdout: SplitParser {
            onRead: data => {
                const val = parseInt(data.trim());
                if (!isNaN(val)) {
                    root.percentage = val;
                }
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: statusProcess
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"]

        stdout: SplitParser {
            onRead: data => {
                const s = data.trim();
                root.status = s || "Unknown";
                root.charging = (s === "Charging");
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: timeProcess
        command: ["bash", "-c", "upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null | grep -E 'time to (empty|full)' | head -1 | awk '{print $4, $5}'"]

        stdout: SplitParser {
            onRead: data => {
                root.timeRemaining = data.trim() || "";
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: {
            batteryProcess.running = true;
            statusProcess.running = true;
            timeProcess.running = true;
        }
    }
}
