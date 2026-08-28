/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

GraphicIcon{
    readonly property int itemLength: 0.22*width

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: "transparent"

        Rectangle{
            required property var iconRoot
            anchors.top: parent.top
            anchors.left: parent.left
            width: iconRoot.itemLength
            height: parent.height
            radius: width/2
            color: iconRoot.iconColor
            iconRoot: parent.parent
        }

        Rectangle{
            required property var iconRoot
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: iconRoot.itemLength
            height: parent.height
            radius: width/2
            color: iconRoot.iconColor
            iconRoot: parent.parent
        }

        Rectangle{
            required property var iconRoot
            anchors.top: parent.top
            anchors.right: parent.right
            width: iconRoot.itemLength
            height: parent.height
            radius: width/2
            color: iconRoot.iconColor
            iconRoot: parent.parent
        }
    }
}
