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
    signal mouseEntered()
    
    readonly property bool isHovered: mainHover.hovered
    
    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }

    implicitWidth: 220
    implicitHeight: 150
    color: Qt.rgba(Theme.base01.r, Theme.base01.g, Theme.base01.b, 0.80)
    radius: 8
    border.color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.5)
    border.width: 1
    
    HoverHandler {
        id: mainHover
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
            color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.5)
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
                color: popup.connected ? Theme.base0D : Theme.base08
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
                color: popup.signalStrength > 60 ? Theme.base0D : (popup.signalStrength > 30 ? Theme.base0A : Theme.base08)
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
