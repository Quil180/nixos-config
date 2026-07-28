//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import Quickshell.Hyprland

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "Modules" as Modules

Scope {
    Component.onCompleted: {
        console.log("Scope loaded!");
        console.log("Quickshell.screens length: " + Quickshell.screens.length);
        console.log("WlrLayer exists: " + (typeof WlrLayer !== 'undefined'));
        if (typeof WlrLayer !== 'undefined') {
            console.log("WlrLayer.Overlay: " + WlrLayer.Background);
        }
        console.log("WlrLayershell exists: " + (typeof WlrLayershell !== 'undefined'));
    }

    // Widget data sources (Shared across screens)
    Modules.CpuWidget {
        id: cpuWidget
    }
    Modules.MemoryWidget {
        id: memWidget
    }
    Modules.TemperatureWidget {
        id: tempWidget
    }
    Modules.BrightnessWidget {
        id: brightnessWidget
    }
    Modules.VolumeWidget {
        id: volumeWidget
    }
    Modules.MusicWidget {
        id: musicWidget
    }
    Modules.NetworkWidget {
        id: networkWidget
    }
    Modules.BatteryWidget {
        id: batteryWidget
    }
    Modules.BluetoothWidget {
        id: bluetoothWidget
    }
    Modules.KeyboardWidget {
        id: keyboardWidget
    }
    Modules.WeatherWidget {
        id: weatherWidget
    }
    Modules.WallpaperWidget {
        id: wallpaperWidgetData
    }

    // Desktop Wallpaper Windows (Layer Shell Background)
    Instantiator {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: wallpaperWindow
            visible: true
            screen: modelData

            WlrLayershell.namespace: "quickshell-wallpaper"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "black"

            property bool useImage1: true

            Image {
                id: bgImage1
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                asynchronous: true
                opacity: 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }
                }

                onStatusChanged: {
                    if (status === Image.Ready && !wallpaperWindow.useImage1 && bgImage1.source !== "") {
                        wallpaperWindow.useImage1 = true
                        bgImage1.opacity = 1.0
                        bgImage2.opacity = 0.0
                    }
                }
            }

            Image {
                id: bgImage2
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                asynchronous: true
                opacity: 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }
                }

                onStatusChanged: {
                    if (status === Image.Ready && wallpaperWindow.useImage1 && bgImage2.source !== "") {
                        wallpaperWindow.useImage1 = false
                        bgImage2.opacity = 1.0
                        bgImage1.opacity = 0.0
                    }
                }
            }

            Connections {
                target: wallpaperWidgetData
                function onCurrentWallpaperChanged() {
                    var newPath = wallpaperWidgetData.currentWallpaper
                    if (!newPath) return
                    var newSource = "file://" + newPath

                    if (bgImage1.source == "" && bgImage2.source == "") {
                        bgImage1.source = newSource
                        bgImage1.opacity = 1.0
                        bgImage2.opacity = 0.0
                        wallpaperWindow.useImage1 = true
                        return
                    }

                    if (wallpaperWindow.useImage1) {
                        if (bgImage1.source == newSource) return
                        bgImage2.source = newSource
                        if (bgImage2.status === Image.Ready) {
                            wallpaperWindow.useImage1 = false
                            bgImage2.opacity = 1.0
                            bgImage1.opacity = 0.0
                        }
                    } else {
                        if (bgImage2.source == newSource) return
                        bgImage1.source = newSource
                        if (bgImage1.status === Image.Ready) {
                            wallpaperWindow.useImage1 = true
                            bgImage1.opacity = 1.0
                            bgImage2.opacity = 0.0
                        }
                    }
                }
            }

            Component.onCompleted: {
                if (wallpaperWidgetData.currentWallpaper) {
                    bgImage1.source = "file://" + wallpaperWidgetData.currentWallpaper
                    bgImage1.opacity = 1.0
                    bgImage2.opacity = 0.0
                    wallpaperWindow.useImage1 = true
                }
            }
        }
    }


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
            notificationHistory = [
                {
                    id: notification.id,
                    appName: notification.appName,
                    summary: notification.summary,
                    body: notification.body,
                    timestamp: new Date()
                }
            ].concat(notificationHistory.slice(0, 49));
        }
    }

    Instantiator {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: root
            visible: true

            // Screen binding
            screen: modelData

            // Identify secondary screens (optional but used in visibility logic)
            property bool isSecondary: root.screen !== Quickshell.screens[0]

            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: 8
                left: 10
                right: 10
            }

            implicitHeight: 38
            color: "transparent"
            exclusiveZone: implicitHeight + 8

            // Timer for hiding network selector popup
            Timer {
                id: networkSelectorHideTimer
                interval: 500
                onTriggered: networkSelectorWindow.visible = false
            }

            // Timer for hiding music popup
            Timer {
                id: musicHideTimer
                interval: 500
                onTriggered: {
                    // Only hide if we're really not hovering anything in the popup
                    musicPopupWindow.visible = false;
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

                    onClearAll: notificationServer.notificationHistory = []
                    onDismissNotification: id => {
                        notificationServer.notificationHistory = notificationServer.notificationHistory.filter(n => n.id !== id);
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

                    onActionTriggered: powerMenuWindow.visible = false
                    onMouseEntered: powerHideTimer.stop()
                    onMouseExited: powerHideTimer.restart()
                }
            }

            // Timer for wallpaper popup
            Timer {
                id: wallpaperHideTimer
                interval: 500
                onTriggered: wallpaperPopupWindow.visible = false
            }

            // Timer for tray popup
            Timer {
                id: trayHideTimer
                interval: 500
                onTriggered: trayPopupWindow.visible = false
            }

            // Tray popup window
            PopupWindow {
                id: trayPopupWindow
                visible: false
                implicitWidth: trayPopup.implicitWidth
                implicitHeight: trayPopup.implicitHeight
                anchor {
                    item: trayIcon
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                color: "transparent"

                Modules.TrayPopup {
                    id: trayPopup
                    parentWindow: root

                    transformOrigin: Item.Top
                    opacity: trayPopupWindow.visible ? 1 : 0
                    scale: trayPopupWindow.visible ? 1 : 0.8

                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                    }

                    onMouseEntered: trayHideTimer.stop()
                    onMouseExited: trayHideTimer.restart()
                }
            }

            // Wallpaper picker popup window
            PopupWindow {
                id: wallpaperPopupWindow
                visible: false
                implicitWidth: wallpaperPicker.implicitWidth
                implicitHeight: wallpaperPicker.implicitHeight
                anchor {
                    item: wallpaperIcon
                    edges: Edges.Bottom
                    gravity: Edges.Bottom
                }
                color: "transparent"

                Modules.WallpaperPicker {
                    id: wallpaperPicker
                    wallpaperWidget: wallpaperWidgetData

                    transformOrigin: Item.Top
                    opacity: wallpaperPopupWindow.visible ? 1 : 0
                    scale: wallpaperPopupWindow.visible ? 1 : 0.8

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

                    onWallpaperSelected: wallpaperPopupWindow.visible = false
                    onMouseEntered: wallpaperHideTimer.stop()
                    onMouseExited: wallpaperHideTimer.restart()
                }
            }

            // Floating Bar Visual Container (Transparent for floating island pills)
            Rectangle {
                id: barBackground
                anchors.fill: parent
                color: "transparent"
                border.color: "transparent"
                border.width: 0
            }

            RowLayout {
                id: barLayout
                anchors {
                    fill: parent
                    leftMargin: 8
                    rightMargin: 8
                    topMargin: 0
                    bottomMargin: 0
                }
                spacing: 8

                // Inline Pill component definition
                component Pill: Item {
                    id: pillRoot
                    default property alias content: inner.data
                    implicitHeight: 30
                    implicitWidth: inner.implicitWidth + 24
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        id: pill
                        anchors.fill: parent
                        radius: 16
                        color: Qt.rgba(Modules.Theme.base00.r, Modules.Theme.base00.g, Modules.Theme.base00.b, 0.85)
                        border.color: Qt.rgba(Modules.Theme.base02.r, Modules.Theme.base02.g, Modules.Theme.base02.b, 0.4)
                        border.width: 1

                        RowLayout {
                            id: inner
                            anchors.centerIn: parent
                            spacing: 10
                        }
                    }
                }

                // Workspaces Pill
                Pill {
                    id: workspacesPill
                    Modules.Workspaces {
                        id: workspaces
                        monitorName: root.screen.name
                    }
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }

                // Active Window Title Pill
                Pill {
                    id: windowTitlePill
                    visible: windowTitleText.text !== ""
                    Layout.maximumWidth: 400

                    Text {
                        id: windowTitleText
                        property var monitor: Hyprland.monitors.values.find(m => m.name === root.screen.name)
                        text: monitor && monitor.activeWorkspace && monitor.activeWorkspace.toplevels.values.length > 0 ? (monitor.activeWorkspace.toplevels.values.find(t => t.focused) || monitor.activeWorkspace.toplevels.values[0]).title : ""
                        color: Modules.Theme.base04
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        Layout.maximumWidth: 380
                    }
                }

                // Spacer to push rest to the right
                Item {
                    Layout.fillWidth: true
                }

                // System Stats Group (CPU, Mem, Temp)
                Pill {
                    id: systemStatsPill
                    visible: !root.isSecondary

                    // CPU Usage with mini progress
                    Row {
                        spacing: 4
                        Modules.MiniProgress {
                            value: cpuWidget.cpuUsage
                            progressColor: Modules.Theme.usageColor(cpuWidget.cpuUsage)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "\uf4bc  " + cpuWidget.cpuUsage + "%"
                            color: Modules.Theme.usageColor(cpuWidget.cpuUsage)
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
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
                            text: parent.showMB ? "\uefc5  " + memWidget.memUsed + "MB" : "\uefc5  " + memWidget.memUsage + "%"
                            color: Modules.Theme.usageColor(memWidget.memUsage)
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }

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
                            text: "\uef2a  " + tempWidget.tempCPU + "°"
                            color: Modules.Theme.tempColor(tempWidget.tempCPU)
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }
                }

                // Quick Controls & Status Pill
                Pill {
                    id: quickControlsPill
                    visible: !root.isSecondary

                    // Brightness
                    Item {
                        implicitWidth: brightnessText.implicitWidth
                        implicitHeight: brightnessText.implicitHeight

                        Text {
                            id: brightnessText
                            anchors.centerIn: parent
                            text: "\udb80\udce0  " + brightnessWidget.brightnessMain + "%"
                            color: brightnessMouse.containsMouse ? Modules.Theme.base0D : Modules.Theme.base04
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            scale: brightnessMouse.containsMouse ? 1.1 : 1.0
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        MouseArea {
                            id: brightnessMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0) {
                                    brightnessWidget.brightnessUp();
                                } else if (wheel.angleDelta.y < 0) {
                                    brightnessWidget.brightnessDown();
                                }
                            }
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
                            color: volumeMouse.containsMouse ? Modules.Theme.base0D : (volumeWidget.muted ? Modules.Theme.base08 : Modules.Theme.base04)
                            font {
                                family: Modules.Theme.fontFamily
                                pixelSize: Modules.Theme.fontSize
                                bold: true
                            }
                            scale: volumeMouse.containsMouse ? 1.1 : 1.0
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        MouseArea {
                            id: volumeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: volumeWidget.toggleMute()
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0) {
                                    volumeWidget.volumeUp();
                                } else if (wheel.angleDelta.y < 0) {
                                    volumeWidget.volumeDown();
                                }
                            }
                            onEntered: {
                                musicHideTimer.stop();
                                musicPopupWindow.visible = true;
                            }
                            onExited: musicHideTimer.restart()
                        }
                    }

                    // Weather Icon
                    Text {
                        id: weatherIcon
                        text: "\uf0c2"
                        color: weatherMouse.containsMouse ? Modules.Theme.base0D : Modules.Theme.base04
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                        scale: weatherMouse.containsMouse ? 1.15 : 1.0
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }

                        Rectangle {
                            id: weatherHoverBg
                            z: -1
                            anchors.centerIn: parent
                            width: Math.max(26, Math.max(parent.width, parent.height) + 8)
                            height: width
                            radius: width / 2
                            color: Modules.Theme.base0D
                            opacity: weatherMouse.containsMouse ? 0.20 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        MouseArea {
                            id: weatherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                weatherHideTimer.stop();
                                weatherPopupWindow.visible = true;
                            }
                            onExited: weatherHideTimer.restart()
                        }
                    }

                    // Battery Icon
                    Text {
                        id: batteryIcon
                        text: (batteryWidget.charging ? "\uf0e7" : (batteryWidget.percentage > 75 ? "\uf240" : (batteryWidget.percentage > 50 ? "\uf241" : (batteryWidget.percentage > 25 ? "\uf242" : (batteryWidget.percentage > 10 ? "\uf243" : "\uf244"))))) + "  " + batteryWidget.percentage + "%"
                        color: batteryMouse.containsMouse ? Modules.Theme.base0D : (batteryWidget.percentage <= 20 && !batteryWidget.charging ? Modules.Theme.base08 : Modules.Theme.base04)
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                        scale: batteryMouse.containsMouse ? 1.15 : 1.0
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }

                        MouseArea {
                            id: batteryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                batteryHideTimer.stop();
                                batteryPopupWindow.visible = true;
                            }
                            onExited: batteryHideTimer.restart()
                        }
                    }

                    // Bluetooth Icon
                    Text {
                        id: bluetoothIcon
                        text: "\uf293"
                        color: bluetoothMouse.containsMouse ? Modules.Theme.base0D : (bluetoothWidget.connected ? Modules.Theme.base0D : (bluetoothWidget.powered ? Modules.Theme.base04 : Modules.Theme.base03))
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                        scale: bluetoothMouse.containsMouse ? 1.15 : 1.0
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }

                        Rectangle {
                            id: bluetoothHoverBg
                            z: -1
                            anchors.centerIn: parent
                            width: Math.max(26, Math.max(parent.width, parent.height) + 8)
                            height: width
                            radius: width / 2
                            color: Modules.Theme.base0D
                            opacity: bluetoothMouse.containsMouse ? 0.20 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        MouseArea {
                            id: bluetoothMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                bluetoothHideTimer.stop();
                                bluetoothPopupWindow.visible = true;
                            }
                            onExited: bluetoothHideTimer.restart()
                        }
                    }

                    // Notification/DND Icon
                    Text {
                        id: notificationIcon
                        text: notificationServer.dndEnabled ? "\uf1f6" : "\uf0f3"
                        color: notificationMouse.containsMouse ? Modules.Theme.base0D : (notificationServer.dndEnabled ? Modules.Theme.base08 : (notificationServer.notificationHistory.length > 0 ? Modules.Theme.base0A : Modules.Theme.base04))
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                        scale: notificationMouse.containsMouse ? 1.15 : 1.0
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }

                        Rectangle {
                            id: notificationHoverBg
                            z: -1
                            anchors.centerIn: parent
                            width: Math.max(26, Math.max(parent.width, parent.height) + 8)
                            height: width
                            radius: width / 2
                            color: Modules.Theme.base0D
                            opacity: notificationMouse.containsMouse ? 0.20 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        MouseArea {
                            id: notificationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                notificationHideTimer.stop();
                                notificationPopupWindow.visible = true;
                            }
                            onExited: notificationHideTimer.restart()
                            onClicked: notificationServer.dndEnabled = !notificationServer.dndEnabled
                        }
                    }

                    // Wallpaper Icon
                    Text {
                        id: wallpaperIcon
                        text: "\uf03e"
                        color: wallpaperMouse.containsMouse ? Modules.Theme.base0D : Modules.Theme.base04
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                        scale: wallpaperMouse.containsMouse ? 1.15 : 1.0
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }

                        Rectangle {
                            id: wallpaperHoverBg
                            z: -1
                            anchors.centerIn: parent
                            width: Math.max(26, Math.max(parent.width, parent.height) + 8)
                            height: width
                            radius: width / 2
                            color: Modules.Theme.base0D
                            opacity: wallpaperMouse.containsMouse ? 0.20 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        MouseArea {
                            id: wallpaperMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                wallpaperHideTimer.stop();
                                wallpaperPopupWindow.visible = true;
                            }
                            onExited: wallpaperHideTimer.restart()
                            onClicked: wallpaperPopupWindow.visible = !wallpaperPopupWindow.visible
                        }
                    }

                    // Tray Icon
                    Text {
                        id: trayIcon
                        text: "\uf03a"
                        color: trayIconMouse.containsMouse ? Modules.Theme.base0D : Modules.Theme.base04
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                        scale: trayIconMouse.containsMouse ? 1.15 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                        MouseArea {
                            id: trayIconMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                trayHideTimer.stop();
                                trayPopupWindow.visible = true;
                            }
                            onExited: trayHideTimer.restart()
                        }
                    }

                    // Power Icon
                    Text {
                        id: powerIcon
                        text: "\uf011"
                        color: powerMouse.containsMouse ? Modules.Theme.base0D : Modules.Theme.base04
                        font {
                            family: Modules.Theme.fontFamily
                            pixelSize: Modules.Theme.fontSize
                            bold: true
                        }
                        scale: powerMouse.containsMouse ? 1.15 : 1.0
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }

                        Rectangle {
                            id: powerHoverBg
                            z: -1
                            anchors.centerIn: parent
                            width: Math.max(26, Math.max(parent.width, parent.height) + 8)
                            height: width
                            radius: width / 2
                            color: Modules.Theme.base0D
                            opacity: powerMouse.containsMouse ? 0.20 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                powerHideTimer.stop();
                                powerMenuWindow.visible = true;
                            }
                            onExited: powerHideTimer.restart()
                        }
                    }
                }

                // System Tray & Clock Pill
                Pill {
                    id: trayClockPill
                    visible: !root.isSecondary

                    // Clock
                    Item {
                        id: clockItem
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
                            onEntered: {
                                calendarHideTimer.stop();
                                calendarPopupWindow.visible = true;
                            }
                            onExited: calendarHideTimer.restart()
                        }
                    }
                }
            }
        }
    }
}
