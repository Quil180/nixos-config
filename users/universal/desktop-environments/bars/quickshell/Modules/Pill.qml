import QtQuick
import QtQuick.Layouts

Item {
    id: pillRoot
    default property alias content: inner.data
    implicitHeight: 30
    implicitWidth: inner.implicitWidth + 24
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(Theme.base00.r, Theme.base00.g, Theme.base00.b, 0.85)
        border.color: Qt.rgba(Theme.base02.r, Theme.base02.g, Theme.base02.b, 0.7)
        border.width: 1

        RowLayout {
            id: inner
            anchors.centerIn: parent
            spacing: 10
        }
    }
}

