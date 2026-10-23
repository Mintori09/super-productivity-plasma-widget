import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // True measured components
    readonly property real horizontalPadding: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

    // Cached labels so text never vanishes before collapse completes
    property string displayTime: ""
    property string displayTask: ""

    Connections {
        target: root
        function onRemainingMsChanged() {
            if (root.isActive) {
                compactRoot.displayTime = root.formatTime(root.remainingMs);
            }
        }
        function onCurrentTaskTitleChanged() {
            if (root.isActive && root.currentTaskTitle) {
                compactRoot.displayTask = root.currentTaskTitle;
            }
        }
    }

    // 1. Overall Session Lifecycle Animation (Appear/Disappear: 0.0 -> 1.0)
    property real animProgress: 0.0

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
                duration: 450
                easing.type: Easing.OutQuart
            }
        },
        Transition {
            from: "active"
            to: "inactive"
            NumberAnimation {
                property: "animProgress"
                duration: 380
                easing.type: Easing.InOutQuart
            }
        }
    ]

    // 2. Pause / Resume Fluid Width Transition (Option B)
    // When Running: show task title (expand pill width)
    // When Paused: fade task title & contract pill width smoothly to just icon + time
    readonly property bool hasTask: (root.isActive && root.currentTaskTitle !== "") || (!root.isActive && compactRoot.displayTask !== "")
    readonly property bool isTaskExpanded: root.timerStatus === "running" && hasTask

    property real taskExpansionProgress: isTaskExpanded ? 1.0 : 0.0
    Behavior on taskExpansionProgress {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuart // Silky smooth macOS fluid morph
        }
    }

    // Layout calculation based on dynamic expansion
    readonly property real baseWidth: mainIcon.width + timeLabel.implicitWidth + (Kirigami.Units.smallSpacing * 2) + (horizontalPadding * 2)
    readonly property real taskAddedWidth: (taskLabel.implicitWidth + Kirigami.Units.smallSpacing) * taskExpansionProgress
    readonly property real fullTargetWidth: baseWidth + taskAddedWidth
    readonly property real fullHeight: Math.min(parent.height - 4, contentRow.implicitHeight + 8)

    // Fluid animated dimensions to KDE panel layout
    readonly property real animatedWidth: fullTargetWidth * animProgress
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
                return Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.20);
            }
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.13);
        }

        border.width: 1
        border.color: {
            if (root.isBreak) {
                return Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.38);
            }
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20);
        }

        // Inner Content Container
        Item {
            anchors.centerIn: parent
            width: contentRow.implicitWidth
            height: contentRow.implicitHeight

            opacity: Math.max(0.0, Math.min(1.0, (compactRoot.animProgress - 0.25) / 0.75))
            scale: 0.90 + (0.10 * compactRoot.animProgress)

            RowLayout {
                id: contentRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing

                // Icon stays as pure clock icon as requested
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
                        return Kirigami.Theme.disabledTextColor; // Soft dim on pause
                    }
                }

                // Time label: slightly dimmed when paused to indicate frozen state
                QQC2.Label {
                    id: timeLabel
                    Layout.alignment: Qt.AlignVCenter
                    text: root.isActive ? root.formatTime(root.remainingMs) : compactRoot.displayTime
                    font.bold: true
                    font.family: "SF Pro Text, -apple-system, Cantarell, Noto Sans, sans-serif"
                    color: root.isBreak ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                    opacity: (root.timerStatus === "paused") ? 0.7 : 1.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                // Task label: Fades out and slides width to 0 during Pause
                Item {
                    id: taskContainer
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: isVertical ? 0 : (taskLabel.implicitWidth * compactRoot.taskExpansionProgress)
                    Layout.preferredHeight: taskLabel.implicitHeight
                    implicitWidth: isVertical ? 0 : (taskLabel.implicitWidth * compactRoot.taskExpansionProgress)
                    implicitHeight: taskLabel.implicitHeight
                    visible: !isVertical && compactRoot.hasTask && compactRoot.taskExpansionProgress > 0.001
                    clip: true

                    QQC2.Label {
                        id: taskLabel
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        Layout.maximumWidth: 130
                        elide: Text.ElideRight
                        text: root.isActive ? root.currentTaskTitle : compactRoot.displayTask
                        font.family: "SF Pro Text, -apple-system, Cantarell, Noto Sans, sans-serif"
                        color: Kirigami.Theme.disabledTextColor
                        opacity: compactRoot.taskExpansionProgress
                    }
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
            contentPill.scale = 1.04;
        }
        onExited: {
            contentPill.scale = 1.0;
        }
    }
}
