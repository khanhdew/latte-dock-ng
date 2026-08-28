/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaComponents.Label {
    readonly property var theme: Kirigami.Theme
    readonly property var units: Kirigami.Units

    Layout.alignment: Qt.AlignLeft
    Layout.topMargin: units.smallSpacing
    Layout.bottomMargin: units.smallSpacing
    color: theme.textColor
    font.weight: Font.DemiBold
    font.letterSpacing: 1.05
    font.pixelSize: 1.2 * units.gridUnit
}
