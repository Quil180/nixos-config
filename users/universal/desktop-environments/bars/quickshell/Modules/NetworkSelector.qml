import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    property var networks: []
    property bool scanning: false
    
    signal networkSelected(string ssid)
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

    implicitWidth: 250
    implicitHeight: Math.max(networksColumn.height + 24, 80)
    color: Qt.rgba(Theme.base01.r, Theme.base01.g, Theme.base01.b, 0.80)
    radius: 8
    border.color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.5)
    border.width: 1
    clip: true
    
    HoverHandler {
        id: mainHover
    }



    ColumnLayout {
        id: networksColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 6

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "\uf1eb  Available Networks"
                color: Theme.base04
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: popup.scanning ? "\uf021" : ""
                color: Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                }
                RotationAnimation on rotation {
                    running: popup.scanning
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.5)
        }

        // Loading indicator
        Text {
            visible: popup.scanning && popup.networks.length === 0
            text: "Scanning..."
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 2
            }
        }

        // No networks found
        Text {
            visible: !popup.scanning && popup.networks.length === 0
            text: "No networks found"
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 2
            }
        }

        // Network list
        Repeater {
            model: popup.networks
            
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: mouseArea.containsMouse ? Qt.rgba(Theme.base0D.r, Theme.base0D.g, Theme.base0D.b, 0.20) : "transparent"
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 8
                    
                    // Signal strength icon
                    Text {
                        text: modelData.signal > 75 ? "\uf1eb" : 
                              (modelData.signal > 50 ? "\uf1eb" : 
                              (modelData.signal > 25 ? "\uf1eb" : "\uf1eb"))
                        color: modelData.signal > 60 ? Theme.base0D : 
                               (modelData.signal > 30 ? Theme.base0A : Theme.base08)
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                        }
                    }
                    
                    // Network name
                    Text {
                        text: modelData.ssid
                        color: modelData.isConnected ? Theme.base0D : (mouseArea.containsMouse ? Theme.base05 : Theme.base03)
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                            bold: modelData.isConnected
                        }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    // Security icon
                    Text {
                        visible: modelData.security !== "" && modelData.security !== "--"
                        text: "\uf023"
                        color: Theme.base02
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 4
                        }
                    }
                    
                    // Connected indicator
                    Text {
                        visible: modelData.isConnected
                        text: "\uf00c"
                        color: Theme.base0D
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                        }
                    }
                    
                    // Signal percentage
                    Text {
                        text: modelData.signal + "%"
                        color: Theme.base02
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 4
                        }
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: popup.mouseEntered()
                    onClicked: {
                        if (!modelData.isConnected) {
                            popup.networkSelected(modelData.ssid);
                        }
                    }
                }
            }
        }
    }
}
