import QtQuick

Text {
    id: root

    property string format: "ddd, MMM dd - h:mm:ss AP"
    property int refreshInterval: 1000

    text: Qt.formatDateTime(new Date(), format)
    color: Theme.base03

    font {
        family: Theme.fontFamily
        pixelSize: Theme.fontSize
        bold: true
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: root.text = Qt.formatDateTime(new Date(), root.format)
    }
}
