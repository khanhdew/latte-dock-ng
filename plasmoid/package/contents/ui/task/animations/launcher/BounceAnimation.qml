/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

SequentialAnimation{
    readonly property string bouncePropertyName: taskItem.isVertical ? "iconAnimatedOffsetX" : "iconAnimatedOffsetY"

    Component.onDestruction: {
        //! make sure to return on initial position even when the animation is destroyed in the middle
        if (taskItem.isVertical) {
            taskItem.iconAnimatedOffsetX = 0;
        } else {
            taskItem.iconAnimatedOffsetY = 0;
        }
    }

    // Rise phase: drive the launcher icon upward by animating its bounce
    // offset to the full icon size.  The zoom property is deliberately NOT
    // touched here — letting parabolic continue tracking the pointer so the
    // icon stays scaled to the correct size throughout the bounce.
    PropertyAnimation {
        target: taskItem
        property: bouncePropertyName
        to: taskItem.abilities.metrics.iconSize
        duration: 1.5 * launcherAnimation.speed
        easing.type: Easing.OutQuad
    }

    // Fall phase: bounce the icon back to its resting position.
    PropertyAnimation {
        target: taskItem
        property: bouncePropertyName
        to: 0
        duration: 5 * launcherAnimation.speed
        easing.type: Easing.OutBounce
    }

    onStopped: {
        //! make sure to return on initial position even when the animation is destroyed in the middle
        if (taskItem.isVertical) {
            taskItem.iconAnimatedOffsetX = 0;
        } else {
            taskItem.iconAnimatedOffsetY = 0;
        }
    }
}
