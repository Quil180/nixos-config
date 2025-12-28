import QtQuick

// Mini circular progress indicator
Item {
    id: root
    
    property real value: 0          // 0-100
    property real size: 18
    property real strokeWidth: 3
    property color progressColor: Theme.successColor
    property color backgroundColor: Theme.base01
    
    implicitWidth: size
    implicitHeight: size
    
    // Background circle
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.backgroundColor;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(width/2, height/2, (width - root.strokeWidth)/2, 0, Math.PI * 2);
            ctx.stroke();
        }
    }
    
    // Progress arc
    Canvas {
        id: progressCanvas
        anchors.fill: parent
        
        property real animatedValue: 0
        
        Behavior on animatedValue {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }
        
        onAnimatedValueChanged: requestPaint()
        
        Component.onCompleted: animatedValue = root.value
        
        Connections {
            target: root
            function onValueChanged() {
                progressCanvas.animatedValue = root.value;
            }
        }
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.progressColor;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.beginPath();
            // Start from top (-90 degrees), go clockwise
            var startAngle = -Math.PI / 2;
            var endAngle = startAngle + (animatedValue / 100) * Math.PI * 2;
            ctx.arc(width/2, height/2, (width - root.strokeWidth)/2, startAngle, endAngle);
            ctx.stroke();
        }
    }
}
