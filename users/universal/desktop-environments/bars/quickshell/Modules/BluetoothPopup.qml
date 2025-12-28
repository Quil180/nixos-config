import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    property bool powered: false
    property bool connected: false
    property string connectedDevice: ""
    property var pairedDevices: []
    
    signal togglePower()
    signal connectDevice(string mac)
    signal disconnectDevice(string mac)
    signal mouseEntered()
    signal mouseExited()
    
    readonly property bool isHovered: mainHover.containsMouse
    
    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }

    implicitWidth: 250
    implicitHeight: Math.min(contentColumn.height + 24, 250)
    color: Theme.base00
    radius: 8
    border.color: Theme.base01
    border.width: 1
    clip: true
    
    MouseArea {
        id: mainHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse => mouse.accepted = false
        onPressed: mouse => mouse.accepted = false
        onReleased: mouse => mouse.accepted = false
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8

        // Header with power toggle
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "\uf293  Bluetooth"
                color: Theme.base04
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Power toggle
            Rectangle {
                width: 40
                height: 20
                radius: 10
                color: popup.powered ? Theme.base0B : Theme.base01
                
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    x: popup.powered ? parent.width - width - 2 : 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.base05
                    
                    Behavior on x {
                        NumberAnimation { duration: 150 }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.togglePower()
                    onEntered: popup.mouseEntered()
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.base01
        }

        // Connection status
        Text {
            visible: popup.connected
            text: "\uf00c  " + popup.connectedDevice
            color: Theme.base0B
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 2
            }
        }

        // Paired devices list
        Text {
            visible: !popup.powered
            text: "Bluetooth is off"
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 2
            }
        }

        Repeater {
            model: popup.powered ? popup.pairedDevices : []
            
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: deviceMouse.containsMouse ? Theme.base01 : "transparent"
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    
                    Text {
                        text: "\uf025"
                        color: Theme.base03
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                        }
                    }
                    
                    Text {
                        text: modelData.name
                        color: (popup.connectedDevice === modelData.name) ? Theme.base04 : Theme.base03
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                            bold: popup.connectedDevice === modelData.name
                        }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        visible: popup.connectedDevice === modelData.name
                        text: "\uf00c"
                        color: Theme.base0B
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                        }
                    }
                }
                
                MouseArea {
                    id: deviceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: popup.mouseEntered()
                    onClicked: {
                        if (popup.connectedDevice === modelData.name) {
                            popup.disconnectDevice(modelData.mac);
                        } else {
                            popup.connectDevice(modelData.mac);
                        }
                    }
                }
            }
        }
    }
}
