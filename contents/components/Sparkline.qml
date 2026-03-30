import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

Rectangle {
    id: sparkRoot
    
    // Propriétés configurables
    property var history: []
    property color lineColor: "#ffffff"
    property int minVal: 0
    property int maxVal: 100
    property int maxPoints: 60
    property string labelLeft: "60s"
    property string labelRight: "now"

    Layout.fillWidth: true
    height: 64
    radius: 6
    color: Qt.rgba(0, 0, 0, 0.15)
    border.color: Qt.rgba(255, 255, 255, 0.08)
    border.width: 1
    clip: true

    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d")
            if (history.length < 2) return
            ctx.clearRect(0, 0, width, height)

            var range = maxVal - minVal || 1
            var w = width
            var h = height

            // Zone remplie sous la courbe
            ctx.beginPath()
            for (var i = 0; i < history.length; i++) {
                var x = (i / (maxPoints - 1)) * w
                var y = h - ((history[i] - minVal) / range) * (h - 8) - 4
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.lineTo((history.length - 1) / (maxPoints - 1) * w, h)
            ctx.lineTo(0, h)
            ctx.closePath()
            
            var grad = ctx.createLinearGradient(0, 0, 0, h)
            grad.addColorStop(0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.25))
            grad.addColorStop(1, Qt.rgba(0,0,0,0))
            ctx.fillStyle = grad
            ctx.fill()

            // Ligne principale
            ctx.beginPath()
            ctx.strokeStyle = lineColor
            ctx.lineWidth = 1.5
            ctx.lineJoin = "round"
            for (var j = 0; j < history.length; j++) {
                var px = (j / (maxPoints - 1)) * w
                var py = h - ((history[j] - minVal) / range) * (h - 8) - 4
                if (j === 0) ctx.moveTo(px, py)
                else ctx.lineTo(px, py)
            }
            ctx.stroke()

            // Point actuel
            var lx = (history.length - 1) / (maxPoints - 1) * w
            var ly = h - ((history[history.length-1] - minVal) / range) * (h - 8) - 4
            ctx.beginPath()
            ctx.arc(lx, ly, 3, 0, Math.PI * 2)
            ctx.fillStyle = lineColor
            ctx.fill()
        }
    }

    // Force le redessin quand les données changent
    onHistoryChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()

    PlasmaComponents.Label {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.margins: 5; text: labelLeft; font.pixelSize: 9; opacity: 0.3
    }
    PlasmaComponents.Label {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 5; text: labelRight; font.pixelSize: 9; opacity: 0.3
    }
}