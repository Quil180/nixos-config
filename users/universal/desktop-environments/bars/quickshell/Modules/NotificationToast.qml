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
    color: Theme.base00
    radius: 8
    border.color: Theme.base01
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
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: dismissTimer.stop()
        onExited: dismissTimer.restart()
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
                color: closeMouse.containsMouse ? Theme.alertColor : Theme.base02
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
                    color: actionMouse.containsMouse ? Theme.base02 : Theme.base01
                    radius: 4
                    implicitWidth: actionText.width + 16
                    implicitHeight: actionText.height + 8
                    
                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text || ""
                        color: Theme.base04
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
