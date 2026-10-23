import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // True measured width of full content
    readonly property real fullWidth: contentRow.implicitWidth + (Kirigami.Units.smallSpacing * 3)
    readonly property real fullHeight: Math.min(parent.height - 4, contentRow.implicitHeight + 6)

    // Animated progress from 0.0 (hidden) to 1.0 (fully expanded)
    property real animProgress: 0.0

    // Synchronize visual state with main.qml Plasmoid.status
    onAnimProgressChanged: {
        root.isVisuallyActive = (animProgress > 0.01);
    }

    // Trigger state changes
    states: [
        State {
            name: "active"
            when: root.isActive
            PropertyChanges {
                target: compactRoot
                animProgress: 1.0
            }
        },
        State {
            name: "inactive"
            when: !root.isActive
            PropertyChanges {
                target: compactRoot
                animProgress: 0.0
            }
        }
    ]

    transitions: [
        Transition {
            from: "inactive"
            to: "active"
            NumberAnimation {
                property: "animProgress"
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.12 // Apple spring bounce
            }
        },
        Transition {
            from: "active"
            to: "inactive"
            NumberAnimation {
                property: "animProgress"
                duration: 300
                easing.type: Easing.InOutCubic // Smooth collapse
            }
        }
    ]

    // Provide fluid animated dimensions to KDE panel layout
    readonly property real animatedWidth: fullWidth * animProgress
    readonly property real animatedHeight: fullHeight * animProgress

    Layout.minimumWidth: isVertical ? 0 : animatedWidth
    Layout.minimumHeight: isVertical ? animatedHeight : 0
    Layout.preferredWidth: isVertical ? 0 : animatedWidth
    Layout.preferredHeight: isVertical ? animatedHeight : 0
    implicitWidth: isVertical ? 0 : animatedWidth
    implicitHeight: isVertical ? animatedHeight : 0

    visible: animProgress > 0.001
    clip: true

    // macOS Dynamic Island Pill
    Rectangle {
        id: contentPill
        anchors.centerIn: parent
        width: Math.max(0, compactRoot.animatedWidth)
        height: Math.max(0, compactRoot.fullHeight)
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

        // Inner Content Container
        Item {
            anchors.centerIn: parent
            width: contentRow.implicitWidth
            height: contentRow.implicitHeight

            opacity: Math.max(0.0, Math.min(1.0, (compactRoot.animProgress - 0.25) / 0.75))
            scale: 0.88 + (0.12 * compactRoot.animProgress)

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
