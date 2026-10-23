import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Smooth width and height transitions
    Layout.minimumWidth: isVertical ? 0 : width
    Layout.minimumHeight: isVertical ? height : 0
    Layout.preferredWidth: isVertical ? 0 : width
    Layout.preferredHeight: isVertical ? height : 0
    implicitWidth: width
    implicitHeight: height

    width: root.isActive ? contentRow.implicitWidth : 0
    height: root.isActive ? contentRow.implicitHeight : 0
    visible: width > 0 || opacity > 0
    opacity: root.isActive ? 1.0 : 0.0
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutQuad
        }
    }

    RowLayout {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Kirigami.Units.smallSpacing

        // Subtle scale transition for content
        scale: root.isActive ? 1.0 : 0.85
        Behavior on scale {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutBack
            }
        }

        Kirigami.Icon {
            id: mainIcon
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            Layout.alignment: Qt.AlignVCenter
            source: {
                if (!root.isConnected) return "network-offline";
                if (root.isBreak) return "coffee";
                if (root.timerStatus === "running") return "chronometer";
                return "appointment-soon";
            }
            color: {
                if (!root.isConnected) return Kirigami.Theme.disabledTextColor;
                if (root.isBreak) return Kirigami.Theme.positiveTextColor;
                if (root.timerStatus === "running") return Kirigami.Theme.highlightColor;
                return Kirigami.Theme.textColor;
            }

            Behavior on color {
                ColorAnimation {
                    duration: Kirigami.Units.shortDuration
                }
            }
        }

        QQC2.Label {
            id: timeLabel
            Layout.alignment: Qt.AlignVCenter
            visible: root.isConnected && (root.timerStatus === "running" || root.timerStatus === "paused")
            text: root.formatTime(root.remainingMs)
            font.bold: true
            color: root.isBreak ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
        }

        QQC2.Label {
            id: taskLabel
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 140
            elide: Text.ElideRight
            visible: !isVertical && root.isConnected && root.currentTaskTitle !== "" && (root.timerStatus === "running" || root.timerStatus === "paused")
            text: root.currentTaskTitle
            color: Kirigami.Theme.disabledTextColor

            Behavior on Layout.maximumWidth {
                NumberAnimation {
                    duration: Kirigami.Units.shortDuration
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Plasmoid.expanded = !Plasmoid.expanded;
        }
    }
}
