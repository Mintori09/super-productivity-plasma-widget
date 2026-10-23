import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    Layout.preferredWidth: 280
    Layout.preferredHeight: 180

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header: App status
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Heading {
                level: 3
                text: "Super Productivity"
                Layout.fillWidth: true
            }
            Kirigami.Icon {
                source: root.isConnected ? "security-high" : "security-low"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                color: root.isConnected ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            visible: !root.isConnected
            text: "Cannot connect to Super Productivity.\nMake sure the app is running and Local REST API is enabled."
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.negativeTextColor
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.isConnected
            spacing: Kirigami.Units.smallSpacing

            // Task title
            QQC2.Label {
                Layout.fillWidth: true
                text: root.currentTaskTitle ? root.currentTaskTitle : "No active task"
                font.bold: true
                elide: Text.ElideRight
            }

            // Status and Cycle
            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    text: root.isBreak ? (root.isLongBreak ? "Long Break" : "Short Break") : (root.timerStatus === "running" ? "Focusing" : (root.timerStatus === "paused" ? "Paused" : "Idle"))
                    color: root.isBreak ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.highlightColor
                }
                QQC2.Label {
                    Layout.alignment: Qt.AlignRight
                    text: "Cycle: #" + root.cycle
                    color: Kirigami.Theme.disabledTextColor
                }
            }

            // Big Timer Display
            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 32
                font.bold: true
                text: root.formatTime(root.remainingMs)
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.mediumSpacing

                QQC2.Button {
                    text: "Stop Task"
                    icon.name: "media-playback-stop"
                    enabled: root.currentTaskId !== ""
                    onClicked: root.stopCurrentTask()
                }

                QQC2.Button {
                    text: "Open App"
                    icon.name: "window-duplicate"
                    onClicked: {
                        Plasmoid.expanded = false;
                        root.raiseSuperProductivityWindow();
                    }
                }
            }
        }
    }
}
