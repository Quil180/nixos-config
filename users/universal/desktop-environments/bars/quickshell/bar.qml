import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

import "Modules" as Modules

PanelWindow {
    id: root

    // Ensuring the bar is on the top and all the way to the left and right
    anchors {
        top: true
        left: true
        right: true
    }
    // Setting the maximum height to be 30
    implicitHeight: 30
    // Setting the background color to be base00
    color: Modules.Theme.base00

    // Widget data sources
    Modules.CpuWidget { id: cpuWidget }
    Modules.MemoryWidget { id: memWidget }
    Modules.TemperatureWidget { id: tempWidget }
    Modules.BrightnessWidget { id: brightnessWidget }
    Modules.VolumeWidget { id: volumeWidget }
    Modules.NetworkWidget { id: networkWidget }
    Modules.WindowWidget { id: windowWidget }

    // Track network icon position for popup
    property real networkIconX: 0

    // Network popup window
    PopupWindow {
        id: networkPopupWindow
        visible: false
        width: networkPopup.width
        height: networkPopup.height
        anchor {
            item: networkIcon
            edges: Edges.Bottom
            gravity: Edges.Bottom
        }
        
        color: "transparent"
        
        Modules.NetworkPopup {
            id: networkPopup
            ssid: networkWidget.ssid
            ipAddress: networkWidget.ipAddress
            signalStrength: networkWidget.signalStrength
            connected: networkWidget.connected
            
            // Transform origin at top center (where wifi icon is)
            transformOrigin: Item.Top
            
            // Animation properties - scale and fade for pop-out effect
            opacity: networkPopupWindow.visible ? 1 : 0
            scale: networkPopupWindow.visible ? 1 : 0.8
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }
            
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }
            
            onMouseExited: networkPopupWindow.visible = false
        }
    }

    // Network selector popup window (right-click)
    PopupWindow {
        id: networkSelectorWindow
        visible: false
        width: networkSelector.width
        height: networkSelector.height
        anchor {
            item: networkIcon
            edges: Edges.Bottom
            gravity: Edges.Bottom
        }
        
        color: "transparent"
        
        Modules.NetworkSelector {
            id: networkSelector
            networks: networkWidget.availableNetworks
            scanning: networkWidget.scanning
            
            // Transform origin at top center
            transformOrigin: Item.Top
            
            // Animation properties
            opacity: networkSelectorWindow.visible ? 1 : 0
            scale: networkSelectorWindow.visible ? 1 : 0.8
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }
            
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }
            
            onNetworkSelected: ssid => {
                networkWidget.connectToNetwork(ssid);
                networkSelectorWindow.visible = false;
            }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            margins: 5
        }

        // Workspaces showing!!
        Modules.Workspaces {
            id: workspaces
        }

        // Spacer
        Modules.Spacer {}

        // Active Window Title
        Text {
            text: windowWidget.activeWindow
            color: Modules.Theme.base04
            font {
                family: Modules.Theme.fontFamily
                pixelSize: Modules.Theme.fontSize
                bold: true
            }
            Layout.fillWidth: true
            Layout.leftMargin: 8
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Spacer to push rest to the very right
        Item {
            Layout.fillWidth: true
        }

        // CPU Usage Text
        Text {
            id: cpu
            text: "\uf4bc  - " + cpuWidget.cpuUsage + "%"
            color: cpuWidget.cpuUsage > 75 ? Modules.Theme.alertColor : Modules.Theme.base03
            font {
                family: Modules.Theme.fontFamily
                pixelSize: Modules.Theme.fontSize
                bold: true
            }
        }

        Modules.Spacer {}

        // Memory Usage Text
        Text {
            id: memory
            text: "\uefc5  - " + memWidget.memUsage + "%"
            color: memWidget.memUsage > 75 ? Modules.Theme.alertColor : Modules.Theme.base03
            font {
                family: Modules.Theme.fontFamily
                pixelSize: Modules.Theme.fontSize
                bold: true
            }

            property bool clicked: false

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    memory.clicked = !memory.clicked;
                    memory.text = memory.clicked ? "\uefc5  - " + memWidget.memUsage + "%" : "\uefc5  - " + memWidget.memUsed + "MB";
                }
            }
        }

        Modules.Spacer {}

        // CPU Temperature Text
        Text {
            id: temperature
            text: "\uef2a  - " + tempWidget.tempCPU + "C"
            color: tempWidget.tempCPU > 85 ? Modules.Theme.alertColor : Modules.Theme.base03
            font {
                family: Modules.Theme.fontFamily
                pixelSize: Modules.Theme.fontSize
                bold: true
            }
        }

        Modules.Spacer {}

        // Brightness Percentage Text
        Text {
            id: brightness
            text: "\udb80\udce0  - " + brightnessWidget.brightnessMain + "%"
            color: Modules.Theme.base03
            font {
                family: Modules.Theme.fontFamily
                pixelSize: Modules.Theme.fontSize
                bold: true
            }
        }

        Modules.Spacer {}

        // Volume Percentage Text
        Text {
            id: volume
            text: (volumeWidget.muted ? "\ueee8" : "\uf028" + "  - " + volumeWidget.volume + "%")
            color: volumeWidget.muted ? Modules.Theme.alertColor : Modules.Theme.base03
            font {
                family: Modules.Theme.fontFamily
                pixelSize: Modules.Theme.fontSize
                bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: volumeWidget.toggleMute()
            }
        }

        Modules.Spacer {}

        // Network Icon
        Text {
            id: networkIcon
            text: networkWidget.connected ? "\uf1eb" : "\uf467"
            color: networkWidget.connected ? Modules.Theme.base03 : Modules.Theme.alertColor
            font {
                family: Modules.Theme.fontFamily
                pixelSize: Modules.Theme.fontSize
                bold: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        // Right-click: show network selector and scan
                        networkPopupWindow.visible = false;
                        networkWidget.scanNetworks();
                        networkSelectorWindow.visible = !networkSelectorWindow.visible;
                    } else {
                        // Left-click: show connection info
                        networkSelectorWindow.visible = false;
                        networkPopupWindow.visible = !networkPopupWindow.visible;
                    }
                }
            }
        }

        Modules.Spacer {}

        // Clock!!
        Modules.Clock {}
    }
}

