import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool dndEnabled: false
    property int refreshInterval: 2000

    function toggle() {
        toggleProcess.running = true;
    }

    Process {
        id: statusProcess
        command: ["dunstctl", "is-paused"]

        stdout: SplitParser {
            onRead: data => {
                root.dndEnabled = data.trim() === "true";
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: toggleProcess
        command: ["dunstctl", "set-paused", "toggle"]
        onRunningChanged: {
            if (!running) {
                statusProcess.running = true;
            }
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: statusProcess.running = true
    }
}
