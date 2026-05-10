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

    // Theme Configuration
    QtObject {
        id: theme
        
        property real bgLuminance: 0.0  
        property bool isDark: bgLuminance < 0.5

        Behavior on bgLuminance { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

        property color textColor:     isDark ? Qt.rgba(1, 1, 1, 1.0) : Qt.rgba(0, 0, 0, 0.95)
        property color textMuted:     isDark ? Qt.rgba(1, 1, 1, 0.80) : Qt.rgba(0, 0, 0, 0.75)
        property color textVeryMuted: isDark ? Qt.rgba(1, 1, 1, 0.50) : Qt.rgba(0, 0, 0, 0.50)
        property color textGlow:      isDark ? Qt.rgba(1, 1, 1, 0.7)  : Qt.rgba(0, 0, 0, 0.5)

        property color pillBg:        isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.06)
        property color pillBorder:    isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)
        
        property color dotActive:     isDark ? Qt.rgba(1, 1, 1, 0.90) : Qt.rgba(0, 0, 0, 0.85)
        property color dotOccupied:   isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.40)
        property color dotEmpty:      isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)
    }

    // State Variables
    property int uptimeSeconds: 0
    property var now: new Date()
    property bool isTakingScreenshot: false

    // Optimized Hyprland Lookups
    property var occupiedWorkspaceIds: {
        const wsValues = Hyprland.workspaces.values
        return wsValues.map(ws => ws.id)
    }

    property string activeTitle: {
        const activeToplevel = Hyprland.toplevels.values.find(w => w.activated)
        return activeToplevel ? activeToplevel.title : ""
    }

    // Timers
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            root.uptimeSeconds++
            root.now = new Date()
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (!root.isTakingScreenshot) {
                root.isTakingScreenshot = true
                screenshotProc.running = true
            }
        }
    }

    // Background Sampler Process
    Process {
        id: screenshotProc
        command:[
            "bash", "-c",
            "WAYLAND_DISPLAY=$WAYLAND_DISPLAY grim -g '0,0 40x40' /tmp/qs_bar_sample.png && " +
            "convert /tmp/qs_bar_sample.png -resize 1x1! -format '%[fx:0.2126*r+0.7152*g+0.0722*b]' info:"
        ]
        
        stdout: SplitParser {
            onRead: function(line) {
                const val = parseFloat(line.trim())
                if (!isNaN(val)) {
                    theme.bgLuminance = val
                }
            }
        }
        
        stderr: SplitParser {
            onRead: function(line) {
                console.warn("Screenshot Sampler Error:", line)
            }
        }

        onExited: root.isTakingScreenshot = false
    }

    // Helper Functions
    function formatUptime(seconds) {
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        const s = seconds % 60
        
        if (h > 0) return `${h}h ${String(m).padStart(2, "0")}m`
        return `${String(m).padStart(2, "0")}m ${String(s).padStart(2, "0")}s`
    }

    function truncate(str, max) {
        if (!str) return ""
        return str.length > max ? str.substring(0, max) + "…" : str
    }

    // Reusable UI Components
    component PillBackground: Rectangle {
        anchors.fill: parent
        radius: 999
        color: theme.pillBg
        border.color: theme.pillBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: 600 } }
    }

    component PillText: Text {
        font.pixelSize: 11
        font.letterSpacing: 0.4
        font.weight: Font.Medium
        Behavior on color { ColorAnimation { duration: 600 } }
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: theme.textGlow
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
    }

    // Main UI Components
    Item {
        id: container
        anchors.fill: parent
        opacity: 0
        transform: Translate { id: barSlide; y: -12 }
        
        Component.onCompleted: entranceAnim.start()

        ParallelAnimation {
            id: entranceAnim
            NumberAnimation { target: container; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
            NumberAnimation { target: barSlide;  property: "y";       from: -12; to: 0; duration: 400; easing.type: Easing.OutCubic }
        }

        // Left Module: Uptime
        Item {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: uptimeLabel.implicitWidth + 24
            height: 22

            PillBackground {}

            PillText {
                id: uptimeLabel
                anchors.centerIn: parent
                text: "⏱ " + root.formatUptime(root.uptimeSeconds)
                color: theme.textMuted
            }
        }

        // Center Module: Window Title & Workspaces
        Item {
            anchors.centerIn: parent
            width: centerCol.implicitWidth + 32
            height: centerCol.implicitHeight + 14

            PillBackground {
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.3)
                    shadowBlur: 0.8
                    shadowVerticalOffset: 4
                }
            }

            Column {
                id: centerCol
                anchors.centerIn: parent
                spacing: 4

                PillText {
                    id: titleText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.activeTitle !== "" ? root.truncate(root.activeTitle, 48) : "—"
                    color: root.activeTitle !== "" ? theme.textColor : theme.textVeryMuted

                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation { target: titleText; property: "opacity"; to: 0; duration: 80; easing.type: Easing.InCubic }
                            PropertyAction {}
                            NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Row {
                    id: dots
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Repeater {
                        model: 10
                        Rectangle {
                            readonly property int wsId: index + 1
                            readonly property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
                            readonly property bool isOccupied: root.occupiedWorkspaceIds.includes(wsId)
                            
                            width: isActive ? 16 : (isOccupied ? 5 : 4)
                            height: 4
                            radius: 999
                            color: isActive ? theme.dotActive : isOccupied ? theme.dotOccupied : theme.dotEmpty
                            
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                            Behavior on color { ColorAnimation { duration: 600 } }
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: isActive
                                shadowColor: theme.textGlow
                                shadowBlur: 1.0
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }
                        }
                    }
                }
            }
        }

        // Right Module: Date & Time
        Item {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: dateLabel.implicitWidth + clockLabel.implicitWidth + 40
            height: 22

            // Date Pill
            Item {
                anchors.right: clockPill.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: dateLabel.implicitWidth + 24

                PillBackground {}

                PillText {
                    id: dateLabel
                    anchors.centerIn: parent
                    text: root.now.toLocaleDateString(Qt.locale(), "ddd d MMM")
                    color: theme.textMuted
                }
            }

            // Clock Pill
            Item {
                id: clockPill
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: clockLabel.implicitWidth + 24

                PillBackground {}

                PillText {
                    id: clockLabel
                    anchors.centerIn: parent
                    text: Qt.formatTime(root.now, "h:mm AP")
                    color: theme.textColor
                }
            }
        }
    }
}
