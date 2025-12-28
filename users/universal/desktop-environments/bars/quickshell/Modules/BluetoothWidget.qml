import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool powered: false
    property bool connected: false
    property string connectedDevice: ""
    property var pairedDevices: []
    property int refreshInterval: 3000

    function togglePower() {
        toggleProcess.command = ["bluetoothctl", "power", powered ? "off" : "on"];
        toggleProcess.running = true;
    }
    
    function connectDevice(mac) {
        connectProcess.command = ["bluetoothctl", "connect", mac];
        connectProcess.running = true;
    }
    
    function disconnectDevice(mac) {
        disconnectProcess.command = ["bluetoothctl", "disconnect", mac];
        disconnectProcess.running = true;
    }

    Process {
        id: statusProcess
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -E 'Powered|Connected' | head -2"]
        
        property string outputBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                statusProcess.outputBuffer += data + "\n";
            }
        }
        
        onRunningChanged: {
            if (!running) {
                const lines = statusProcess.outputBuffer;
                root.powered = lines.includes("Powered: yes");
                statusProcess.outputBuffer = "";
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: connectedProcess
        command: ["bash", "-c", "bluetoothctl info 2>/dev/null | grep -E 'Name:|Connected:' | head -2"]
        
        property string outputBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                connectedProcess.outputBuffer += data + "\n";
            }
        }
        
        onRunningChanged: {
            if (!running) {
                const output = connectedProcess.outputBuffer;
                root.connected = output.includes("Connected: yes");
                const nameMatch = output.match(/Name:\s*(.+)/);
                root.connectedDevice = nameMatch ? nameMatch[1].trim() : "";
                connectedProcess.outputBuffer = "";
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: pairedProcess
        command: ["bash", "-c", "bluetoothctl devices Paired 2>/dev/null"]
        
        property string outputBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                pairedProcess.outputBuffer += data + "\n";
            }
        }
        
        onRunningChanged: {
            if (!running) {
                var devices = [];
                var lines = pairedProcess.outputBuffer.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith("Device ")) {
                        var parts = line.substring(7).split(" ");
                        var mac = parts[0];
                        var name = parts.slice(1).join(" ");
                        if (mac && name) {
                            devices.push({ mac: mac, name: name });
                        }
                    }
                }
                root.pairedDevices = devices;
                pairedProcess.outputBuffer = "";
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: toggleProcess
        onRunningChanged: {
            if (!running) {
                statusProcess.running = true;
            }
        }
    }
    
    Process {
        id: connectProcess
        onRunningChanged: {
            if (!running) {
                connectedProcess.running = true;
            }
        }
    }
    
    Process {
        id: disconnectProcess
        onRunningChanged: {
            if (!running) {
                connectedProcess.running = true;
            }
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: {
            statusProcess.running = true;
            connectedProcess.running = true;
            pairedProcess.running = true;
        }
    }
}
