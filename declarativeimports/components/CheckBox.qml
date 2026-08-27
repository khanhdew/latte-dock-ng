/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami 2.0 as Kirigami

QQC2.CheckBox {
    id: root
    Kirigami.Theme.inherit: true
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    SystemPalette {
        id: systemPalette
        colorGroup: SystemPalette.Active
    }

    palette.window: systemPalette.window
    palette.windowText: systemPalette.windowText
    palette.base: systemPalette.base
    palette.text: systemPalette.text
    palette.button: systemPalette.button
    palette.buttonText: systemPalette.buttonText
    palette.highlight: systemPalette.highlight
    palette.highlightedText: systemPalette.highlightedText

    property int value: 0
    property alias partiallyCheckedEnabled: root.tristate
    property alias checkedState: root.checkState

    // Custom string tooltip — required because many config pages do
    //   LatteComponents.CheckBox { tooltip: i18n("...") }
    // and Plasma 6 made "Cannot assign to non-existent property" fatal.
    property string tooltip: ""

    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    QQC2.ToolTip.visible: hovered && tooltip !== ""
    QQC2.ToolTip.text: tooltip
    spacing: Kirigami.Units.smallSpacing

    readonly property color controlTextColor: enabled
        ? systemPalette.windowText
        : Qt.rgba(systemPalette.windowText.r, systemPalette.windowText.g, systemPalette.windowText.b, 0.45)
    readonly property color controlBorderColor: enabled
        ? Qt.rgba(systemPalette.windowText.r, systemPalette.windowText.g, systemPalette.windowText.b, hovered ? 0.65 : 0.42)
        : Qt.rgba(systemPalette.windowText.r, systemPalette.windowText.g, systemPalette.windowText.b, 0.22)
    readonly property color controlBaseColor: enabled
        ? systemPalette.window
        : Qt.rgba(systemPalette.window.r, systemPalette.window.g, systemPalette.window.b, 0.55)

    indicator: Rectangle {
        id: indicatorBox
        implicitWidth: Math.max(14, Math.round(Kirigami.Units.gridUnit * 0.82))
        implicitHeight: implicitWidth
        width: implicitWidth
        height: implicitHeight
        x: root.mirrored ? root.width - width - root.rightPadding : root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        radius: Math.max(2, Math.round(width / 5))
        color: root.checkState === Qt.Unchecked ? root.controlBaseColor : systemPalette.highlight
        border.width: root.activeFocus || root.hovered ? 2 : 1
        border.color: root.checkState === Qt.Unchecked ? root.controlBorderColor : systemPalette.highlight
        opacity: root.enabled ? 1 : 0.65

        Text {
            anchors.centerIn: parent
            text: root.checkState === Qt.Checked ? "\u2713" : (root.checkState === Qt.PartiallyChecked ? "-" : "")
            color: systemPalette.highlightedText
            font.pixelSize: Math.round(parent.height * 0.72)
            font.bold: true
            visible: root.checkState !== Qt.Unchecked
        }
    }

    contentItem: QQC2.Label {
        text: root.text
        font: root.font
        color: root.controlTextColor
        opacity: root.enabled ? 1 : 0.7
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.mirrored ? 0 : indicatorBox.width + root.spacing
        rightPadding: root.mirrored ? indicatorBox.width + root.spacing : 0
        wrapMode: Text.WordWrap
    }

    onValueChanged: {
        if (partiallyCheckedEnabled) {
            checkedState = value;
        } else {
            checked = !!value;
        }
    }
}
