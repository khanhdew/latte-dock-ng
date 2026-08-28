/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.kirigami as Kirigami

import "code/ColorizerTools.js" as ColorizerTools

Item{
    id: addItem
    readonly property var theme: Kirigami.Theme

    property real backgroundOpacity: 1

    Rectangle{
        width: Math.min(parent.width, parent.height)
        height: width
        anchors.centerIn: parent

        radius: 0.05 * Math.max(width,height)

        color: Qt.rgba(addItem.theme.backgroundColor.r, addItem.theme.backgroundColor.g, addItem.theme.backgroundColor.b, addItem.backgroundOpacity)
        border.width: 1
        border.color: addBackground.outlineColor

        property int crossSize: Math.min(0.4*parent.width, 0.4 * parent.height)

        id: addBackground
        readonly property color outlineColorBase: addItem.theme.backgroundColor
        readonly property real outlineColorBaseBrightness: ColorizerTools.colorBrightness(outlineColorBase)
        readonly property color outlineColor: {
            if (outlineColorBaseBrightness > 127.5) {
                return Qt.darker(outlineColorBase, 1.5);
            } else {
                return Qt.lighter(outlineColorBase, 2.2);
            }
        }

        Rectangle{width: parent.crossSize; height: 4; radius:2; anchors.centerIn: parent; color: addItem.theme.highlightColor}
        Rectangle{width: 4; height: parent.crossSize; radius:2; anchors.centerIn: parent; color: addItem.theme.highlightColor}
    }
}
