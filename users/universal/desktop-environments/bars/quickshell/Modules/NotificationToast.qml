import Quickshell
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: toast
    
    required property var notification
    
    signal dismissed()
    
    implicitWidth: 350
    implicitHeight: contentColumn.height + 24
    color: Qt.rgba(Theme.base01.r, Theme.base01.g, Theme.base01.b, 0.80)
    radius: 8
    border.color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.5)
    border.width: 1
    
    // Slide in animation
    x: parent ? parent.width - width - 20 : 0
    
    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }
    
    // Auto-dismiss timer
    Timer {
        id: dismissTimer
        interval: notification ? (notification.expireTimeout > 0 ? notification.expireTimeout : 5000) : 5000
        running: true
        onTriggered: toast.dismissed()
    }
    
    HoverHandler {
        id: toastHover
        onHoveredChanged: {
            if (hovered) {
                dismissTimer.stop();
            } else {
                dismissTimer.restart();
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (notification) {
                notification.dismiss();
            }
            toast.dismissed();
        }
    }
    
    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 6
        
        // Header with app name and close button
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: notification ? notification.appName : ""
                color: Theme.base03
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 3
                }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            Text {
                text: "\uf00d"
                color: closeMouse.containsMouse ? Theme.base0D : Theme.base02
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSize - 2
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (notification) {
                            notification.dismiss();
                        }
                        toast.dismissed();
                    }
                }
            }
        }
        
        // Summary (title)
        Text {
            text: notification ? notification.summary : ""
            color: Theme.base04
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize
                bold: true
            }
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        
        // Body
        Text {
            visible: notification && notification.body !== ""
            text: notification ? notification.body : ""
            color: Theme.base03
            font {
                family: Theme.fontFamily
                pixelSize: Theme.fontSize - 1
            }
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        
        // Actions (if any)
        RowLayout {
            visible: notification && notification.actions && notification.actions.length > 0
            Layout.fillWidth: true
            spacing: 8
            
            Repeater {
                model: notification ? notification.actions : []
                
                Rectangle {
                    color: actionMouse.containsMouse ? Qt.rgba(Theme.base0D.r, Theme.base0D.g, Theme.base0D.b, 0.25) : Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.4)
                    radius: 4
                    implicitWidth: actionText.width + 16
                    implicitHeight: actionText.height + 8
                    
                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text || ""
                        color: actionMouse.containsMouse ? Theme.base0D : Theme.base04
                        font {
                            family: Theme.fontFamily
                            pixelSize: Theme.fontSize - 2
                        }
                    }
                    
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.invoke) {
                                modelData.invoke();
                            }
                            toast.dismissed();
                        }
                    }
                }
            }
        }
    }
}
