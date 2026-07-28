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
    
    readonly property bool isHovered: mainHover.hovered
    
    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }

    implicitWidth: 200
    implicitHeight: 90
    color: Qt.rgba(Theme.base01.r, Theme.base01.g, Theme.base01.b, 0.80)
    radius: 8
    border.color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.5)
    border.width: 1
    
    HoverHandler {
        id: mainHover
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
                color: popup.percentage <= 20 && !popup.charging ? Theme.base08 : Theme.base04
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
                color: popup.charging ? Theme.base0D : Theme.base03
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
            color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.4)
            radius: 4
            
            Rectangle {
                width: parent.width * (popup.percentage / 100)
                height: parent.height
                radius: 4
                color: popup.percentage <= 20 ? Theme.base08 :
                       (popup.percentage <= 50 ? Theme.base0A : Theme.base0D)
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
