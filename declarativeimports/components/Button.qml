/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong88@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami 2.0 as Kirigami

QQC2.Button {
    id: control
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    property string tooltip: ""

    readonly property color safeTextColor: (Kirigami.Theme.textColor !== undefined) ? Kirigami.Theme.textColor : Kirigami.Theme.viewTextColor
    readonly property color safeBackgroundColor: (Kirigami.Theme.backgroundColor !== undefined) ? Kirigami.Theme.backgroundColor : Kirigami.Theme.viewBackgroundColor

    palette.window: safeBackgroundColor
    palette.windowText: safeTextColor
    palette.button: safeBackgroundColor
    palette.buttonText: safeTextColor

    hoverEnabled: true
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    QQC2.ToolTip.visible: hovered && tooltip !== ""
    QQC2.ToolTip.text: tooltip
}
