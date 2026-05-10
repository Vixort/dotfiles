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
    exclusiveZone: 30
    margins { top: 6; left: 0; right: 0 }

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

        property color pillBg:        isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
        property color pillBorder:    isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)
        property color pillGloss:     isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.30)
        
        property color dotActive:     isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(0, 0, 0, 0.85)
        property color dotOccupied:   isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.35)
        property color dotEmpty:      isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10)
    }

    // State Variables
    property int uptimeSeconds: 0
    property var now: new Date()
    property bool isTakingScreenshot: false

    // State Lookups
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

    // Background Sampler
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
                if (!isNaN(val)) theme.bgLuminance = val
            }
        }
        onExited: root.isTakingScreenshot = false
    }

    // Format Utilities
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

    // UI Components
    component InteractiveWidget: Item {
        id: widgetRoot
        default property alias content: container.data
        property bool showShadow: false

        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        Rectangle {
            anchors.fill: parent
            radius: 999
            color: theme.pillBg
            border.color: theme.pillBorder
            border.width: 1
            Behavior on color { ColorAnimation { duration: 600 } }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: theme.pillGloss }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            layer.enabled: widgetRoot.showShadow
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 1.2
                shadowVerticalOffset: 4
            }
        }

        Item {
            id: container
            anchors.fill: parent
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: widgetRoot.scale = 1.05
            onExited: widgetRoot.scale = 1.0
            onPressed: widgetRoot.scale = 0.94
            onReleased: widgetRoot.scale = containsMouse ? 1.05 : 1.0
        }
    }

    component PillText: Text {
        font.pixelSize: 11
        font.letterSpacing: 0.4
        font.weight: Font.DemiBold
        Behavior on color { ColorAnimation { duration: 600 } }
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: theme.textGlow
            shadowBlur: 1.2
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
    }

    // Main Layout
    Item {
        id: mainLayout
        anchors.fill: parent
        opacity: 0
        transform: Translate { id: barSlide; y: -20 }
        
        Component.onCompleted: entranceAnim.start()

        ParallelAnimation {
            id: entranceAnim
            NumberAnimation { target: mainLayout; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { target: barSlide;  property: "y";       from: -20; to: 0; duration: 500; easing.type: Easing.OutBack }
        }

        // Left Module: Uptime
        InteractiveWidget {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: uptimeLabel.implicitWidth + 28
            height: 26

            PillText {
                id: uptimeLabel
                anchors.centerIn: parent
                text: root.formatUptime(root.uptimeSeconds)
                color: theme.textMuted
            }
        }

        // Center Module: Workspaces & Title
        InteractiveWidget {
            anchors.centerIn: parent
            width: centerRow.implicitWidth + 32
            height: 26
            showShadow: true

            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: 12

                Row {
                    id: dots
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: 10
                        Rectangle {
                            readonly property int wsId: index + 1
                            readonly property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
                            readonly property bool isOccupied: root.occupiedWorkspaceIds.includes(wsId)
                            
                            width: isActive ? 18 : (isOccupied ? 6 : 4)
                            height: 4
                            radius: 999
                            color: isActive ? theme.dotActive : isOccupied ? theme.dotOccupied : theme.dotEmpty
                            
                            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 600 } }
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: isActive
                                shadowColor: theme.textGlow
                                shadowBlur: 1.5
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 0
                            }
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 12
                    color: theme.pillBorder
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.activeTitle !== ""
                }

                PillText {
                    id: titleText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.activeTitle !== "" ? root.truncate(root.activeTitle, 35) : "Desktop"
                    color: root.activeTitle !== "" ? theme.textColor : theme.textVeryMuted

                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation { target: titleText; property: "opacity"; to: 0; duration: 100; easing.type: Easing.OutExpo }
                            PropertyAction {}
                            NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: 250; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }

        // Right Module: Date & Time
        Item {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: dateWidget.width + clockWidget.width + 8
            height: 26

            InteractiveWidget {
                id: dateWidget
                anchors.right: clockWidget.left
                anchors.rightMargin: 8
                height: parent.height
                width: dateLabel.implicitWidth + 24

                PillText {
                    id: dateLabel
                    anchors.centerIn: parent
                    text: root.now.toLocaleDateString(Qt.locale(), "ddd d MMM")
                    color: theme.textMuted
                }
            }

            InteractiveWidget {
                id: clockWidget
                anchors.right: parent.right
                height: parent.height
                width: clockLabel.implicitWidth + 24

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
