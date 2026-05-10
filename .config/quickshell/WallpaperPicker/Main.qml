import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    color: "transparent"
    focusable: true

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: 500
    margins { left: 0; right: 0; bottom: 20 }
    exclusiveZone: -1

    // Core Configuration
    QtObject {
        id: config
        
        property string userHome: "/home/null"
        property string wallDir: userHome + "/wallpaper/"
        property string thumbDir: wallDir + "thumbnails/"
        property string scriptDir: userHome + "/.config/quickshell/WallpaperPicker/Scripts/"

        property string thumbExt: ".jpg"
        property string videoExt: ".mp4"

        property int cardWidth: 200
        property int cardHeight: 280
        property int animationDuration: 450
        property int maxEntranceDelay: 800
        
        property int cardRadius: 22
    }

    property int currentIndex: 0

    // Helper Functions
    function terminateApp() {
        Qt.quit()
        Quickshell.execDetached(["kill", "-9", Quickshell.processId.toString()])
    }

    function applyWallpaper(thumbName) {
        if (!thumbName) return

        const videoName = thumbName.replace(config.thumbExt, config.videoExt)
        const fullPath = config.wallDir + videoName

        const genThumbsScript = config.scriptDir + "gen_thumbs.sh"
        const changeWallScript = config.scriptDir + "change_wall.sh"

        Quickshell.execDetached(["/bin/bash", genThumbsScript])
        Quickshell.execDetached(["/bin/bash", changeWallScript, fullPath])

        terminateApp()
    }

    // Input Shortcuts
    Shortcut { sequence: "Escape"; onActivated: terminateApp() }
    Shortcut { sequence: "Left"; onActivated: { if (root.currentIndex > 0) root.currentIndex-- } }
    Shortcut { sequence: "Right"; onActivated: { if (root.currentIndex < folderModel.count - 1) root.currentIndex++ } }
    Shortcut { sequence: "Return"; onActivated: { 
        if (folderModel.count > 0 && root.currentIndex >= 0) applyWallpaper(folderModel.get(root.currentIndex, "fileName")) 
    }}

    // Data Model
    FolderListModel {
        id: folderModel
        folder: "file://" + config.thumbDir
        nameFilters: ["*" + config.thumbExt]
        showDirs: false
        onCountChanged: { if (root.currentIndex >= count && count > 0) root.currentIndex = count - 1 }
    }

    // Background Dimming
    Rectangle {
        id: desktopDimmer
        anchors.fill: parent
        anchors.margins: -500
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: 0
        
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    }

    // Main UI Components
    Item {
        id: scene
        anchors.fill: parent
        opacity: 0
        transform: Translate { id: sceneSlide; y: 60 }

        ParallelAnimation {
            running: true
            NumberAnimation { target: scene; property: "opacity"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
            NumberAnimation { target: sceneSlide; property: "y"; from: 60; to: 0; duration: 600; easing.type: Easing.OutBack }
        }

        Repeater {
            id: cardRepeater
            model: folderModel

            Item {
                id: card

                // Geometry & Math
                readonly property int totalCards: Math.max(folderModel.count, 1)
                readonly property bool isSelected: index === root.currentIndex

                readonly property real spreadDeg: Math.min(80, totalCards * 9)
                readonly property real angleDeg: totalCards > 1 ? (-spreadDeg / 2.0) + (index / (totalCards - 1.0)) * spreadDeg : 0
                readonly property real angleRad: angleDeg * (Math.PI / 180.0)

                readonly property real pivotY: scene.height + 100
                readonly property real fanRadius: 280

                width: config.cardWidth
                height: config.cardHeight

                x: (scene.width / 2) - (width / 2) + Math.sin(angleRad) * fanRadius
                y: pivotY - (height / 2) - Math.cos(angleRad) * fanRadius + (isSelected ? -45 : 0)
                
                rotation: angleDeg
                scale: isSelected ? 1.15 : 0.90
                z: isSelected ? 9999 : (totalCards - Math.abs(root.currentIndex - index))
                opacity: 0

                // Animations
                Behavior on x { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutBack } }
                Behavior on rotation { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutBack } }
                Behavior on scale { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutBack } }
                Behavior on z { PropertyAnimation { duration: 150 } }

                Component.onCompleted: Qt.callLater(() => entrTimer.start())

                Timer {
                    id: entrTimer
                    interval: Math.min(index * 40, config.maxEntranceDelay)
                    onTriggered: entrAnim.start()
                }

                NumberAnimation { id: entrAnim; target: card; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }

                // Card Shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: config.cardRadius
                    color: "transparent"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, card.isSelected ? 0.8 : 0.4)
                        shadowBlur: card.isSelected ? 1.5 : 0.6
                        shadowVerticalOffset: card.isSelected ? 25 : 8
                        shadowHorizontalOffset: 0
                        
                        Behavior on shadowBlur { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutExpo } }
                        Behavior on shadowVerticalOffset { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutExpo } }
                    }
                }

                // Card Frame & Image
                Rectangle {
                    id: cardFrame
                    anchors.fill: parent
                    radius: config.cardRadius
                    color: "transparent"
                    clip: true
                    
                    border.color: card.isSelected ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(1, 1, 1, 0.1)
                    border.width: card.isSelected ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    Image {
                        id: img
                        anchors.fill: parent
                        source: typeof fileUrl !== 'undefined' ? fileUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                        layer.enabled: true
                        sourceSize.width: config.cardWidth * 1.5
                        sourceSize.height: config.cardHeight * 1.5
                    }

                    Rectangle {
                        id: msk
                        anchors.fill: img
                        radius: config.cardRadius - border.width
                        visible: false
                        layer.enabled: true
                    }

                    // Color Correction
                    MultiEffect {
                        anchors.fill: img
                        source: img
                        maskEnabled: true
                        maskSource: msk
                        
                        saturation: card.isSelected ? 0.15 : -0.75 
                        brightness: card.isSelected ? 0.05 : -0.35

                        Behavior on saturation { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutCubic } }
                        Behavior on brightness { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutCubic } }
                    }

                    // Reflection Overlay
                    Rectangle {
                        anchors.fill: parent
                        radius: config.cardRadius
                        opacity: card.isSelected ? 0.15 : 0.05
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.8) }
                            GradientStop { position: 0.4; color: "transparent" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        transform: Rotation { origin.x: width/2; origin.y: height/2; angle: 35 }
                    }

                    // Label Pill
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 16
                        
                        width: labelText.implicitWidth + 30
                        height: 28
                        radius: height / 2
                        
                        color: Qt.rgba(0.1, 0.1, 0.1, 0.75)
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 1
                        
                        opacity: card.isSelected ? 1 : 0
                        transform: Translate { y: card.isSelected ? 0 : 15 }
                        
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        Behavior on transform { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            color: "white"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                            style: Text.Outline
                            styleColor: Qt.rgba(0, 0, 0, 0.3)
                            
                            text: {
                                if (typeof fileName === 'undefined' || !fileName) return ""
                                const nameBase = fileName.replace(config.thumbExt, "")
                                return nameBase.length > 18 ? nameBase.substring(0, 18) + "…" : nameBase
                            }
                        }
                    }
                }

                // Mouse Controls
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            terminateApp()
                        } else if (index === root.currentIndex) {
                            applyWallpaper(folderModel.get(root.currentIndex, "fileName"))
                        } else {
                            root.currentIndex = index
                        }
                    }
                    
                    onEntered: if (!card.isSelected) card.scale = 0.95
                    onExited: if (!card.isSelected) card.scale = 0.90
                }
            }
        }
    }
}
