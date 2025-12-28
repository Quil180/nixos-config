import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    property int percentage: 0
    property bool charging: false
    property string status: "Unknown"
    property string timeRemaining: ""
    
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

    implicitWidth: 200
    implicitHeight: 90
    color: Theme.base00
    radius: 8
    border.color: Theme.base01
    border.width: 1
    
    MouseArea {
        id: mainHover
        anchors.fill: parent
        hoverEnabled: true
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        // Header with icon and percentage
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text {
                text: popup.charging ? "\uf0e7" : 
                      (popup.percentage > 75 ? "\uf240" :
                      (popup.percentage > 50 ? "\uf241" :
                      (popup.percentage > 25 ? "\uf242" :
                      (popup.percentage > 10 ? "\uf243" : "\uf244"))))
                color: popup.percentage <= 20 && !popup.charging ? Theme.alertColor : Theme.base04
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize + 4
                }
            }
            
            Text {
                text: popup.percentage + "%"
                color: Theme.base04
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize + 2
                    bold: true
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: popup.status
                color: popup.charging ? Theme.base0B : Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
            }
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            height: 8
            color: Theme.base01
            radius: 4
            
            Rectangle {
                width: parent.width * (popup.percentage / 100)
                height: parent.height
                radius: 4
                color: popup.percentage <= 20 ? Theme.alertColor :
                       (popup.percentage <= 50 ? Theme.base0A : Theme.base0B)
            }
        }

        // Time remaining
        Text {
            visible: popup.timeRemaining !== ""
            text: popup.charging ? "Full in " + popup.timeRemaining : popup.timeRemaining + " remaining"
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 2
            }
        }
    }
}
