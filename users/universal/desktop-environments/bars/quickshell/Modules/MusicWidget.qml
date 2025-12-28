import Quickshell.Io
import QtQuick

Item {
    id: root

    property string title: ""
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property string status: "Stopped"  // Playing, Paused, Stopped
    property bool hasPlayer: false
    property int refreshInterval: 1000

    function playPause() {
        playPauseProcess.running = true;
    }
    
    function next() {
        nextProcess.running = true;
    }
    
    function previous() {
        prevProcess.running = true;
    }

    Process {
        id: metadataProcess
        command: ["bash", "-c", "playerctl metadata --format '{{status}}|||{{title}}|||{{artist}}|||{{album}}|||{{mpris:artUrl}}' 2>/dev/null"]

        stdout: SplitParser {
            onRead: data => {
                const cleanData = data.trim();
                if (!cleanData || cleanData === "No players found") {
                    root.hasPlayer = false;
                    root.status = "Stopped";
                    root.title = "";
                    root.artist = "";
                    root.album = "";
                    root.artUrl = "";
                    return;
                }
                
                const parts = cleanData.split("|||");
                if (parts.length >= 1) {
                    root.hasPlayer = true;
                    root.status = parts[0] || "Stopped";
                    root.title = parts[1] || "Unknown";
                    root.artist = parts[2] || "Unknown Artist";
                    root.album = parts[3] || "";
                    root.artUrl = parts[4] || "";
                }
            }
        }
        Component.onCompleted: running = true
    }
    
    Process {
        id: playPauseProcess
        command: ["playerctl", "play-pause"]
        onRunningChanged: {
            if (!running) metadataProcess.running = true;
        }
    }
    
    Process {
        id: nextProcess
        command: ["playerctl", "next"]
        onRunningChanged: {
            if (!running) metadataProcess.running = true;
        }
    }
    
    Process {
        id: prevProcess
        command: ["playerctl", "previous"]
        onRunningChanged: {
            if (!running) metadataProcess.running = true;
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: metadataProcess.running = true
    }
}
