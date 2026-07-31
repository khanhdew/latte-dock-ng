/*
    SPDX-FileCopyrightText: 2021 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15

Item {
    id: level
    signal mousePressed(int x, int y, int button);
    signal mouseReleased(int x, int y, int button);
    signal taskLauncherActivated();
    signal taskGroupedWindowAdded();
    signal taskGroupedWindowRemoved();

    property bool isBackground: true
    property bool isForeground: false

    property bool isDrawn: false

    readonly property Item requested: Item{
        property int iconOffsetX: 0
        property int iconOffsetY: 0
        property int iconTransformOrigin: Item.Center
        property real iconOpacity: 1.0
        property real iconRotation: 0
        property real iconScale: 1.0
        property bool isTaskLauncherAnimationRunning: false
    }

    property Item indicator: null

    // Guard against mutual re-entrant signal handling — if both properties
    // were ever set to the same value simultaneously, the two handlers would
    // flip-flop indefinitely.  The reentry guard limits each handler to one
    // pass.
    property bool _updatingBackground: false
    property bool _updatingForeground: false

    onIsBackgroundChanged: {
        if (_updatingBackground) return;
        _updatingForeground = true;
        isForeground = !isBackground;
        _updatingForeground = false;
    }

    onIsForegroundChanged: {
        if (_updatingForeground) return;
        _updatingBackground = true;
        isBackground = !isForeground;
        _updatingBackground = false;
    }
}
