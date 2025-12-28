import Quickshell.Io
import QtQuick

Item {
    id: root

    property int volume: 0
    property bool muted: false
    property int refreshInterval: 200

    function toggleMute() {
        muteProcess.running = true;
    }

    Process {
        id: muteProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onRunningChanged: {
            if (!running) {
                volumeProcess.running = true;
            }
        }
    }

    Process {
        id: volumeProcess
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]

        stdout: SplitParser {
            onRead: data => {
                const cleanData = data.trim();
                if (!cleanData) {
                    return;
                }
                // Output format: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
                root.muted = cleanData.includes("[MUTED]");
                const match = cleanData.match(/Volume:\s*([\d.]+)/);
                if (match) {
                    root.volume = Math.round(parseFloat(match[1]) * 100);
                }
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: volumeProcess.running = true
    }
}
