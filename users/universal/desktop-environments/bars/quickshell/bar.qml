import Quickshell
import QtQuick

FloatingWindow {
  visible: true
  width: 200
  height: 100

  Text {
    anchors.centerIn: parent
    text: "Hello, Quickshell!"
    color: "#0db9d7"
    font.pixelSize: 18
  }
}
