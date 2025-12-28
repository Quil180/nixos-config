import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    property string temperature: ""
    property string conditions: ""
    property string location: ""
    
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
    
    function getWeatherIcon(cond) {
        var c = cond.toLowerCase();
        if (c.includes("sun") || c.includes("clear")) return "\uf185";
        if (c.includes("cloud")) return "\uf0c2";
        if (c.includes("rain") || c.includes("drizzle")) return "\uf043";
        if (c.includes("snow")) return "\uf2dc";
        if (c.includes("thunder") || c.includes("storm")) return "\uf0e7";
        if (c.includes("fog") || c.includes("mist")) return "\uf75f";
        return "\uf0c2";
    }

    implicitWidth: 180
    implicitHeight: 80
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
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Text {
                text: popup.getWeatherIcon(popup.conditions)
                color: Theme.base0A
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize + 8
                }
            }
            
            ColumnLayout {
                spacing: 2
                
                Text {
                    text: popup.temperature || "..."
                    color: Theme.base04
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize + 2
                        bold: true
                    }
                }
                
                Text {
                    text: popup.conditions || "Loading..."
                    color: Theme.base03
                    font {
                        family: Theme.fontFamily
                        pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
        
        Text {
            visible: popup.location !== ""
            text: "\uf3c5  " + popup.location
            color: Theme.base02
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 3
            }
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
