import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Hyprland

import QtQuick
import QtQuick.Layouts

import "Modules" as Modules

Scope {
    // Widget data sources (Shared across screens)
    Modules.CpuWidget { id: cpuWidget }
    Modules.MemoryWidget { id: memWidget }
    Modules.TemperatureWidget { id: tempWidget }
    Modules.BrightnessWidget { id: brightnessWidget }
    Modules.VolumeWidget { id: volumeWidget }
    Modules.MusicWidget { id: musicWidget }
    Modules.NetworkWidget { id: networkWidget }
    Modules.WindowWidget { id: windowWidget }
    Modules.BatteryWidget { id: batteryWidget }
    Modules.BluetoothWidget { id: bluetoothWidget }
    Modules.KeyboardWidget { id: keyboardWidget }
    Modules.WeatherWidget { id: weatherWidget }

    // Notification Server (replaces dunst)
    NotificationServer {
        id: notificationServer
        
        // Track DND state
        property bool dndEnabled: false
        
        // Store notification history
        property var notificationHistory: []
        
        onNotification: notification => {
            if (!dndEnabled) {
                // Add to active notifications (for toasts)
                // The notification will be displayed by the notification layer
            }
            // Add to history
            notificationHistory = [{
                id: notification.id,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                timestamp: new Date()
            }].concat(notificationHistory.slice(0, 49));
        }
    }

    Repeater {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: root
            
            // Screen binding
            screen: modelData
            
            // Secondary screen detection
            property bool isSecondary: index !== 0

            // Ensuring the bar is on the top and all the way to the left and right
            anchors {
                top: true
                left: true
                right: true
            }
            // Setting the maximum height to be 30
            implicitHeight: 30
            // Glassmorphism background - semi-transparent with subtle gradient
            color: Qt.rgba(
                parseInt(Modules.Theme.base00.toString().slice(1, 3), 16) / 255,
                parseInt(Modules.Theme.base00.toString().slice(3, 5), 16) / 255,
                parseInt(Modules.Theme.base00.toString().slice(5, 7), 16) / 255,
            )

            // Track network icon position for popup
            property real networkIconX: 0
            
            // Timer for hiding network popup
            Timer {
                id: networkHideTimer
                interval: 500
                onTriggered: networkPopupWindow.visible = false
            }

            // Network popup window
            PopupWindow {
                id: networkPopupWindow
                visible: false
                implicitWidth: networkPopup.implicitWidth
                implicitHeight: networkPopup.implicitHeight
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
                    
                    onMouseEntered: networkHideTimer.stop()
                    onMouseExited: networkHideTimer.restart()
                }
            }

            // Timer for hiding network selector popup
            Timer {
                id: networkSelectorHideTimer
                interval: 500
                onTriggered: networkSelectorWindow.visible = false
            }

            // Network selector popup window (right-click)
            PopupWindow {
                id: networkSelectorWindow
                visible: false
                implicitWidth: networkSelector.implicitWidth
                implicitHeight: networkSelector.implicitHeight
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
                    
                    onMouseEntered: networkSelectorHideTimer.stop()
                    onMouseExited: networkSelectorHideTimer.restart()
                }
            }

            // Timer for hiding music popup
            Timer {
                id: musicHideTimer
                interval: 500
                onTriggered: {
                    // Only hide if we're really not hovering anything in the popup
                    musicPopupWindow.visible = false
                }
            }

            // Music popup window (hover over volume)
            PopupWindow {
                id: musicPopupWindow
                visible: false
                implicitWidth: musicPopup.implicitWidth
                implicitHeight: musicPopup.implicitHeight
                anchor {
                    item: volumeText
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                
                color: "transparent"
                
                Modules.MusicPopup {
                    id: musicPopup
                    title: musicWidget.title
                    artist: musicWidget.artist
                    album: musicWidget.album
                    status: musicWidget.status
                    hasPlayer: musicWidget.hasPlayer
                    
                    transformOrigin: Item.Top
                    opacity: musicPopupWindow.visible ? 1 : 0
                    scale: musicPopupWindow.visible ? 1 : 0.8
                    
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
                    
                    onPlayPause: musicWidget.playPause()
                    onNext: musicWidget.next()
                    onPrevious: musicWidget.previous()
                    onMouseEntered: musicHideTimer.stop()
                    onMouseExited: musicHideTimer.restart()
                }
            }

            // Timer for battery popup
            Timer {
                id: batteryHideTimer
                interval: 500
                onTriggered: batteryPopupWindow.visible = false
            }

            // Battery popup window
            PopupWindow {
                id: batteryPopupWindow
                visible: false
                implicitWidth: batteryPopup.implicitWidth
                implicitHeight: batteryPopup.implicitHeight
                anchor {
                    item: batteryIcon
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                color: "transparent"
                
                Modules.BatteryPopup {
                    id: batteryPopup
                    percentage: batteryWidget.percentage
                    charging: batteryWidget.charging
                    status: batteryWidget.status
                    timeRemaining: batteryWidget.timeRemaining
                    
                    transformOrigin: Item.Top
                    opacity: batteryPopupWindow.visible ? 1 : 0
                    scale: batteryPopupWindow.visible ? 1 : 0.8
                    
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    
                    onMouseEntered: batteryHideTimer.stop()
                    onMouseExited: batteryHideTimer.restart()
                }
            }

            // Timer for bluetooth popup  
            Timer {
                id: bluetoothHideTimer
                interval: 500
                onTriggered: bluetoothPopupWindow.visible = false
            }

            // Bluetooth popup window
            PopupWindow {
                id: bluetoothPopupWindow
                visible: false
                implicitWidth: bluetoothPopup.implicitWidth
                implicitHeight: bluetoothPopup.implicitHeight
                anchor {
                    item: bluetoothIcon
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                color: "transparent"
                
                Modules.BluetoothPopup {
                    id: bluetoothPopup
                    powered: bluetoothWidget.powered
                    connected: bluetoothWidget.connected
                    connectedDevice: bluetoothWidget.connectedDevice
                    pairedDevices: bluetoothWidget.pairedDevices
                    
                    transformOrigin: Item.Top
                    opacity: bluetoothPopupWindow.visible ? 1 : 0
                    scale: bluetoothPopupWindow.visible ? 1 : 0.8
                    
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    
                    onTogglePower: bluetoothWidget.togglePower()
                    onConnectDevice: mac => bluetoothWidget.connectDevice(mac)
                    onDisconnectDevice: mac => bluetoothWidget.disconnectDevice(mac)
                    onMouseEntered: bluetoothHideTimer.stop()
                    onMouseExited: bluetoothHideTimer.restart()
                }
            }

            // Timer for calendar popup
            Timer {
                id: calendarHideTimer
                interval: 500
                onTriggered: calendarPopupWindow.visible = false
            }

            // Calendar popup window
            PopupWindow {
                id: calendarPopupWindow
                visible: false
                implicitWidth: calendarPopup.implicitWidth
                implicitHeight: calendarPopup.implicitHeight
                anchor {
                    item: clockItem
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                color: "transparent"
                
                Modules.CalendarPopup {
                    id: calendarPopup
                    
                    transformOrigin: Item.Top
                    opacity: calendarPopupWindow.visible ? 1 : 0
                    scale: calendarPopupWindow.visible ? 1 : 0.8
                    
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    
                    onMouseEntered: calendarHideTimer.stop()
                    onMouseExited: calendarHideTimer.restart()
                }
            }

            // Timer for weather popup
            Timer {
                id: weatherHideTimer
                interval: 500
                onTriggered: weatherPopupWindow.visible = false
            }

            // Weather popup window
            PopupWindow {
                id: weatherPopupWindow
                visible: false
                implicitWidth: weatherPopup.implicitWidth
                implicitHeight: weatherPopup.implicitHeight
                anchor {
                    item: weatherIcon
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                color: "transparent"
                
                Modules.WeatherPopup {
                    id: weatherPopup
                    temperature: weatherWidget.temperature
                    conditions: weatherWidget.conditions
                    location: weatherWidget.location
                    
                    transformOrigin: Item.Top
                    opacity: weatherPopupWindow.visible ? 1 : 0
                    scale: weatherPopupWindow.visible ? 1 : 0.8
                    
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    
                    onMouseEntered: weatherHideTimer.stop()
                    onMouseExited: weatherHideTimer.restart()
                }
            }

            // Timer for notification popup
            Timer {
                id: notificationHideTimer
                interval: 500
                onTriggered: notificationPopupWindow.visible = false
            }

            // Notification popup window
            PopupWindow {
                id: notificationPopupWindow
                visible: false
                implicitWidth: notificationPopup.implicitWidth
                implicitHeight: notificationPopup.implicitHeight
                anchor {
                    item: notificationIcon
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                color: "transparent"
                
                Modules.NotificationPopup {
                    id: notificationPopup
                    notifications: notificationServer.notificationHistory
                    count: notificationServer.notificationHistory.length
                    
                    transformOrigin: Item.Top
                    opacity: notificationPopupWindow.visible ? 1 : 0
                    scale: notificationPopupWindow.visible ? 1 : 0.8
                    
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    
                    onClearAll: notificationServer.notificationHistory = []
                    onDismissNotification: id => {
                        notificationServer.notificationHistory = notificationServer.notificationHistory.filter(n => n.id !== id)
                    }
                    onMouseEntered: notificationHideTimer.stop()
                    onMouseExited: notificationHideTimer.restart()
                }
            }

            // Timer for power menu
            Timer {
                id: powerHideTimer
                interval: 500
                onTriggered: powerMenuWindow.visible = false
            }

            // Power menu popup window
            PopupWindow {
                id: powerMenuWindow
                visible: false
                implicitWidth: powerMenu.implicitWidth
                implicitHeight: powerMenu.implicitHeight
                anchor {
                    item: powerIcon
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                color: "transparent"
                
                Modules.PowerMenu {
                    id: powerMenu
                    
                    transformOrigin: Item.Top
                    opacity: powerMenuWindow.visible ? 1 : 0
                    scale: powerMenuWindow.visible ? 1 : 0.8
                    
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    
                    onActionTriggered: powerMenuWindow.visible = false
                    onMouseEntered: powerHideTimer.stop()
                    onMouseExited: powerHideTimer.restart()
                }
            }

            RowLayout {
                id: barLayout
                anchors {
                    fill: parent
                    margins: 5
                }

                // Workspaces showing!!
                // Hidden on secondary screens
                Modules.Workspaces {
                    id: workspaces
                    visible: !isSecondary
                }

                // Spacer
                Modules.Spacer {
                    visible: !isSecondary
                }

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
                    visible: !isSecondary
                }

                // Spacer to push rest to the very right
                Item {
                    Layout.fillWidth: true
                }

                // System Stats Group (no separators between them)
                RowLayout {
                    spacing: 12
                    
                    // CPU Usage with mini progress
                    Row {
                        spacing: 4
                        Modules.MiniProgress {
                            value: cpuWidget.cpuUsage
                            progressColor: Modules.Theme.usageColor(cpuWidget.cpuUsage)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "\uf4bc " + cpuWidget.cpuUsage + "%"
                            color: Modules.Theme.usageColor(cpuWidget.cpuUsage)
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                    
                    // Memory Usage with mini progress
                    Row {
                        spacing: 4
                        property bool showMB: false
                        
                        Modules.MiniProgress {
                            value: memWidget.memUsage
                            progressColor: Modules.Theme.usageColor(memWidget.memUsage)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: memText
                            text: parent.showMB ? "\uefc5 " + memWidget.memUsed + "MB" : "\uefc5 " + memWidget.memUsage + "%"
                            color: Modules.Theme.usageColor(memWidget.memUsage)
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            Behavior on color { ColorAnimation { duration: 200 } }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: parent.parent.showMB = !parent.parent.showMB
                            }
                        }
                    }
                    
                    // CPU Temperature with mini progress
                    Row {
                        spacing: 4
                        Modules.MiniProgress {
                            value: tempWidget.tempCPU
                            progressColor: Modules.Theme.tempColor(tempWidget.tempCPU)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "\uef2a " + tempWidget.tempCPU + "°"
                            color: Modules.Theme.tempColor(tempWidget.tempCPU)
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                Modules.Spacer {}

                // Audio/Display Group
                RowLayout {
                    spacing: 12
                    
                    // Brightness
                    Text {
                        text: "\udb80\udce0  " + brightnessWidget.brightnessMain + "%"
                        color: Modules.Theme.base03
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                    }
                    
                    // Volume
                    Item {
                        implicitWidth: volumeText.implicitWidth
                        implicitHeight: volumeText.implicitHeight
                        
                        Text {
                            id: volumeText
                            anchors.centerIn: parent
                            text: volumeWidget.muted ? "\ueee8" : "\uf028  " + volumeWidget.volume + "%"
                            color: volumeMouse.containsMouse ? Modules.Theme.base04 :
                                   (volumeWidget.muted ? Modules.Theme.alertColor : Modules.Theme.base03)
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            scale: volumeMouse.containsMouse ? 1.1 : 1.0
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                        }
                        
                        MouseArea {
                            id: volumeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: volumeWidget.toggleMute()
                            onEntered: {
                                musicHideTimer.stop();
                                musicPopupWindow.visible = true;
                            }
                            onExited: musicHideTimer.restart()
                        }
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
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: {
                            networkHideTimer.stop();
                        }
                        onExited: {
                            if (networkPopupWindow.visible) {
                                networkHideTimer.restart();
                            }
                        }
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                // Right-click: show network selector and scan
                                networkPopupWindow.visible = false;
                                networkWidget.scanNetworks();
                                networkSelectorWindow.visible = !networkSelectorWindow.visible;
                            } else {
                                // Left-click: show connection info
                                networkSelectorWindow.visible = false;
                                networkHideTimer.stop();
                                networkPopupWindow.visible = !networkPopupWindow.visible;
                            }
                        }
                    }
                }

                Modules.Spacer {}

                // Weather Icon
                Text {
                    id: weatherIcon
                    text: "\uf0c2"
                    color: weatherMouse.containsMouse ? Modules.Theme.base04 : Modules.Theme.base03
                    font {
                        family: Modules.Theme.fontFamily
                        pixelSize: Modules.Theme.fontSize
                        bold: true
                    }
                    scale: weatherMouse.containsMouse ? 1.15 : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    
                    MouseArea {
                        id: weatherMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { weatherHideTimer.stop(); weatherPopupWindow.visible = true; }
                        onExited: weatherHideTimer.restart()
                    }
                }

                Modules.Spacer {}

                // Battery Icon
                Text {
                    id: batteryIcon
                    text: batteryWidget.charging ? "\uf0e7" : 
                          (batteryWidget.percentage > 75 ? "\uf240" :
                          (batteryWidget.percentage > 50 ? "\uf241" :
                          (batteryWidget.percentage > 25 ? "\uf242" :
                          (batteryWidget.percentage > 10 ? "\uf243" : "\uf244"))))
                    color: batteryMouse.containsMouse ? Modules.Theme.base04 :
                           (batteryWidget.percentage <= 20 && !batteryWidget.charging ? Modules.Theme.alertColor : Modules.Theme.base03)
                    font {
                        family: Modules.Theme.fontFamily
                        pixelSize: Modules.Theme.fontSize
                        bold: true
                    }
                    scale: batteryMouse.containsMouse ? 1.15 : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    
                    MouseArea {
                        id: batteryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { batteryHideTimer.stop(); batteryPopupWindow.visible = true; }
                        onExited: batteryHideTimer.restart()
                    }
                }

                Modules.Spacer {}

                // Bluetooth Icon
                Text {
                    id: bluetoothIcon
                    text: "\uf293"
                    color: bluetoothMouse.containsMouse ? Modules.Theme.base04 :
                           (bluetoothWidget.connected ? Modules.Theme.base0D : 
                           (bluetoothWidget.powered ? Modules.Theme.base03 : Modules.Theme.base02))
                    font {
                        family: Modules.Theme.fontFamily
                        pixelSize: Modules.Theme.fontSize
                        bold: true
                    }
                    scale: bluetoothMouse.containsMouse ? 1.15 : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    
                    MouseArea {
                        id: bluetoothMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { bluetoothHideTimer.stop(); bluetoothPopupWindow.visible = true; }
                        onExited: bluetoothHideTimer.restart()
                    }
                }

                Modules.Spacer {}

                // Notification/DND Icon (merged: hover=notifications, click=toggle DND)
                // Hidden on secondary screens
                Text {
                    id: notificationIcon
                    visible: !isSecondary
                    text: notificationServer.dndEnabled ? "\uf1f6" : "\uf0f3"
                    color: notificationMouse.containsMouse ? Modules.Theme.base04 :
                           (notificationServer.dndEnabled ? Modules.Theme.alertColor : 
                           (notificationServer.notificationHistory.length > 0 ? Modules.Theme.base0A : Modules.Theme.base03))
                    font {
                        family: Modules.Theme.fontFamily
                        pixelSize: Modules.Theme.fontSize
                        bold: true
                    }
                    scale: notificationMouse.containsMouse ? 1.15 : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    
                    MouseArea {
                        id: notificationMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { notificationHideTimer.stop(); notificationPopupWindow.visible = true; }
                        onExited: notificationHideTimer.restart()
                        onClicked: notificationServer.dndEnabled = !notificationServer.dndEnabled
                    }
                }


                // Power Icon
                Text {
                    id: powerIcon
                    text: "\uf011"
                    color: powerMouse.containsMouse ? Modules.Theme.alertColor : Modules.Theme.base03
                    font {
                        family: Modules.Theme.fontFamily
                        pixelSize: Modules.Theme.fontSize
                        bold: true
                    }
                    scale: powerMouse.containsMouse ? 1.15 : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    
                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { powerHideTimer.stop(); powerMenuWindow.visible = true; }
                        onExited: powerHideTimer.restart()
                    }
                }

                Modules.Spacer {
                    visible: !isSecondary
                }

                // Clock with calendar popup
                // Hidden on secondary screens
                Item {
                    id: clockItem
                    visible: !isSecondary
                    implicitWidth: clockText.implicitWidth
                    implicitHeight: clockText.implicitHeight
                    
                    Text {
                        id: clockText
                        text: Qt.formatDateTime(new Date(), "ddd MMM d  -  h:mm:ss AP")
                        color: Modules.Theme.base04
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                    }
                    
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd MMM d  -  h:mm:ss AP")
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { calendarHideTimer.stop(); calendarPopupWindow.visible = true; }
                        onExited: calendarHideTimer.restart()
                    }
                }
            }
        }
    }
}
