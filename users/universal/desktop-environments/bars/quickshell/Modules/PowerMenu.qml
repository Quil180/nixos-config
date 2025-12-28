import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    signal mouseEntered()
    signal mouseExited()
    signal actionTriggered()
    
    readonly property bool isHovered: mainHover.containsMouse
    
    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }

    implicitWidth: 160
    implicitHeight: menuColumn.height + 24
    color: Theme.base00
    radius: 8
    border.color: Theme.base01
    border.width: 1
    
    MouseArea {
        id: mainHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse => mouse.accepted = false
        onPressed: mouse => mouse.accepted = false
        onReleased: mouse => mouse.accepted = false
    }
    
    // Action processes
    Process { id: lockProcess; command: ["loginctl", "lock-session"] }
    Process { id: suspendProcess; command: ["systemctl", "suspend"] }
    Process { id: rebootProcess; command: ["systemctl", "reboot"] }
    Process { id: shutdownProcess; command: ["systemctl", "poweroff"] }
    Process { id: logoutProcess; command: ["hyprctl", "dispatch", "exit"] }

    ColumnLayout {
        id: menuColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 4

        // Menu items
        Repeater {
            model: [
                { icon: "\uf023", label: "Lock", action: "lock" },
                { icon: "\uf186", label: "Suspend", action: "suspend" },
                { icon: "\uf021", label: "Reboot", action: "reboot" },
                { icon: "\uf011", label: "Shutdown", action: "shutdown" },
                { icon: "\uf2f5", label: "Logout", action: "logout" }
            ]
            
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: itemMouse.containsMouse ? Theme.base01 : "transparent"
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12
                    
                    Text {
                        text: modelData.icon
                        color: modelData.action === "shutdown" ? Theme.alertColor : Theme.base03
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                    }
                    
                    Text {
                        text: modelData.label
                        color: modelData.action === "shutdown" ? Theme.alertColor : Theme.base04
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize
                        }
                        Layout.fillWidth: true
                    }
                }
                
                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: popup.mouseEntered()
                    onClicked: {
                        popup.actionTriggered();
                        switch (modelData.action) {
                            case "lock": lockProcess.running = true; break;
                            case "suspend": suspendProcess.running = true; break;
                            case "reboot": rebootProcess.running = true; break;
                            case "shutdown": shutdownProcess.running = true; break;
                            case "logout": logoutProcess.running = true; break;
                        }
                    }
                }
            }
        }
    }
}
