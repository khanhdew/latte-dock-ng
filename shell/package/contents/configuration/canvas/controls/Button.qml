/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item{
    id: button
    required property var latteView
    required property var settingsRoot
    readonly property var units: Kirigami.Units
    width: visibleButton.width
    height: visibleButton.height

    signal pressedChanged(bool pressed);

    property bool checked: false

    property bool iconPositionReversed: false
    property string text: "Default Text"
    property string tooltip: ""

    readonly property bool containsMouse: tooltipBtn.hovered
    // Define the control's implicit size from its actual visible button.
    // qmllint disable property-override
    readonly property int implicitHeight: visibleButton.height
    // qmllint enable property-override

    readonly property color appliedTextColor: checked ? checkedTextColor : textColor
    readonly property color appliedBackgroundColor: checked ? checkedBackgroundColor : backgroundColor
    readonly property color appliedBorderColor: checked ? checkedBorderColor : borderColor

    readonly property bool _hasColorizer: !!(latteView && latteView.colorizer)
    readonly property color _fallbackText: settingsRoot && settingsRoot.textColor !== undefined
                                            ? settingsRoot.textColor : "#D7E3FF"
    readonly property color _fallbackBg: "#2d2d2d"

    readonly property color textColor: containsMouse && _hasColorizer ? latteView.colorizer.buttonTextColor : _fallbackText
    readonly property color backgroundColor: containsMouse ? hoveredBackground :  normalBackground
    readonly property color borderColor: containsMouse ? hoveredBorder : normalBorder

    readonly property color checkedTextColor: _hasColorizer ? latteView.colorizer.buttonTextColor : _fallbackText
    readonly property color checkedBackgroundColor: _hasColorizer ? latteView.colorizer.buttonFocusColor : _fallbackBg
    readonly property color checkedBorderColor: hoveredBorder

    readonly property color normalBackground: _hasColorizer ? Qt.rgba(latteView.colorizer.buttonHoverColor.r,
                                                                       latteView.colorizer.buttonHoverColor.g,
                                                                       latteView.colorizer.buttonHoverColor.b,
                                                                       0.04) : _fallbackBg

    readonly property color hoveredBackground: _hasColorizer ? Qt.rgba(latteView.colorizer.buttonHoverColor.r,
                                                                        latteView.colorizer.buttonHoverColor.g,
                                                                        latteView.colorizer.buttonHoverColor.b,
                                                                        0.7) : _fallbackBg

    readonly property color normalBorder: Qt.rgba(_fallbackText.r,
                                                  _fallbackText.g,
                                                  _fallbackText.b,
                                                  0.7)

    readonly property color hoveredBorder: "#222222"

    property Component icon

    Item{
        id: visibleButtonRoot
        width: visibleButton.width
        height: visibleButton.height

        Rectangle {
            id: visibleButton
            width: buttonRow.width + 4 * margin
            height: buttonRow.height + 2 * margin
            radius: 2
            color: button.appliedBackgroundColor
            border.width: 1
            border.color: button.appliedBorderColor

            readonly property int margin: button.units.smallSpacing

            RowLayout{
                id: buttonRow
                anchors.centerIn: parent
                spacing: button.units.smallSpacing
                layoutDirection: button.iconPositionReversed ? Qt.RightToLeft : Qt.LeftToRight

                Loader {
                    Layout.preferredWidth: textLbl.implicitHeight
                    Layout.preferredHeight: textLbl.implicitHeight
                    active: button.icon
                    sourceComponent: button.icon
                    visible: active

                    readonly property color iconColor: button.appliedTextColor
                }

                PlasmaComponents.Label{
                    id: textLbl
                    text: button.text
                    color: button.appliedTextColor
                }
            }
        }
    }

    PlasmaComponents.Button {
        id: tooltipBtn
        anchors.fill: visibleButtonRoot
        opacity: 0
        Kirigami.Theme.inherit: true
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        palette.buttonText: button.appliedTextColor
        hoverEnabled: true

        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        QQC2.ToolTip.visible: hovered && button.tooltip !== ""
        QQC2.ToolTip.text: button.tooltip

        onPressedChanged: button.pressedChanged(pressed)
    }
}
