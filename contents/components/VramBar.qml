import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    property int used: 0
    property int total: 1
    property color barColor: "#1D9E75"

    spacing: 6
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        PlasmaComponents.Label { text: "VRAM"; font.pixelSize: 12; opacity: 0.6 }
        Item { Layout.fillWidth: true }
        PlasmaComponents.Label {
            text: used + " / " + total + " MiB"
            font.pixelSize: 13; font.weight: Font.Medium; color: barColor
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 20
        radius: 10
        color: Qt.rgba(0, 0, 0, 0.15)
        border.color: Qt.rgba(255, 255, 255, 0.08)
        border.width: 1

        Rectangle {
            width: Math.max(20, parent.width * (used / Math.max(total, 1)))
            height: parent.height
            radius: 10
            color: barColor
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
    }
}