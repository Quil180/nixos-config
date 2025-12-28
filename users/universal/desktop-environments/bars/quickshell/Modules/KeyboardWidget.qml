import Quickshell.Io
import QtQuick

Item {
    id: root

    property string currentLayout: ""
    property var availableLayouts: []
    property int refreshInterval: 2000

    function switchLayout() {
        switchProcess.running = true;
    }

    Process {
        id: layoutProcess
        command: ["bash", "-c", "hyprctl devices -j 2>/dev/null | jq -r '.keyboards[0].active_keymap // empty'"]

        stdout: SplitParser {
            onRead: data => {
                root.currentLayout = data.trim() || "Unknown";
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: switchProcess
        command: ["hyprctl", "switchxkblayout", "all", "next"]
        onRunningChanged: {
            if (!running) {
                layoutProcess.running = true;
            }
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: layoutProcess.running = true
    }
}
