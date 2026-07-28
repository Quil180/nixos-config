import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: popup

    property string title: ""
    property string artist: ""
    property string album: ""
    property string status: "Stopped"
    property bool hasPlayer: false
    
    signal playPause()
    signal next()
    signal previous()

    implicitWidth: 280
    implicitHeight: 100
    color: Qt.rgba(Theme.base01.r, Theme.base01.g, Theme.base01.b, 0.80)
    radius: 8
    border.color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.5)
    border.width: 1
    
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
    
    HoverHandler {
        id: mainHover
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        // No player message
        Text {
            visible: !popup.hasPlayer
            text: "No media playing"
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize
            }
            Layout.alignment: Qt.AlignCenter
        }

        // Media info
        ColumnLayout {
            visible: popup.hasPlayer
            spacing: 4
            Layout.fillWidth: true
            
            // Title
            Text {
                text: popup.title
                color: Theme.base05
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize
                    bold: true
                }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            // Artist
            Text {
                text: popup.artist
                color: Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Controls
        RowLayout {
            visible: popup.hasPlayer
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            
            // Previous
            Text {
                text: "\uf048"
                color: controlPrev.containsMouse ? Theme.base0D : Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize + 4
                }
                MouseArea {
                    id: controlPrev
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.previous()
                    onEntered: popup.mouseEntered()
                }
            }
            
            // Play/Pause
            Text {
                text: popup.status === "Playing" ? "\uf04c" : "\uf04b"
                color: controlPlay.containsMouse ? Theme.base0D : (popup.status === "Playing" ? Theme.base0D : Theme.base04)
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize + 8
                }
                MouseArea {
                    id: controlPlay
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.playPause()
                    onEntered: popup.mouseEntered()
                }
            }
            
            // Next
            Text {
                text: "\uf051"
                color: controlNext.containsMouse ? Theme.base0D : Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize + 4
                }
                MouseArea {
                    id: controlNext
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.next()
                    onEntered: popup.mouseEntered()
                }
            }
        }
    }
}

