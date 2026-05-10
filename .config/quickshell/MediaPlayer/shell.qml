import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

Scope {
  id: root

  // IPC Setup
  IpcHandler {
    target: "music"
    function toggle(): void {
      musicWindow.toggle()
    }
  }

  // Main UI Components
  PanelWindow {
    id: musicWindow
    visible: false
    
    implicitWidth: 320
    implicitHeight: 620
    color: "transparent"

    anchors { right: true; bottom: true }
    margins { right: 30; bottom: 80 }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "musicwidget"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Player State
    property var player: {
      for (var i = 0; i < Mpris.players.values.length; i++) {
        var p = Mpris.players.values[i]
        if (p.identity.toLowerCase().includes("spotify")) return p
      }
      return Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    }

    property bool shown: false
    function toggle() {
      shown = !shown
      if (shown) visible = true
    }

    onShownChanged: {
      if (shown) {
          showAnim.start()
          mainCard.forceActiveFocus()
      }
      else {
          hideAnim.start()
      }
    }

    // Animations
    ParallelAnimation { 
        id: showAnim
        NumberAnimation { target: mainCard; property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: mainCard; property: "y"; from: 60; to: 0; duration: 500; easing.type: Easing.OutBack }
    }
    
    ParallelAnimation { 
        id: hideAnim
        NumberAnimation { target: mainCard; property: "opacity"; from: 1; to: 0; duration: 300 }
        NumberAnimation { target: mainCard; property: "y"; from: 0; to: 60; duration: 300; easing.type: Easing.InCubic }
        onFinished: musicWindow.visible = false 
    }

    // Theme Config
    property color themeFg: "#FFFFFF"
    property color themeBg: "#080808"
    property color themeDim: "#777777"
    
    property int focusedIndex: 1

    // Helper Functions
    function formatTime(val) {
        if (!val || isNaN(val)) return "00:00"
        
        var sec = val;
        if (val > 10000000) {
            sec = val / 1000000;
        } else if (val > 10000) {
            sec = val / 1000;
        }
        
        var m = Math.floor(sec / 60);
        var s = Math.floor(sec % 60);
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    function randomHex() {
        return "0x" + Math.floor(Math.random() * 65535).toString(16).toUpperCase().padStart(4, '0')
    }

    // Connections
    Connections {
        target: musicWindow.player
        ignoreUnknownSignals: true
        
        function onTrackTitleChanged() {
            var title = musicWindow.player.trackTitle || "Unknown"
            if (title.length > 18) title = title.substring(0, 18) + "..."
            logModel.pushLog("[" + musicWindow.randomHex() + "] LOAD: " + title)
        }
        
        function onPlaybackStateChanged() {
            var st = musicWindow.player.playbackState
            var statusStr = (st === MprisPlaybackState.Playing) ? "RESUMED" : "PAUSED"
            logModel.pushLog("[" + musicWindow.randomHex() + "] AUDIO: " + statusStr)
        }
    }

    Item {
      id: mainCard
      anchors.fill: parent
      opacity: 0
      y: 60
      focus: true

      // Keyboard Controls
      Keys.onPressed: (event) => {
          if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
              musicWindow.focusedIndex = Math.max(0, musicWindow.focusedIndex - 1)
              event.accepted = true
          } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
              musicWindow.focusedIndex = Math.min(2, musicWindow.focusedIndex + 1)
              event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              pressAnim.start()
              if (musicWindow.player) {
                  if (musicWindow.focusedIndex === 0) musicWindow.player.previous()
                  else if (musicWindow.focusedIndex === 1) musicWindow.player.togglePlaying()
                  else if (musicWindow.focusedIndex === 2) musicWindow.player.next()
              }
              event.accepted = true
          }
      }

      // Background Glassmorphism
      Rectangle {
          id: bg
          anchors.fill: parent
          
          gradient: Gradient {
              GradientStop { position: 0.0; color: Qt.rgba(0.2, 0.2, 0.2, 0.35) } 
              GradientStop { position: 0.5; color: Qt.rgba(0.08, 0.08, 0.08, 0.45) } 
              GradientStop { position: 1.0; color: Qt.rgba(0.0, 0.0, 0.0, 0.65) } 
          }
          
          border.color: Qt.rgba(1.0, 1.0, 1.0, 0.25)
          border.width: 1.5
          clip: true

          // Shadow Effect
          layer.enabled: true
          layer.effect: MultiEffect {
              shadowEnabled: true
              shadowColor: "black"
              shadowBlur: 1.0
              shadowOpacity: 0.8
              shadowVerticalOffset: 4
          }

          // Inner Highlight
          Rectangle {
              anchors.fill: parent
              anchors.margins: 1.5
              color: "transparent"
              border.color: Qt.rgba(1.0, 1.0, 1.0, 0.06)
              border.width: 1
          }

          // Scanlines
          Column {
              anchors.fill: parent
              spacing: 3
              Repeater {
                  model: 200
                  Rectangle { width: parent.width; height: 1; color: Qt.rgba(1.0, 1.0, 1.0, 0.02) }
              }
          }
      }

      // Content Container
      Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Terminal Header
        Row {
            spacing: 8
            Text {
                text: "root@arch:~# ./music --mono --debug"
                color: musicWindow.themeFg
                font.family: "monospace"
                font.pixelSize: 11
                font.bold: true
            }
            Rectangle {
                width: 8; height: 14
                color: musicWindow.themeFg
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0; duration: 400 }
                    NumberAnimation { to: 1; duration: 400 }
                }
            }
        }

        Text {
            text: "================================="
            color: Qt.rgba(1.0, 1.0, 1.0, 0.4)
            font.family: "monospace"
            font.pixelSize: 12
            width: parent.width
            clip: true
        }

        // Album Art
        Item {
            id: artBox
            width: 160 
            height: 160
            anchors.horizontalCenter: parent.horizontalCenter
            
            transform: Translate { id: glitchTranslate; x: 0; y: 0 }

            Timer {
                running: musicWindow.visible && (musicWindow.player && musicWindow.player.playbackState === MprisPlaybackState.Playing)
                repeat: true
                interval: Math.random() * 4000 + 3000
                onTriggered: {
                    glitchAnim.start()
                    interval = Math.random() * 4000 + 3000
                }
            }

            SequentialAnimation {
                id: glitchAnim
                PropertyAction { target: artFrame; property: "border.color"; value: "#FF0000" }
                NumberAnimation { target: glitchTranslate; property: "x"; to: 6; duration: 25 }
                NumberAnimation { target: glitchTranslate; property: "x"; to: -5; duration: 25 }
                PropertyAction { target: artFrame; property: "border.color"; value: "#00FFFF" }
                NumberAnimation { target: glitchTranslate; property: "x"; to: 4; duration: 25 }
                NumberAnimation { target: glitchTranslate; property: "x"; to: 0; duration: 25 }
                PropertyAction { target: artFrame; property: "border.color"; value: Qt.rgba(1.0, 1.0, 1.0, 0.4) }
            }

            Rectangle {
                id: artFrame
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.4)
                border.width: 1

                Text { text: "+"; color: musicWindow.themeFg; font.family: "monospace"; anchors.top: parent.top; anchors.left: parent.left; anchors.margins: -4 }
                Text { text: "+"; color: musicWindow.themeFg; font.family: "monospace"; anchors.top: parent.top; anchors.right: parent.right; anchors.margins: -4 }
                Text { text: "+"; color: musicWindow.themeFg; font.family: "monospace"; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: -4 }
                Text { text: "+"; color: musicWindow.themeFg; font.family: "monospace"; anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: -4 }
            }

            Item {
                anchors.fill: parent
                anchors.margins: 6
                
                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: musicWindow.player ? (musicWindow.player.metadata["mpris:artUrl"] ?? "") : ""
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: MultiEffect { saturation: -1.0 }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.08, 0.08, 0.08, 0.8)
                    visible: albumArt.status !== Image.Ready
                    Text {
                        anchors.centerIn: parent
                        text: "[ NO_MEDIA ]"
                        color: musicWindow.themeFg
                        font.family: "monospace"
                    }
                }
            }
        }

        // Track Information
        Column {
            width: parent.width
            spacing: 8
            
            property string rawTitle: musicWindow.player ? (musicWindow.player.trackTitle || "N/A") : "N/A"
            property string rawArtist: musicWindow.player ? (musicWindow.player.trackArtists || "N/A") : "N/A"
            property string typedTitle: ""
            property string typedArtist: ""
            property int typeIdx: 0

            onRawTitleChanged: {
                typedTitle = ""
                typedArtist = ""
                typeIdx = 0
                typewriterTimer.start()
            }

            Timer {
                id: typewriterTimer
                interval: 25
                repeat: true
                running: true
                onTriggered: {
                    var isDone = true
                    if (parent.typeIdx < parent.rawTitle.length) {
                        parent.typedTitle += parent.rawTitle[parent.typeIdx]
                        isDone = false
                    }
                    if (parent.typeIdx < parent.rawArtist.length) {
                        parent.typedArtist += parent.rawArtist[parent.typeIdx]
                        isDone = false
                    }
                    parent.typeIdx++
                    if (isDone) stop()
                }
            }
            
            Text {
                width: parent.width
                text: "> TITLE : " + parent.typedTitle + (typewriterTimer.running ? "█" : "")
                color: musicWindow.themeFg
                font.pixelSize: 14
                font.family: "monospace"
                font.bold: true
                elide: Text.ElideRight
            }
            
            Text {
                width: parent.width
                text: "> ARTIST: " + parent.typedArtist
                color: musicWindow.themeDim
                font.pixelSize: 13
                font.family: "monospace"
                elide: Text.ElideRight
            }
            
            Row {
                spacing: 8
                Text {
                    text: "> STATUS: " + (musicWindow.player && musicWindow.player.playbackState === MprisPlaybackState.Playing ? "[ PLAYING ]" : "[ STOPPED ]")
                    color: musicWindow.themeDim
                    font.pixelSize: 12
                    font.family: "monospace"
                }
                
                Text {
                    property var chars:["|", "/", "-", "\\"]
                    property int spinIdx: 0
                    text: musicWindow.player && musicWindow.player.playbackState === MprisPlaybackState.Playing ? chars[spinIdx] : "*"
                    color: musicWindow.themeFg
                    font.pixelSize: 12
                    font.family: "monospace"
                    font.bold: true
                    
                    Timer {
                        running: musicWindow.player && musicWindow.player.playbackState === MprisPlaybackState.Playing
                        interval: 120
                        repeat: true
                        onTriggered: parent.spinIdx = (parent.spinIdx + 1) % parent.chars.length
                    }
                }
            }
            
            // Progress Bar
            Text {
                id: progressBarText
                width: parent.width
                color: musicWindow.themeFg
                font.family: "monospace"
                font.pixelSize: 11
                
                property real currentPos: 0
                property real currentLen: 0
                
                Timer {
                    running: musicWindow.visible && musicWindow.player != null && musicWindow.player.playbackState === MprisPlaybackState.Playing
                    interval: 500
                    repeat: true
                    onTriggered: {
                        if (musicWindow.player) {
                            progressBarText.currentPos = musicWindow.player.position || 0
                            progressBarText.currentLen = musicWindow.player.length || (musicWindow.player.metadata ? (musicWindow.player.metadata["mpris:length"] || 0) : 0)
                        }
                    }
                }

                Connections {
                    target: musicWindow.player
                    ignoreUnknownSignals: true
                    function onPlaybackStateChanged() {
                        if (musicWindow.player) {
                            progressBarText.currentPos = musicWindow.player.position || 0
                            progressBarText.currentLen = musicWindow.player.length || (musicWindow.player.metadata ? (musicWindow.player.metadata["mpris:length"] || 0) : 0)
                        }
                    }
                    function onMetadataChanged() {
                        if (musicWindow.player) {
                            progressBarText.currentLen = musicWindow.player.length || (musicWindow.player.metadata ? (musicWindow.player.metadata["mpris:length"] || 0) : 0)
                        }
                    }
                }
                
                property real progressRaw: (currentLen > 0) ? (currentPos / currentLen) : 0
                property real progress: Math.max(0, Math.min(1, progressRaw))
                
                text: {
                    var barLength = 16
                    var filledLength = Math.floor(progress * barLength)
                    var emptyLength = barLength - filledLength
                    
                    var bar = "["
                    for (var i = 0; i < filledLength; i++) bar += "="
                    if (filledLength < barLength) { bar += ">"; emptyLength-- }
                    for (var j = 0; j < emptyLength; j++) bar += "."
                    bar += "]"
                    
                    var posStr = musicWindow.formatTime(currentPos)
                    var lenStr = musicWindow.formatTime(currentLen)
                    
                    return bar + " " + posStr + " / " + lenStr
                }
            }
        }

        // Radar Visualizer
        Row {
            spacing: 5
            height: 25
            anchors.horizontalCenter: parent.horizontalCenter
            
            Repeater {
                model: 29
                Rectangle {
                    id: volBar
                    width: 4
                    color: musicWindow.themeFg
                    anchors.bottom: parent.bottom
                    
                    property int centerDist: Math.abs(14 - index)
                    property int maxHeight: Math.max(5, 25 - (centerDist * 1.5))
                    
                    property real targetHeight: 4
                    height: targetHeight
                    
                    Behavior on height {
                        NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                    }
                    
                    Timer {
                        running: musicWindow.player && musicWindow.player.playbackState === MprisPlaybackState.Playing
                        interval: 100 + Math.random() * 150
                        repeat: true
                        onTriggered: {
                            if (volBar.targetHeight <= 5) {
                                volBar.targetHeight = 4 + Math.random() * volBar.maxHeight
                            } else {
                                volBar.targetHeight = 4 + Math.random() * (volBar.maxHeight * 0.4)
                            }
                        }
                        onRunningChanged: {
                            if (!running) volBar.targetHeight = 4
                        }
                    }
                }
            }
        }

        Text {
            text: "---------------------------------"
            color: Qt.rgba(1.0, 1.0, 1.0, 0.4)
            font.family: "monospace"
            font.pixelSize: 12
            width: parent.width
            clip: true
        }

        // Terminal Logs
        Rectangle {
            width: parent.width
            height: 50
            color: "transparent"
            
            ListModel {
                id: logModel
                ListElement { msg: "> SYSTEM INITIALIZED." }
                
                function pushLog(text) {
                    if (count >= 3) remove(0, 1)
                    append({ msg: "> " + text })
                }
            }
            
            ListView {
                anchors.fill: parent
                model: logModel
                interactive: false
                spacing: 4
                delegate: Text {
                    text: model.msg
                    color: musicWindow.themeDim
                    font.family: "monospace"
                    font.pixelSize: 10
                    width: parent.width
                    elide: Text.ElideRight
                }
                
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                    NumberAnimation { property: "x"; from: -10; to: 0; duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }

        // Navigation Controls
        Item {
            width: controlsRow.implicitWidth 
            height: 32
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                id: selector
                height: parent.height
                x: controlsRow.children[musicWindow.focusedIndex].x
                width: controlsRow.children[musicWindow.focusedIndex].width
                color: musicWindow.themeFg

                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

                SequentialAnimation on scale {
                    id: pressAnim
                    running: false
                    NumberAnimation { to: 0.85; duration: 70; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 1.0; duration: 150; easing.type: Easing.OutBack }
                }
            }

            Row {
                id: controlsRow
                spacing: 12
                
                Item {
                    width: 70; height: 32
                    Rectangle { anchors.fill: parent; color: "transparent"; border.color: musicWindow.themeFg; border.width: musicWindow.focusedIndex === 0 ? 0 : 1; Behavior on border.width { NumberAnimation { duration: 150 } } }
                    Text { anchors.centerIn: parent; text: "[ PREV ]"; font.family: "monospace"; font.pixelSize: 13; font.bold: true; color: musicWindow.focusedIndex === 0 ? musicWindow.themeBg : musicWindow.themeDim; Behavior on color { ColorAnimation { duration: 150 } } }
                    MouseArea { anchors.fill: parent; onClicked: { musicWindow.focusedIndex = 0; musicWindow.player && musicWindow.player.previous() } }
                }

                Item {
                    width: 90; height: 32
                    Rectangle { anchors.fill: parent; color: "transparent"; border.color: musicWindow.themeFg; border.width: musicWindow.focusedIndex === 1 ? 0 : 1; Behavior on border.width { NumberAnimation { duration: 150 } } }
                    Text { anchors.centerIn: parent; font.family: "monospace"; font.pixelSize: 14; font.bold: true; text: musicWindow.player && musicWindow.player.playbackState === MprisPlaybackState.Playing ? "[ PAUSE ]" : "[ PLAY ]"; color: musicWindow.focusedIndex === 1 ? musicWindow.themeBg : musicWindow.themeFg; Behavior on color { ColorAnimation { duration: 150 } } }
                    MouseArea { anchors.fill: parent; onClicked: { musicWindow.focusedIndex = 1; musicWindow.player && musicWindow.player.togglePlaying() } }
                }

                Item {
                    width: 70; height: 32
                    Rectangle { anchors.fill: parent; color: "transparent"; border.color: musicWindow.themeFg; border.width: musicWindow.focusedIndex === 2 ? 0 : 1; Behavior on border.width { NumberAnimation { duration: 150 } } }
                    Text { anchors.centerIn: parent; text: "[ NEXT ]"; font.family: "monospace"; font.pixelSize: 13; font.bold: true; color: musicWindow.focusedIndex === 2 ? musicWindow.themeBg : musicWindow.themeDim; Behavior on color { ColorAnimation { duration: 150 } } }
                    MouseArea { anchors.fill: parent; onClicked: { musicWindow.focusedIndex = 2; musicWindow.player && musicWindow.player.next() } }
                }
            }
        }
        
        // Key Hint
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nav: <H> Left | <L> Right | <Enter> Select"
            color: Qt.rgba(1.0, 1.0, 1.0, 0.3)
            font.family: "monospace"
            font.pixelSize: 10
        }
      }
    }
  }
}
