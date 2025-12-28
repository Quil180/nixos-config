import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    property string ssid: ""
    property string ipAddress: ""
    property int signalStrength: 0
    property bool connected: false
    
    signal mouseExited()
    
    // Track if mouse is over popup
    property bool mouseOver: false

    width: 220
    height: 150
    color: Theme.base00
    radius: 8
    border.color: Theme.base01
    border.width: 1
    
    // Delay before hiding to allow moving from bar to popup
    Timer {
        id: hideTimer
        interval: 150
        onTriggered: {
            if (!popup.mouseOver) {
                popup.mouseExited();
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            popup.mouseOver = true;
            hideTimer.stop();
        }
        onExited: {
            popup.mouseOver = false;
            hideTimer.restart();
        }
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

        // Header
        Text {
            text: "\uf1eb  Network"
            color: Theme.base04
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize
                bold: true
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.base01
        }

        // Connection Status
        RowLayout {
            spacing: 8
            Text {
                text: "Status:"
                color: Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
            }
            Text {
                text: popup.connected ? "Connected" : "Disconnected"
                color: popup.connected ? Theme.base0B : Theme.alertColor
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                    bold: true
                }
            }
        }

        // SSID
        RowLayout {
            visible: popup.connected
            spacing: 8
            Text {
                text: "SSID:"
                color: Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
            }
            Text {
                text: popup.ssid
                color: Theme.base05
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Signal Strength
        RowLayout {
            visible: popup.connected
            spacing: 8
            Text {
                text: "Signal:"
                color: Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
            }
            Text {
                text: popup.signalStrength + "%"
                color: popup.signalStrength > 60 ? Theme.base0B : (popup.signalStrength > 30 ? Theme.base0A : Theme.alertColor)
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                    bold: true
                }
            }
        }

        // IP Address
        RowLayout {
            visible: popup.connected
            spacing: 8
            Text {
                text: "IP:"
                color: Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
            }
            Text {
                text: popup.ipAddress
                color: Theme.base05
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
            }
        }
    }
}
