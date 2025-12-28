import Quickshell.Io
import QtQuick

Item {
    id: root

    property string activeWindow: "Window"
    property int refreshInterval: 200

    Process {
        id: windowProcess
        command: ["bash", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]

        stdout: SplitParser {
            onRead: data => {
                root.activeWindow = data.trim();
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: windowProcess.running = true
    }
}
