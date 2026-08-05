/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0

import org.kde.latte.core 0.2 as LatteCore
import org.kde.latte.private.app 0.1 as LatteApp

import "./privates" as Ability

Ability.AnimationsPrivate {
    //! Public Properties
    active: plasmoid.configuration.animationsEnabled && LatteCore.WindowSystem.compositingActive

    duration.large: LatteCore.Environment.longDuration
    duration.proposed: speedFactor.current * 2.8 * duration.large
    duration.small: LatteCore.Environment.shortDuration

    speedFactor.normal: 1.0
    //! speedFactor multiplies animation durations, so x1/x2/x3 map to
    //! 1x/2x/3x durations. This matches the plasmoid's own "xN duration"
    //! semantics (plasmoid/main.qml) so the setting behaves identically in
    //! standalone and Latte Dock modes, and the differences are clearly
    //! perceptible (previously 0.75/1.0/1.15 were too subtle to notice).
    speedFactor.current: {
        if (!active || plasmoid.configuration.durationTime === 0) {
            return 0;
        }

        switch (plasmoid.configuration.durationTime) {
        case 1:
            return 1.0;      // x1: normal duration
        case 2:
            return 2.0;      // x2: twice the duration
        case 3:
            return 3.0;      // x3: three times the duration
        }

        return speedFactor.normal;
    }

    //! animations related to parabolic effect
    hoverPixelSensitivity: 1

    //! do not update during dragging/moving applets inConfigureAppletsMode
    updateIsBlocked: (root.dragOverlay && root.dragOverlay.pressed)
                     || layouter.appletsInParentChange
}
