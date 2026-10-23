import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Fluid animated width (macOS Dynamic Island expansion)
    property real fullWidth: contentRow.implicitWidth + (Kirigami.Units.smallSpacing * 3)
    property real animWidth: root.isActive ? fullWidth : 0
    property real animHeight: root.isActive ? Math.min(parent.height - 4, contentRow.implicitHeight + 6) : 0

    Behavior on animWidth {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.15 // Gentle, elegant macOS expansion
        }
    }

    Behavior on animHeight {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }

    Layout.minimumWidth: isVertical ? 0 : animWidth
    Layout.minimumHeight: isVertical ? animHeight : 0
    Layout.preferredWidth: isVertical ? 0 : animWidth
    Layout.preferredHeight: isVertical ? animHeight : 0
    implicitWidth: isVertical ? 0 : animWidth
    implicitHeight: isVertical ? animHeight : 0

    visible: animWidth > 0.5 || opacity > 0
    clip: true

    // macOS Dynamic Island Pill
    Rectangle {
        id: contentPill
        anchors.centerIn: parent
        width: Math.max(0, compactRoot.animWidth)
        height: Math.max(0, compactRoot.animHeight)
        radius: height / 2

        color: {
            if (root.isBreak) {
                return Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.18);
            }
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12);
        }

        border.width: 1
        border.color: {
            if (root.isBreak) {
                return Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.35);
            }
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18);
        }

        // Inner Content Layer with synchronized fade and gentle scale
        Item {
            anchors.centerIn: parent
            width: contentRow.implicitWidth
            height: contentRow.implicitHeight

            opacity: root.isActive ? 1.0 : 0.0
            scale: root.isActive ? 1.0 : 0.85

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }

            RowLayout {
                id: contentRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    id: mainIcon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small - 2
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small - 2
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
                            duration: 250
                        }
                    }
                }

                QQC2.Label {
                    id: timeLabel
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.isConnected && (root.timerStatus === "running" || root.timerStatus === "paused")
                    text: root.formatTime(root.remainingMs)
                    font.bold: true
                    font.family: "SF Pro Text, -apple-system, Cantarell, Noto Sans, sans-serif"
                    color: root.isBreak ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                }

                QQC2.Label {
                    id: taskLabel
                    Layout.alignment: Qt.AlignVCenter
                    Layout.maximumWidth: 130
                    elide: Text.ElideRight
                    visible: !isVertical && root.isConnected && root.currentTaskTitle !== "" && (root.timerStatus === "running" || root.timerStatus === "paused")
                    text: root.currentTaskTitle
                    font.family: "SF Pro Text, -apple-system, Cantarell, Noto Sans, sans-serif"
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Plasmoid.expanded = !Plasmoid.expanded;
        }
        onEntered: {
            contentPill.scale = 1.05;
        }
        onExited: {
            contentPill.scale = 1.0;
        }
    }
}
