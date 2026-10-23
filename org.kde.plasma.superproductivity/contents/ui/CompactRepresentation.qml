import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    visible: root.isActive
    Layout.minimumWidth: (!root.isActive) ? 0 : (isVertical ? 0 : contentRow.implicitWidth)
    Layout.minimumHeight: (!root.isActive) ? 0 : (isVertical ? contentRow.implicitHeight : 0)
    Layout.preferredWidth: (!root.isActive) ? 0 : (isVertical ? 0 : contentRow.implicitWidth)
    Layout.preferredHeight: (!root.isActive) ? 0 : (isVertical ? contentRow.implicitHeight : 0)
    implicitWidth: root.isActive ? contentRow.implicitWidth : 0
    implicitHeight: root.isActive ? contentRow.implicitHeight : 0

    RowLayout {
        id: contentRow
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

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
            Layout.maximumWidth: 120
            elide: Text.ElideRight
            visible: !isVertical && root.isConnected && root.currentTaskTitle !== "" && (root.timerStatus === "running" || root.timerStatus === "paused")
            text: root.currentTaskTitle
            color: Kirigami.Theme.disabledTextColor
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            Plasmoid.expanded = !Plasmoid.expanded;
        }
    }
}
