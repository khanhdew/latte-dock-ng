/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.Switch {
    id: root
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

    spacing: Kirigami.Units.smallSpacing

    readonly property color controlTextColor: enabled
        ? systemPalette.windowText
        : Qt.rgba(systemPalette.windowText.r, systemPalette.windowText.g, systemPalette.windowText.b, 0.45)
    readonly property color trackOffColor: Qt.rgba(systemPalette.windowText.r, systemPalette.windowText.g, systemPalette.windowText.b, enabled ? 0.18 : 0.10)
    readonly property color trackBorderColor: Qt.rgba(systemPalette.windowText.r, systemPalette.windowText.g, systemPalette.windowText.b, enabled ? 0.38 : 0.20)

    indicator: Rectangle {
        id: switchTrack
        implicitWidth: Math.max(36, Math.round(Kirigami.Units.gridUnit * 2.35))
        implicitHeight: Math.max(18, Math.round(Kirigami.Units.gridUnit * 1.15))
        width: implicitWidth
        height: implicitHeight
        x: root.mirrored ? root.width - width - root.rightPadding : root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        radius: height / 2
        color: root.checked ? systemPalette.highlight : root.trackOffColor
        border.width: root.activeFocus || root.hovered ? 2 : 1
        border.color: root.checked ? systemPalette.highlight : root.trackBorderColor
        opacity: root.enabled ? 1 : 0.65

        Rectangle {
            id: switchHandle
            width: switchTrack.height - 4
            height: width
            radius: width / 2
            x: root.checked ? switchTrack.width - width - 2 : 2
            y: 2
            color: root.checked ? systemPalette.highlightedText : systemPalette.window
            border.width: 1
            border.color: Qt.rgba(systemPalette.windowText.r, systemPalette.windowText.g, systemPalette.windowText.b, 0.22)

            Behavior on x {
                NumberAnimation {
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    contentItem: QQC2.Label {
        text: root.text
        font: root.font
        color: root.controlTextColor
        opacity: root.enabled ? 1 : 0.7
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.mirrored ? 0 : switchTrack.width + root.spacing
        rightPadding: root.mirrored ? switchTrack.width + root.spacing : 0
    }
}
