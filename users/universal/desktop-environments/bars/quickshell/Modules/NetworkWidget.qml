import Quickshell.Io
import QtQuick

Item {
    id: root

    property string ssid: ""
    property string ipAddress: ""
    property int signalStrength: 0
    property bool connected: false
    property int refreshInterval: 2000
    
    // Available networks list
    property var availableNetworks: []
    property bool scanning: false

    // Scan for available networks
    function scanNetworks() {
        root.scanning = true;
        scanProcess.running = true;
    }
    
    // Connect to a network
    function connectToNetwork(networkSsid) {
        connectProcess.command = ["nmcli", "dev", "wifi", "connect", networkSsid];
        connectProcess.running = true;
    }

    Process {
        id: networkProcess
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes' | head -1"]

        stdout: SplitParser {
            onRead: data => {
                const cleanData = data.trim();
                if (!cleanData) {
                    root.connected = false;
                    root.ssid = "";
                    root.signalStrength = 0;
                    return;
                }
                // Output format: "yes:MyNetwork:75"
                const parts = cleanData.split(":");
                if (parts.length >= 3) {
                    root.connected = true;
                    root.ssid = parts[1] || "Unknown";
                    root.signalStrength = parseInt(parts[2]) || 0;
                }
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: ipProcess
        command: ["bash", "-c", "ip -4 addr show | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | grep -v '127.0.0.1' | head -1"]

        stdout: SplitParser {
            onRead: data => {
                root.ipAddress = data.trim() || "No IP";
            }
        }
        Component.onCompleted: running = true
    }
    
    // Scan for available networks
    Process {
        id: scanProcess
        command: ["bash", "-c", "nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>/dev/null | head -20"]
        
        property string outputBuffer: ""
        
        stdout: SplitParser {
            onRead: data => {
                scanProcess.outputBuffer += data + "\n";
            }
        }
        
        onRunningChanged: {
            if (!running) {
                var networks = [];
                var lines = scanProcess.outputBuffer.trim().split("\n");
                var seenSsids = {};
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (!line) continue;
                    
                    // Format: SSID:SIGNAL:SECURITY
                    var parts = line.split(":");
                    if (parts.length >= 2) {
                        var ssid = parts[0];
                        if (!ssid || seenSsids[ssid]) continue;
                        seenSsids[ssid] = true;
                        
                        networks.push({
                            ssid: ssid,
                            signal: parseInt(parts[1]) || 0,
                            security: parts[2] || "",
                            isConnected: ssid === root.ssid
                        });
                    }
                }
                
                // Sort by signal strength
                networks.sort((a, b) => b.signal - a.signal);
                root.availableNetworks = networks;
                root.scanning = false;
                scanProcess.outputBuffer = "";
            }
        }
    }
    
    // Connect to network process
    Process {
        id: connectProcess
        onRunningChanged: {
            if (!running) {
                // Refresh connection status after connecting
                networkProcess.running = true;
                ipProcess.running = true;
            }
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: {
            networkProcess.running = true;
            ipProcess.running = true;
        }
    }
}
