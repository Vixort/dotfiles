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

    // =====================================================================
    // CORE CONFIGURATION & CONSTANTS
    // =====================================================================
    QtObject {
        id: config
        
        // Paths configuration - Extracted to prevent hardcoded magic strings
        property string userHome: "/home/null"
        property string wallDir: userHome + "/wallpaper/"
        property string thumbDir: wallDir + "thumbnails/"
        property string scriptDir: userHome + "/.config/quickshell/WallpaperPicker/Scripts/"

        // File extensions
        property string thumbExt: ".jpg"
        property string videoExt: ".mp4"

        // UI Metrics
        property int cardWidth: 190
        property int cardHeight: 260
        property int animationDuration: 320
        property int maxEntranceDelay: 800 // Cap timer to prevent endless loading on huge folders
    }

    // State Management
    property int currentIndex: 0

    // =====================================================================
    // HELPER FUNCTIONS
    // =====================================================================
    function terminateApp() {
        Qt.quit()
        // Fallback forcefully terminates the detached process if Qt.quit hangs
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

    // =====================================================================
    // INPUT CONTROLLERS (Shortcuts replace the hidden ListView)
    // =====================================================================
    Shortcut {
        sequence: "Escape"
        onActivated: terminateApp()
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            if (root.currentIndex > 0) root.currentIndex--
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            if (root.currentIndex < folderModel.count - 1) root.currentIndex++
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            if (folderModel.count > 0 && root.currentIndex >= 0 && root.currentIndex < folderModel.count) {
                const thumbName = folderModel.get(root.currentIndex, "fileName")
                applyWallpaper(thumbName)
            }
        }
    }

    // =====================================================================
    // DATA MODEL
    // =====================================================================
    FolderListModel {
        id: folderModel
        folder: "file://" + config.thumbDir
        nameFilters: ["*" + config.thumbExt]
        showDirs: false

        // Safety bound check if the folder contents change dynamically
        onCountChanged: {
            if (root.currentIndex >= count && count > 0) {
                root.currentIndex = count - 1
            }
        }
    }

    // =====================================================================
    // MAIN SCENE & UI COMPONENTS
    // =====================================================================
    Item {
        id: scene
        anchors.fill: parent
        opacity: 0
        transform: Translate { id: sceneSlide; y: 50 }

        // Scene Entrance Animation
        ParallelAnimation {
            running: true
            NumberAnimation {
                target: scene
                property: "opacity"
                from: 0; to: 1
                duration: 500
                easing.type: Easing.OutExpo
            }
            NumberAnimation {
                target: sceneSlide
                property: "y"
                from: 50; to: 0
                duration: 500
                easing.type: Easing.OutExpo
            }
        }

        // Card Renderer
        Repeater {
            id: cardRepeater
            model: folderModel

            Item {
                id: card

                // --- Geometry & Math Context ---
                readonly property int totalCards: Math.max(folderModel.count, 1)
                readonly property bool isSelected: index === root.currentIndex

                readonly property real spreadDeg: Math.min(70, totalCards * 8)
                readonly property real angleDeg: totalCards > 1 
                    ? (-spreadDeg / 2.0) + (index / (totalCards - 1.0)) * spreadDeg 
                    : 0
                readonly property real angleRad: angleDeg * (Math.PI / 180.0)

                readonly property real pivotY: scene.height + 80
                readonly property real fanRadius: 260

                // Positioning
                width: config.cardWidth
                height: config.cardHeight

                x: (scene.width / 2) - (width / 2) + Math.sin(angleRad) * fanRadius
                y: pivotY - (height / 2) - Math.cos(angleRad) * fanRadius + (isSelected ? -20 : 0)
                
                rotation: angleDeg
                scale: isSelected ? 1.10 : 1.0
                z: isSelected ? 9999 : index
                opacity: 0

                // Smoothing Behaviors
                Behavior on x { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutExpo } }
                Behavior on y { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutExpo } }
                Behavior on rotation { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutExpo } }
                Behavior on scale { NumberAnimation { duration: config.animationDuration; easing.type: Easing.OutExpo } }

                // Entrance Timing
                Component.onCompleted: Qt.callLater(() => entrTimer.start())

                Timer {
                    id: entrTimer
                    interval: Math.min(index * 35, config.maxEntranceDelay)
                    onTriggered: entrAnim.start()
                }

                NumberAnimation {
                    id: entrAnim
                    target: card
                    property: "opacity"
                    from: 0; to: 1
                    duration: 400
                    easing.type: Easing.OutCubic
                }

                // --- Visual Hierarchy ---

                // 1. Card Shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: 18
                    color: "transparent"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, card.isSelected ? 0.7 : 0.35)
                        shadowBlur: 0.9
                        shadowVerticalOffset: card.isSelected ? 14 : 5
                        shadowHorizontalOffset: 0
                    }
                }

                // 2. Main Card Frame
                Rectangle {
                    id: cardFrame
                    anchors.fill: parent
                    radius: 16
                    color: "transparent"
                    clip: true
                    border.color: card.isSelected ? Qt.rgba(1, 1, 1, 0.88) : Qt.rgba(1, 1, 1, 0.16)
                    border.width: card.isSelected ? 1.5 : 1

                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    // Image loading with strict memory bounds
                    Image {
                        id: img
                        anchors.fill: parent
                        anchors.margins: 1
                        source: typeof fileUrl !== 'undefined' ? fileUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                        layer.enabled: true
                        
                        // CRITICAL PERFORMANCE FIX: Downscale image to save VRAM
                        sourceSize.width: config.cardWidth
                        sourceSize.height: config.cardHeight
                    }

                    Rectangle {
                        id: msk
                        anchors.fill: img
                        radius: 15
                        visible: false
                        layer.enabled: true
                    }

                    // Combined MultiEffect (Replaces dual-overlapping effects)
                    MultiEffect {
                        anchors.fill: img
                        source: img
                        maskEnabled: true
                        maskSource: msk
                        
                        saturation: card.isSelected ? 0.08 : -0.45
                        brightness: card.isSelected ? 0.02 : -0.18

                        Behavior on saturation { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                        Behavior on brightness { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    }

                    // Gloss Overlay Layer
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height * 0.3
                        radius: 15
                        opacity: 0.07
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "white" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Bottom Label & Gradient Layer
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 36
                        opacity: card.isSelected ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                        }

                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 4
                            color: Qt.rgba(1, 1, 1, 0.82)
                            font.pixelSize: 10
                            font.letterSpacing: 0.6
                            text: {
                                if (typeof fileName === 'undefined' || !fileName) return ""
                                const nameBase = fileName.replace(config.thumbExt, "")
                                return nameBase.length > 20 ? nameBase.substring(0, 20) + "…" : nameBase
                            }
                        }
                    }
                }

                // 3. Pointer Interactions
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            terminateApp()
                        } else {
                            root.currentIndex = index
                        }
                    }
                }
            }
        }
    }
}
