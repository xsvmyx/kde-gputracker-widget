import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.core as PlasmaCore
import "../components" as MyComponents 
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Vendor
    property string gpuVendor: ""
    property bool   amdHasRocm: false
    property bool   detected: false

    property string gpuName: "GPU"
    property int    gpuUsage: 0
    property int    gpuTemp: 0
    property int    vramUsed: 0
    property int    vramTotal: 6141
    property string driverVersion: "595.45"
    property var    usageHistory: []
    property var    tempHistory: []
    readonly property int maxPoints: 60

    readonly property color borderCol:
        gpuVendor === "nvidia" ? "#76b900" :
        gpuVendor === "amd"    ? "#ED1C24" : "#444444"
    





    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var output = data["stdout"].trim()

            // Détection vendor
            if (sourceName.indexOf("lspci") !== -1) {
                var lower = output.toLowerCase()
                if (lower.indexOf("nvidia") !== -1)
                    root.gpuVendor = "nvidia"
                else if (lower.indexOf("amd") !== -1 || lower.indexOf("radeon") !== -1)
                    root.gpuVendor = "amd"
                else
                    root.gpuVendor = ""
                root.detected = true
                if (root.gpuVendor === "amd")
                    executable.exec("which rocm-smi")

            // Verification rocm-smi
            } else if (sourceName.indexOf("which rocm-smi") !== -1) {
                root.amdHasRocm = output.length > 0

            // Poll NVIDIA
            } else if (sourceName.indexOf("nvidia-smi") !== -1) {
                var parts = output.split(",")
                if (parts.length >= 5) {
                    root.gpuName   = parts[0].trim()
                    root.gpuUsage  = parseInt(parts[1].trim())
                    root.gpuTemp   = parseInt(parts[2].trim())
                    root.vramUsed  = parseInt(parts[3].trim())
                    root.vramTotal = parseInt(parts[4].trim())
                    pushHistory(root.gpuUsage, root.gpuTemp)
                }

            // Poll AMD rocm-smi
            } else if (sourceName.indexOf("rocm-smi") !== -1) {
                var lines = output.split("\n")
                if (lines.length >= 2) {
                    var vals = lines[1].split(",")
                    if (vals.length >= 5) {
                        root.gpuUsage  = parseInt(vals[1])
                        root.gpuTemp   = parseInt(vals[2])
                        root.vramTotal = Math.round(parseInt(vals[3]) / 1048576)
                        root.vramUsed  = Math.round(parseInt(vals[4]) / 1048576)
                        pushHistory(root.gpuUsage, root.gpuTemp)
                    }
                }

            // Poll AMD sysfs
            } else if (sourceName.indexOf("gpu_busy_percent") !== -1) {
                var lines = output.split("\n")
                if (lines.length >= 4) {
                    root.gpuUsage  = parseInt(lines[0])
                    root.gpuTemp   = Math.round(parseInt(lines[1]) / 1000)
                    root.vramUsed  = Math.round(parseInt(lines[2]) / 1048576)
                    root.vramTotal = Math.round(parseInt(lines[3]) / 1048576)
                    pushHistory(root.gpuUsage, root.gpuTemp)
                }
            }

            disconnectSource(sourceName)
        }

        function exec(cmd) { connectSource(cmd) }
    }

    function pushHistory(usage, temp) {
        var u = usageHistory.slice(); u.push(usage)
        var t = tempHistory.slice();  t.push(temp)
        if (u.length > maxPoints) u.shift()
        if (t.length > maxPoints) t.shift()
        usageHistory = u
        tempHistory  = t
    }

    function pollCmd() {
        if (gpuVendor === "nvidia")
            return "nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits"
        if (gpuVendor === "amd" && amdHasRocm)
            return "rocm-smi --showuse --showtemp --showmeminfo vram --csv"
        if (gpuVendor === "amd")
            return "cat /sys/class/drm/card0/device/gpu_busy_percent && cat /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input && cat /sys/class/drm/card0/device/mem_info_vram_used && cat /sys/class/drm/card0/device/mem_info_vram_total"
        return ""
    }

    //start detection
    Timer {
        interval: 100; running: true; repeat: false
        onTriggered: executable.exec("lspci | grep -i 'vga\\|3d\\|display'")
    }

    // Poll every 2s
    Timer {
        interval: 2000
        running: root.detected && root.gpuVendor !== ""
        repeat: true
        onTriggered: {
            var cmd = root.pollCmd()
            if (cmd !== "") executable.exec(cmd)
        }
    }

    fullRepresentation: Rectangle {
        id: container
        width: 380
        height: root.detected && root.gpuVendor === "" ? 80 : 440

        color: Kirigami.Theme.backgroundColor
        border.color: root.borderCol
        border.width: 4
        radius: 8

        PlasmaComponents.ToolButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        icon.name: "view-refresh"
        onClicked: root.restartDetection()
        }

        // Pas de GPU
        PlasmaComponents.Label {
            visible: root.detected && root.gpuVendor === ""
            anchors.centerIn: parent
            text: "No GPU detected :("
            font.pixelSize: 14
            opacity: 0.6
        }

        // GPU détecté
        ColumnLayout {
            visible: root.gpuVendor !== ""
            anchors.fill: parent; anchors.margins: 16; spacing: 12

        

            ColumnLayout {
                spacing: 2
                PlasmaComponents.Label {
                    text: root.gpuName
                    font.pixelSize: 15; font.weight: Font.Medium
                }
                PlasmaComponents.Label {
                    text: "Driver " + root.driverVersion
                    font.pixelSize: 11; opacity: 0.5
                }
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                RowLayout {
                    PlasmaComponents.Label { text: "GPU Usage"; font.pixelSize: 12; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label { text: root.gpuUsage + "%"; color: "#534AB7"; font.weight: Font.Medium }
                }
                MyComponents.Sparkline {
                    history: root.usageHistory
                    lineColor: "#534AB7"
                    maxPoints: root.maxPoints
                }
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                RowLayout {
                    PlasmaComponents.Label { text: "Temperature"; font.pixelSize: 12; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label { text: root.gpuTemp + "°C"; color: "#D85A30"; font.weight: Font.Medium }
                }
                MyComponents.Sparkline {
                    history: root.tempHistory
                    lineColor: "#D85A30"
                    minVal: 20
                    maxPoints: root.maxPoints
                }
                visible: container.height > 240
            }

            MyComponents.VramBar {
                used: root.vramUsed
                total: root.vramTotal
                visible: container.height > 315
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: "white"; opacity: 0.1 }

            RowLayout {
                visible: container.height > 350
                Layout.fillWidth: true
                PlasmaComponents.Label { text: "Power: 65W"; font.pixelSize: 11; opacity: 0.6 }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label { text: "VRAM Total: " + root.vramTotal + "MB"; font.pixelSize: 11; opacity: 0.6 }
            }
        }
    }

    //tool bar view
    compactRepresentation: MyComponents.CompactView {}



function restartDetection() {
    // Vide toutes les sources en cours
    executable.connectedSources.forEach(function(src) {
        executable.disconnectSource(src)
    })

    root.detected = false
    root.gpuVendor = ""
    root.gpuName = "GPU"
    root.gpuUsage = 0
    root.gpuTemp = 0
    root.vramUsed = 0
    //root.usageHistory = []
   //root.tempHistory = []

    executable.exec("lspci | grep -Ei 'vga|3d'")
}
}