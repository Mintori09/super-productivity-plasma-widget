import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Target width requested from panel
    property real targetWidth: root.isActive ? (contentPill.implicitWidth + Kirigami.Units.smallSpacing * 2) : 0
    property real targetHeight: root.isActive ? (contentPill.implicitHeight) : 0

    Layout.minimumWidth: isVertical ? 0 : targetWidth
    Layout.minimumHeight: isVertical ? targetHeight : 0
    Layout.preferredWidth: isVertical ? 0 : targetWidth
    Layout.preferredHeight: isVertical ? targetHeight : 0
    implicitWidth: isVertical ? 0 : targetWidth
    implicitHeight: isVertical ? targetHeight : 0

    visible: targetWidth > 0 || opacity > 0
    clip: true

    // macOS Dynamic Island / Capsule Container
    Rectangle {
        id: contentPill
        anchors.centerIn: parent
        implicitWidth: contentRow.implicitWidth + (Kirigami.Units.smallSpacing * 3)
        implicitHeight: Math.min(parent.height - 4, contentRow.implicitHeight + 6)
        radius: height / 2

        // macOS vibrant translucent dark/light pill styling
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

        // macOS Spring / Fluid Motion: Scale, Opacity & Y-offset
        opacity: root.isActive ? 1.0 : 0.0
        scale: root.isActive ? 1.0 : 0.8
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutBack
                easing.overshoot: 1.4 // Distinctive macOS spring/bounce
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 300
                easing.type: Easing.OutQuad
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
            contentPill.scale = root.isActive ? 1.0 : 0.8;
        }
    }
}
