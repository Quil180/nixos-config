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
    
    // Computed hover state - checks main area and all network item mouse areas
    readonly property bool isHovered: mainHover.containsMouse
    
    onIsHoveredChanged: {
        if (isHovered) {
            popup.mouseEntered();
        } else {
            popup.mouseExited();
        }
    }

    implicitWidth: 250
    implicitHeight: Math.max(networksColumn.height + 24, 80)
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
            color: Theme.base01
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
                color: mouseArea.containsMouse ? Theme.base01 : "transparent"
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
                        color: modelData.signal > 60 ? Theme.base0B : 
                               (modelData.signal > 30 ? Theme.base0A : Theme.alertColor)
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                        }
                    }
                    
                    // Network name
                    Text {
                        text: modelData.ssid
                        color: modelData.isConnected ? Theme.base04 : Theme.base03
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
                        color: Theme.base0B
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
