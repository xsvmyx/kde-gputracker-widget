import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

Item {
    id: compactRoot
    
    // Définition des tailles pour le Panel Plasma
    Layout.minimumWidth: 240 // Augmenté un peu pour 3 boîtes
    Layout.maximumWidth: 350
    Layout.minimumHeight: 28
    

    RowLayout {
        anchors.fill: parent
        spacing: 6

        // --- BOÎTE 1 : USAGE ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0,0,0,0.2)
            border.color: root.borderCol
            border.width: 0.5
            radius: 4

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 6
                
                PlasmaComponents.Label { text: "U"; opacity: 0.6; font.pixelSize: 10; font.bold: true }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label { 
                    text: root.gpuUsage + "%"
                    font.pixelSize: 11; font.weight: Font.Medium 
                    color: root.gpuUsage > 80 ? "#D85A30" : "#5DCAA5" 
                }
            }
        }

        // --- BOÎTE 2 : TEMP ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0,0,0,0.2)
            border.color: root.borderCol
            border.width: 0.5
            radius: 4

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 6

                PlasmaComponents.Label { text: "T"; opacity: 0.6; font.pixelSize: 10; font.bold: true }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label { 
                    text: root.gpuTemp + "°"
                    font.pixelSize: 11; font.weight: Font.Medium
                    color: root.gpuTemp > 75 ? "#D85A30" : "#534AB7"
                }
            }
        }

        // --- BOÎTE 3 : VRAM ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0,0,0,0.3)
            border.color: root.borderCol
            border.width: 0.5
            radius: 4

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 6

                PlasmaComponents.Label { text: "V"; opacity: 0.6; font.pixelSize: 10; font.bold: true }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label { 
                    text: (root.vramUsed / 1024).toFixed(1) + "G"
                    font.pixelSize: 11; font.weight: Font.Medium
                    color: (root.vramUsed / root.vramTotal) > 0.8 ? "#D85A30" : "#1D9E75"
                }
            }
        }
    }
}