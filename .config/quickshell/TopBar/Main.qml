import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
  id: root
  color: "transparent"

  anchors { top: true; left: true; right: true }
  implicitHeight: 40
  exclusiveZone: 20
  margins { top: 2; left: 0; right: 0 }

  // Color Variables
  property real bgLuminance: 0.0  
  property bool isDark: bgLuminance < 0.5

  property color textColor:     isDark ? Qt.rgba(1,1,1,1.0) : Qt.rgba(0,0,0,0.95)
  property color textMuted:     isDark ? Qt.rgba(1,1,1,0.80) : Qt.rgba(0,0,0,0.75)
  property color textVeryMuted: isDark ? Qt.rgba(1,1,1,0.50) : Qt.rgba(0,0,0,0.50)
  property color textGlow:      isDark ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0, 0, 0, 0.5)

  property color pillBg:        isDark ? Qt.rgba(1,1,1,0.06) : Qt.rgba(0,0,0,0.06)
  property color pillBorder:    isDark ? Qt.rgba(1,1,1,0.10) : Qt.rgba(0,0,0,0.10)
  property color dotActive:     isDark ? Qt.rgba(1,1,1,0.90) : Qt.rgba(0,0,0,0.85)
  property color dotOccupied:   isDark ? Qt.rgba(1,1,1,0.45) : Qt.rgba(0,0,0,0.40)
  property color dotEmpty:      isDark ? Qt.rgba(1,1,1,0.15) : Qt.rgba(0,0,0,0.12)

  Behavior on bgLuminance { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

  // Background Sampler
  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: screenshotProc.running = true
  }

  Process {
    id: screenshotProc
    command:[
      "bash", "-c",
      "WAYLAND_DISPLAY=$WAYLAND_DISPLAY grim -g '0,0 40x40' /tmp/qs_bar_sample.png && " +
      "convert /tmp/qs_bar_sample.png -resize 1x1! -format '%[fx:0.2126*r+0.7152*g+0.0722*b]' info:"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        var val = parseFloat(line.trim())
        if (!isNaN(val)) {
          root.bgLuminance = val
          console.log("luminance:", val, "isDark:", root.isDark)
        }
      }
    }
    stderr: SplitParser {
      onRead: function(line) {
        console.log("ERR:", line)
      }
    }
  }

  // State Variables
  property int uptimeSeconds: 0
  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: root.uptimeSeconds++
  }

  property var now: new Date()
  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: root.now = new Date()
  }

  property string activeTitle: {
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      if (toplevels[i].activated) return toplevels[i].title
    }
    return ""
  }

  // Helper Functions
  function formatUptime(s) {
    var h = Math.floor(s / 3600)
    var m = Math.floor((s % 3600) / 60)
    var sec = s % 60
    if (h > 0) return h + "h " + String(m).padStart(2,"0") + "m"
    return String(m).padStart(2,"0") + "m " + String(sec).padStart(2,"0") + "s"
  }

  function formatTime(d) {
    var h = d.getHours()
    var m = d.getMinutes()
    var ampm = h >= 12 ? "PM" : "AM"
    h = h % 12; if (h === 0) h = 12
    return h + ":" + String(m).padStart(2,"0") + " " + ampm
  }

  function truncate(str, max) {
    if (!str) return ""
    return str.length > max ? str.substring(0, max) + "…" : str
  }

  // Main UI Components
  Item {
    id: container
    anchors.fill: parent
    opacity: 0
    transform: Translate { id: barSlide; y: -12 }
    Component.onCompleted: entranceAnim.start()

    // Entrance Animation
    ParallelAnimation {
      id: entranceAnim
      NumberAnimation { target: container; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
      NumberAnimation { target: barSlide;  property: "y";       from: -12; to: 0; duration: 400; easing.type: Easing.OutCubic }
    }

    // Uptime Widget
    Item {
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      width: uptimeLabel.implicitWidth + 24
      height: 22

      Rectangle {
        anchors.fill: parent; radius: 999
        color: root.pillBg
        border.color: root.pillBorder; border.width: 1
        Behavior on color { ColorAnimation { duration: 600 } }
      }
      Text {
        id: uptimeLabel
        anchors.centerIn: parent
        text: "⏱ " + root.formatUptime(root.uptimeSeconds)
        color: root.textMuted
        font.pixelSize: 11; font.letterSpacing: 0.4; font.weight: Font.Medium
        Behavior on color { ColorAnimation { duration: 600 } }
        
        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowColor: root.textGlow
          shadowBlur: 1.0
          shadowHorizontalOffset: 0
          shadowVerticalOffset: 0
        }
      }
    }

    // Center Widget
    Item {
      anchors.centerIn: parent
      width: centerCol.implicitWidth + 32
      height: centerCol.implicitHeight + 14

      Rectangle {
        anchors.fill: parent; radius: 999
        color: root.pillBg
        border.color: root.pillBorder; border.width: 1
        Behavior on color { ColorAnimation { duration: 600 } }
        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowColor: Qt.rgba(0,0,0,0.3)
          shadowBlur: 0.8; shadowVerticalOffset: 4
        }
      }

      Column {
        id: centerCol
        anchors.centerIn: parent
        spacing: 4

        Text {
          id: titleText
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.activeTitle !== "" ? root.truncate(root.activeTitle, 48) : "—"
          color: root.activeTitle !== "" ? root.textColor : root.textVeryMuted
          font.pixelSize: 11; font.letterSpacing: 0.3; font.weight: Font.Medium
          Behavior on color { ColorAnimation { duration: 600 } }

          layer.enabled: true
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.textGlow
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
          }

          Behavior on text {
            SequentialAnimation {
              NumberAnimation { target: titleText; property: "opacity"; to: 0; duration: 80; easing.type: Easing.InCubic }
              PropertyAction { }
              NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            }
          }
        }

        // Workspaces Indicator
        Row {
          id: dots
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 6

          Repeater {
            model: 10
            Rectangle {
              readonly property int wsId: index + 1
              readonly property bool active: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
              readonly property bool occupied: {
                for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                  if (Hyprland.workspaces.values[i].id === wsId) return true
                }
                return false
              }
              width: active ? 16 : (occupied ? 5 : 4)
              height: 4; radius: 999
              color: active ? root.dotActive : occupied ? root.dotOccupied : root.dotEmpty
              Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
              Behavior on color { ColorAnimation { duration: 600 } }
              
              layer.enabled: true
              layer.effect: MultiEffect {
                shadowEnabled: active
                shadowColor: root.textGlow
                shadowBlur: 1.0
                shadowHorizontalOffset: 0; shadowVerticalOffset: 0
              }
            }
          }
        }
      }
    }

    // Date Widget
    Item {
      anchors.right: clockPill.left
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      width: dateLabel.implicitWidth + 24
      height: 22

      Rectangle {
        anchors.fill: parent; radius: 999
        color: root.pillBg
        border.color: root.pillBorder; border.width: 1
        Behavior on color { ColorAnimation { duration: 600 } }
      }

      Text {
        id: dateLabel
        anchors.centerIn: parent
        text: root.now.toLocaleDateString(Qt.locale(), "ddd d MMM")
        color: root.textMuted
        font.pixelSize: 11; font.letterSpacing: 0.4; font.weight: Font.Medium
        Behavior on color { ColorAnimation { duration: 600 } }
        
        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowColor: root.textGlow
          shadowBlur: 1.0
          shadowHorizontalOffset: 0
          shadowVerticalOffset: 0
        }
      }
    }

    // Clock Widget
    Item {
      id: clockPill
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      width: clockLabel.implicitWidth + 24
      height: 22

      Rectangle {
        anchors.fill: parent; radius: 999
        color: root.pillBg
        border.color: root.pillBorder; border.width: 1
        Behavior on color { ColorAnimation { duration: 600 } }
      }

      Text {
        id: clockLabel
        anchors.centerIn: parent
        text: root.formatTime(root.now)
        color: root.textColor
        font.pixelSize: 11; font.letterSpacing: 0.4; font.weight: Font.Medium
        Behavior on color { ColorAnimation { duration: 600 } }
        
        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowColor: root.textGlow
          shadowBlur: 1.0
          shadowHorizontalOffset: 0
          shadowVerticalOffset: 0
        }
      }
    }
  }
}
