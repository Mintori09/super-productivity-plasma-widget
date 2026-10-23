import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // True measured full target width & height
    readonly property real fullWidth: contentRow.implicitWidth + (Kirigami.Units.smallSpacing * 3.5)
    readonly property real fullHeight: Math.min(parent.height - 4, contentRow.implicitHeight + 8)

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

    // Animated progress from 0.0 (hidden) to 1.0 (fully expanded)
    property real animProgress: 0.0

    onAnimProgressChanged: {
        root.isVisuallyActive = (animProgress > 0.005);
    }

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
                duration: 520
                easing.type: Easing.OutQuart // Silky smooth fluid expansion
            }
        },
        Transition {
            from: "active"
            to: "inactive"
            NumberAnimation {
                property: "animProgress"
                duration: 450
                easing.type: Easing.InOutQuart // Seamless fluid collapse
            }
        }
    ]

    // Fluid animated dimensions to panel layout
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
        clip: true // Prevent text spilling out of pill during size transition

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

            // Smooth cubic fade curve synced with expansion
            opacity: Math.max(0.0, Math.min(1.0, (compactRoot.animProgress - 0.35) / 0.65))
            scale: 0.90 + (0.10 * compactRoot.animProgress)

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
                    text: root.isActive ? root.formatTime(root.remainingMs) : compactRoot.displayTime
                    font.bold: true
                    font.family: "SF Pro Text, -apple-system, Cantarell, Noto Sans, sans-serif"
                    color: root.isBreak ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                }

                QQC2.Label {
                    id: taskLabel
                    Layout.alignment: Qt.AlignVCenter
                    Layout.maximumWidth: 130
                    elide: Text.ElideRight
                    visible: !isVertical && (root.currentTaskTitle !== "" || compactRoot.displayTask !== "")
                    text: root.isActive ? root.currentTaskTitle : compactRoot.displayTask
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
            contentPill.scale = 1.04;
        }
        onExited: {
            contentPill.scale = 1.0;
        }
    }
}
