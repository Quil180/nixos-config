import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    property color base00: "#1b1d29"
    property color base01: "#364852"
    property color base02: "#5a697c"
    property color base03: "#999da8"
    property color base04: "#cbb785"
    property color base05: "#ffdeb3"
    property color base06: "#fdefca"
    property color base07: "#f5f0ed"
    property color base08: "#8c929e"
    property color base09: "#8b919d"
    property color base0A: "#a48f60"
    property color base0B: "#898f9b"
    property color base0C: "#8d939f"
    property color base0D: "#8a909c"
    property color base0E: "#909196"
    property color base0F: "#8b919d"

    // Ensuring the bar is on the top and all the way to the left and right
    anchors {
        top: true
        left: true
        right: true
    }
    // Setting the maximum height to be 30
    implicitHeight: 30
    // Setting the background color to be base00
    color: base00

    property string fontFamily: "Iosevka Nerd Font"
    property int fontSize: 16

    // CPU Process things
    Item {
        id: cpuWidget
        // CPU Widget stuff
        property int cpuUsage: 0
        property var lastCpuIdle: 0
        property var lastCpuTotal: 0

        Process {
            // Id of the process we want running
            id: cpuProcess
            // What the process will execute command wise
            command: ["bash", "-c", "head -1 /proc/stat"]

            // Splitting what the command outputs into what we want
            stdout: SplitParser {
                onRead: data => {
                    var givenData = data.trim().split(/\s+/);
                    var idle = parseInt(givenData[4]) + parseInt(givenData[5]);
                    var total = givenData.slice(1, 8).reduce((a, b) => a + parseInt(b), 0);
                    if (cpuWidget.lastCpuTotal > 0) {
                        cpuWidget.cpuUsage = Math.round(100 * (1 - (idle - cpuWidget.lastCpuIdle) / (total - cpuWidget.lastCpuTotal)));
                    }
                    cpuWidget.lastCpuTotal = total;
                    cpuWidget.lastCpuIdle = idle;
                }
            }
            Component.onCompleted: running = true
        }
    }

    // Memory Process things
    Item {
        id: memWidget
        // CPU Widget stuff
        property int memUsage: 0
        property int memUsed: 0
        property int memTotal: 0

        Process {
            // Id of the process we want running
            id: memProcess
            // What the process will execute command wise
            command: ["bash", "-c", "free | grep Mem"]

            // Splitting what the command outputs into what we want
            stdout: SplitParser {
                onRead: data => {
                    var parts = data.trim().split(/\s+/);
                    var total = parseInt(parts[1]) || 1;
                    var used = parseInt(parts[2]) || 0;
                    memWidget.memUsage = Math.round(100 * used / total);
                    memWidget.memUsed = Math.round(used / 1024);
                    memWidget.memTotal = total;
                }
            }
            Component.onCompleted: running = true
        }
    }

    // Temperature Process things
    Item {
        id: tempWidget
        // CPU Widget stuff
        property int tempCPU: 0

        Process {
            // Id of the process we want running
            id: tempProcess
            // What the process will execute command wise
            command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp"]

            // Splitting what the command outputs into what we want
            stdout: SplitParser {
                onRead: data => {
                    tempWidget.tempCPU = Math.round(data / 1000);
                }
            }
            Component.onCompleted: running = true
        }
    }

    // Brightness Process things
    Item {
        id: brightnessWidget
        // CPU Widget stuff
        property int brightnessMain: 0

        Process {
            // Id of the process we want running
            id: brightnessProcess
            // What the process will execute command wise
            command: ["bash", "-c", "brightnessctl -m"]

            // Splitting what the command outputs into what we want
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
                        brightnessWidget.brightnessMain = parseInt(parts[3]);
                    }
                }
            }
            Component.onCompleted: running = true
        }
    }

    Item {
        id: windowWidget
        property string activeWindow: "Window"

        Process {
            id: windowProcess
            command: ["bash", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]

            stdout: SplitParser {
                onRead: data => {
                    var parts = data.trim().split(/\s+/);
                    windowWidget.activeWindow = data.trim();
                }
            }
            Component.onCompleted: running = true
        }
    }

    Timer {
        interval: 2000 // 2 seconds
        running: true
        repeat: true
        onTriggered: {
            cpuProcess.running = true;
            memProcess.running = true;
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            windowProcess.running = true;
            tempProcess.running = true;
            brightnessProcess.running = true;
        }
    }
    RowLayout {
        anchors {
            fill: parent
            margins: 5
        }

        // Workspaces showing!!
        Repeater {
            id: workspaces
            model: 9
            Rectangle {
                property var workspaces: Hyprland.workspaces.values.find(workspace => workspace.id === index + 1 && workspace.toplevels.values.length > 0) ?? null
                property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === (index + 1)

                Layout.preferredWidth: 20
                Layout.preferredHeight: parent.height
                color: "transparent"

                Text {
                    id: workspacesText
                    text: index + 1
                    color: parent.isFocused ? root.base03 : (parent.workspaces ? root.base02 : root.base01)

                    font {
                        family: root.fontFamily
                        pixelSize: root.fontSize
                        bold: true
                    }

                    Rectangle {
                        width: 20
                        height: 1
                        color: parent.parent.isFocused ? base04 : base00
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                    }
                }
            }
        }

        // Spacer
        Rectangle {
            width: 2
            height: 16
            color: base08
        }

        Text {
            text: windowWidget.activeWindow
            color: base04
            font {
                family: root.fontFamily
                pixelSize: root.fontSize
                bold: true
            }
            Layout.fillWidth: true
            Layout.leftMargin: 8
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Spacer to push rest to the very right
        Item {
            Layout.fillWidth: true
        }

        // CPU Usage Text
        Text {
            id: cpu
            text: "\uf4bc  - " + cpuWidget.cpuUsage + "%"
            color: cpuWidget.cpuUsage > 75 ? "#CD5C5C" : base03
            font {
                family: root.fontFamily
                pixelSize: root.fontSize
                bold: true
            }
        }

        // Spacer
        Rectangle {
            width: 2
            height: 16
            color: base08
        }

        // Memory Usage Text
        Text {
            id: memory
            text: "\uefc5  - " + memWidget.memUsage + "%"
            color: memWidget.memUsage > 75 ? "#CD5C5C" : base03
            font {
                family: root.fontFamily
                pixelSize: root.fontSize
                bold: true
            }

            property bool clicked: false

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    memory.clicked = !memory.clicked;
                    memory.text = memory.clicked ? "\uefc5  - " + memWidget.memUsage + "%" : "\uefc5  - " + memWidget.memUsed + "MB";
                }
            }
        }

        // Spacer
        Rectangle {
            width: 2
            height: 16
            color: base08
        }

        // CPU Temperature Text
        Text {
            id: temperature
            text: "\uef2a  - " + tempWidget.tempCPU + "C"
            color: tempWidget.tempCPU > 85 ? "#CD5C5C" : base03
            font {
                family: root.fontFamily
                pixelSize: root.fontSize
                bold: true
            }
        }

        // Spacer
        Rectangle {
            width: 2
            height: 16
            color: base08
        }

        // Brightness Percentage Text
        Text {
            id: brightness
            text: "\udb80\udce0  - " + brightnessWidget.brightnessMain + "%"
            color: base03
            font {
                family: root.fontFamily
                pixelSize: root.fontSize
                bold: true
            }
        }

        // Spacer
        Rectangle {
            width: 2
            height: 16
            color: base08
        }
        // Clock!!
        Text {
            id: clock
            text: Qt.formatDateTime(new Date(), "ddd, MMM dd - h:mm:ss AP")
            color: base03

            font {
                family: root.fontFamily
                pixelSize: root.fontSize
                bold: true
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - h:mm:ss AP")
            }
        }
    }
}
