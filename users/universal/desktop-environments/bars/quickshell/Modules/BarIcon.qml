import QtQuick

Text {
    id: icon
    
    property bool active: false
    property bool hovered: false
    property color activeColor: Theme.base0D
    property color normalColor: Theme.base03
    property color hoveredColor: Theme.base0D
    
    color: active ? activeColor : (hovered ? hoveredColor : normalColor)
    
    font {
        family: Theme.fontFamily
        pixelSize: Theme.fontSize
        bold: true
    }
    
    // Smooth color transition
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    // Scale on hover
    scale: hovered ? 1.1 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
    }
    
    // Circular hover background
    Rectangle {
        id: hoverBg
        z: -1
        anchors.centerIn: parent
        width: Math.max(26, Math.max(parent.width, parent.height) + 8)
        height: width
        radius: width / 2
        color: Theme.base0D
        opacity: icon.hovered ? 0.20 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }
    
    // Glow effect for active state
    layer.enabled: active
    layer.effect: Item {
        property var source
        Rectangle {
            anchors.centerIn: parent
            width: icon.width + 8
            height: icon.height + 8
            radius: (icon.width + 8) / 2
            color: "transparent"
            border.color: Qt.rgba(
                icon.activeColor.r,
                icon.activeColor.g,
                icon.activeColor.b,
                0.3
            )
            border.width: 1
        }
    }
}
