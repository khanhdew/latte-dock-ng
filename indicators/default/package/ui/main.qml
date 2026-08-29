/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore

import org.kde.latte.core as LatteCore
import org.kde.latte.components as LatteComponents

LatteComponents.IndicatorItem{
    id: root
    extraMaskThickness: root.reversedEnabled && root.glowEnabled ? 1.7 * (factor * root.indicator.maxIconSize) : 0

    enabledForApplets: root.indicator && root.indicator.configuration ? root.indicator.configuration.enabledForApplets : true
    lengthPadding: modernDockStyle ? 0.05
                                   : (root.indicator && root.indicator.configuration ? root.indicator.configuration.lengthPadding : 0.08)
    backgroundCornerMargin: modernDockStyle ? 0.35
                                            : (root.indicator && root.indicator.configuration ? root.indicator.configuration.backgroundCornerMargin : 1.00)

    readonly property real factor: root.indicator.configuration.size
    readonly property int modernDockDotSize: Math.max(3, Math.round(root.indicator.currentIconSize * 0.055))
    readonly property int size: modernDockStyle ? modernDockDotSize : factor * root.indicator.currentIconSize
    readonly property int thickLocalMargin: root.indicator.configuration.thickMargin * root.indicator.currentIconSize

    readonly property int screenEdgeMargin: modernDockStyle ? root.indicator.screenEdgeMargin
                                                            : (plasmoid.location === PlasmaCore.Types.Floating || root.reversedEnabled ? 0 : root.indicator.screenEdgeMargin)

    property color textColorSafe: (root.indicator && root.indicator.palette && root.indicator.palette.textColor !== undefined)
                                 ? root.indicator.palette.textColor
                                 : "#ffffff"
    property real textColorBrightness: colorBrightness(textColorSafe)
    property color backgroundColorSafe: (root.indicator && root.indicator.palette && root.indicator.palette.backgroundColor !== undefined)
                                       ? root.indicator.palette.backgroundColor
                                       : (textColorBrightness > 127.5 ? "#202020" : "#e8e8e8")

    property real backgroundColorBrightness: colorBrightness(backgroundColorSafe)
    property color isActiveColor: oppositeToBackgroundColor(textColorSafe)
    property color minimizedColor: {
        if (minimizedTaskColoredDifferently) {
            return tonedDownOppositeColor(isActiveColor);
        }

        return isActiveColor;
    }

    property color notActiveColor: root.indicator.isMinimized ? minimizedColor : isActiveColor
    property color stateDotColor: root.indicator.isActive || (root.indicator.isGroup && root.indicator.hasShown) ? isActiveColor : notActiveColor

    //! Common Options
    readonly property bool reversedEnabled: root.indicator.configuration.reversed

    //! Configuration Options
    readonly property bool extraDotOnActive: root.indicator.configuration.extraDotOnActive
    readonly property bool minimizedTaskColoredDifferently: root.indicator.configuration.minimizedTaskColoredDifferently
    readonly property int activeStyle: root.indicator.configuration.activeStyle
    readonly property bool modernDockStyle: {
        var styleValue = plasmoid.configuration.dockStyle;
        var configModern = styleValue === 1 || styleValue === "1" || styleValue === "Modern";
        var apiModern = root.indicator && root.indicator.isModernDockStyle === true;

        return configModern || apiModern;
    }
    readonly property int effectiveActiveStyle: modernDockStyle ? 1 /*Dot*/ : activeStyle
    readonly property real modernDockIconEdgeGap: modernDockStyle
                                                 ? Math.max(0, root.indicator.tailThickness !== undefined ? root.indicator.tailThickness : thickLocalMargin)
                                                 : 0
    readonly property real modernDockIndicatorMargin: modernDockStyle
                                                       ? screenEdgeMargin + Math.max(0, Math.round((modernDockIconEdgeGap - size) / 2))
                                                       : screenEdgeMargin
    readonly property real thicknessMargin: modernDockStyle
                                            ? modernDockIndicatorMargin
                                            : screenEdgeMargin + thickLocalMargin + (root.glowEnabled ? 1 : 0)

    //!glow options
    readonly property bool glowEnabled: root.indicator.configuration.glowEnabled
    readonly property bool glow3D: root.indicator.configuration.glow3D
    readonly property int glowApplyTo: root.indicator.configuration.glowApplyTo
    readonly property real glowOpacity: root.indicator.configuration.glowOpacity
    readonly property int glowMargins: root.glowEnabled ? Math.max(1, Math.round(root.indicator.currentIconSize * 0.25)) : 0

    function colorBrightness(color) {
        return colorBrightnessFromRGB(color.r * 255, color.g * 255, color.b * 255);
    }

    function hasOppositeBrightness(foregroundColor, baseBackgroundColor) {
        var foregroundBrightness = colorBrightness(foregroundColor);
        var baseBrightness = colorBrightness(baseBackgroundColor);

        return (baseBrightness > 127.5 && foregroundBrightness < 127.5)
                || (baseBrightness <= 127.5 && foregroundBrightness >= 127.5);
    }

    function oppositeToBackgroundColor(candidateColor) {
        if (hasOppositeBrightness(candidateColor, backgroundColorSafe)) {
            return candidateColor;
        }

        return backgroundColorBrightness > 127.5 ? Qt.darker(candidateColor, 1.8) : Qt.lighter(candidateColor, 1.8);
    }

    function tonedDownOppositeColor(baseColor) {
        var tonedColor = backgroundColorBrightness > 127.5 ? Qt.lighter(baseColor, 1.28) : Qt.darker(baseColor, 1.28);
        return oppositeToBackgroundColor(tonedColor);
    }

    // formula for brightness according to:
    // https://www.w3.org/TR/AERT/#color-contrast
    function colorBrightnessFromRGB(r, g, b) {
        return (r * 299 + g * 587 + b * 114) / 1000
    }

    function isWindowMinimized(winIndex) {
        if (!root.indicator) {
            return false;
        }
        if (root.indicator.windowsMinimizedList && root.indicator.windowsMinimizedList.length > winIndex) {
            return root.indicator.windowsMinimizedList[winIndex] === true;
        }
        if (!root.indicator.isGroup) {
            return root.indicator.isMinimized;
        }
        return false;
    }

    readonly property int dotSpacing: Math.max(2, Math.round(root.size * 0.4))
    readonly property int extraDotsCount: {
        if (!root.indicator || !root.indicator.isGroup) {
            return 0;
        }
        if (root.effectiveActiveStyle === 0 /*Line*/) {
            return (!root.indicator.hasActive || root.extraDotOnActive) ? 1 : 0;
        }
        var count = root.indicator.windowsCount > 0 ? root.indicator.windowsCount : 2;
        return Math.max(0, Math.min(5, count) - 1);
    }

    Grid{
        id: grid
        columns: plasmoid.formFactor === PlasmaCore.Types.Vertical ? 1 : 0
        rows: plasmoid.formFactor !== PlasmaCore.Types.Vertical ? 1 : 0
        columnSpacing: plasmoid.formFactor === PlasmaCore.Types.Vertical ? 0 : (extraDotsCount > 0 ? root.dotSpacing : 0)
        rowSpacing: plasmoid.formFactor === PlasmaCore.Types.Vertical ? (extraDotsCount > 0 ? root.dotSpacing : 0) : 0

        LatteComponents.GlowPoint{
            id:firstPoint
            width: stateWidth
            height: stateHeight
            opacity: {
                if (!root.indicator || root.indicator.isEmptySpace) {
                    return 0;
                }

                if (root.indicator.isTask) {
                    const isPureLauncher = root.indicator.isLauncher && !root.indicator.isWindow;
                    return isPureLauncher || (root.indicator.inRemoving && !isAnimating) ? 0 : 1;
                }

                if (root.indicator.isApplet) {
                    return (root.indicator.isActive || isAnimating) ? 1 : 0;
                }

                return 0;
            }

            basicColor: {
                if (root.effectiveActiveStyle === 0 /*Line*/ || !root.indicator || !root.indicator.isGroup) {
                    return root.stateDotColor;
                }

                // Dot style in a multi-window group:
                if (root.indicator.activeWindowIndex === 0) {
                    return root.isActiveColor;
                }

                if (root.isWindowMinimized(0) && root.minimizedTaskColoredDifferently) {
                    return root.minimizedColor;
                }

                return root.indicator.hasActive ? root.notActiveColor : root.stateDotColor;
            }

            size: root.size
            glow3D: root.glow3D
            animation: Math.max(1.65*3*LatteCore.Environment.longDuration, root.indicator ? root.indicator.durationTime*3*LatteCore.Environment.longDuration : 0)
            location: plasmoid.location
            glowOpacity: root.modernDockStyle ? 1 : root.glowOpacity
            contrastColor: root.indicator ? root.indicator.shadowColor : "black"
            attentionColor: root.indicator && root.indicator.palette ? root.indicator.palette.negativeTextColor : "red"

            roundCorners: true
            showAttention: root.indicator ? root.indicator.inAttention : false
            showGlow: {
                if (root.modernDockStyle) {
                    return false;
                }

                if (root.glowEnabled && (root.glowApplyTo === 2 /*All*/ || showAttention ))
                    return true;
                else if (root.glowEnabled && root.glowApplyTo === 1 /*OnActive*/ && root.indicator && root.indicator.hasActive) {
                    if (root.effectiveActiveStyle === 0 /*Line*/) {
                        return true;
                    }
                    return root.indicator.isGroup ? (root.indicator.activeWindowIndex === 0) : true;
                }
                else
                    return false;
            }
            showBorder: !root.modernDockStyle && root.glow3D

            property int stateWidth: {
                if (!vertical && isActive && root.effectiveActiveStyle === 0 /*Line*/) {
                    var extraSpace = root.extraDotsCount * (root.size + grid.columnSpacing);
                    return (root.width - extraSpace) - root.glowMargins;
                }

                return root.size;
            }

            property int stateHeight: {
                if (vertical && isActive && root.effectiveActiveStyle === 0 /*Line*/) {
                    var extraSpace = root.extraDotsCount * (root.size + grid.rowSpacing);
                    return (root.height - extraSpace) - root.glowMargins;
                }

                return root.size;
            }

            property int animationTime: root.indicator ? root.indicator.durationTime * (0.75*LatteCore.Environment.longDuration) : 250

            property bool isActive: root.indicator ? (root.indicator.hasActive || root.indicator.isActive) : false

            property bool vertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

            property real scaleFactor: root.indicator ? root.indicator.scaleFactor : 1

            readonly property bool isAnimating: inGrowAnimation || inShrinkAnimation
            property bool inGrowAnimation: false
            property bool inShrinkAnimation: false

            property bool isBindingBlocked: isAnimating

            readonly property bool isActiveStateForAnimation: root.indicator && root.indicator.isActive && root.effectiveActiveStyle === 0 /*Line*/

            onIsActiveStateForAnimationChanged: {
                if (root.effectiveActiveStyle === 0 /*Line*/) {
                    if (isActiveStateForAnimation) {
                        inGrowAnimation = true;
                        inShrinkAnimation = false;
                    } else {
                        inGrowAnimation = false;
                        inShrinkAnimation = true;
                    }
                } else {
                    inGrowAnimation = false;
                    inShrinkAnimation = false;
                }
            }

            onWidthChanged: {
                if (!vertical) {
                    if (inGrowAnimation && width >= stateWidth) {
                        inGrowAnimation = false;
                    } else if (inShrinkAnimation && width <= stateWidth) {
                        inShrinkAnimation = false;
                    }
                }
            }

            onHeightChanged: {
                if (vertical) {
                    if (inGrowAnimation && height >= stateHeight) {
                        inGrowAnimation = false;
                    } else if (inShrinkAnimation && height <= stateHeight) {
                        inShrinkAnimation = false;
                    }
                }
            }

            Behavior on width {
                enabled: (!firstPoint.vertical && (firstPoint.isAnimating || firstPoint.opacity === 0/*first showing requirement*/))
                NumberAnimation {
                    duration: firstPoint.animationTime
                    easing.type: Easing.Linear
                }
            }

            Behavior on height {
                enabled: (firstPoint.vertical && (firstPoint.isAnimating || firstPoint.opacity === 0/*first showing requirement*/))
                NumberAnimation {
                    duration: firstPoint.animationTime
                    easing.type: Easing.Linear
                }
            }
        }

        Repeater {
            model: root.extraDotsCount

            LatteComponents.GlowPoint {
                id: extraPoint
                required property int index

                width: root.size
                height: root.size

                size: root.size
                glow3D: root.glow3D
                animation: Math.max(1.65*3*LatteCore.Environment.longDuration, root.indicator ? root.indicator.durationTime*3*LatteCore.Environment.longDuration : 0)
                location: plasmoid.location
                glowOpacity: root.modernDockStyle ? 1 : root.glowOpacity
                contrastColor: root.indicator ? root.indicator.shadowColor : "black"
                attentionColor: root.indicator && root.indicator.palette ? root.indicator.palette.negativeTextColor : "red"
                showBorder: !root.modernDockStyle && root.glow3D

                roundCorners: true
                showGlow: {
                    if (root.modernDockStyle) {
                        return false;
                    }
                    if (root.glowEnabled && (root.glowApplyTo === 2 /*All*/ || showAttention)) {
                        return true;
                    } else if (root.glowEnabled && root.glowApplyTo === 1 /*OnActive*/ && root.indicator && root.indicator.hasActive) {
                        if (root.effectiveActiveStyle === 0 /*Line*/) {
                            return false;
                        }
                        return root.indicator.activeWindowIndex === (index + 1);
                    }
                    return false;
                }

                basicColor: {
                    if (!root.indicator) {
                        return root.stateDotColor;
                    }
                    if (root.effectiveActiveStyle === 0 /*Line*/) {
                        return root.indicator.hasMinimized ? root.minimizedColor : root.isActiveColor;
                    }

                    // For dot style:
                    var winIndex = index + 1;
                    if (root.indicator.activeWindowIndex === winIndex) {
                        return root.isActiveColor;
                    }

                    if (root.isWindowMinimized(winIndex) && root.minimizedTaskColoredDifferently) {
                        return root.minimizedColor;
                    }

                    return root.indicator.hasActive ? root.notActiveColor : root.isActiveColor;
                }
            }
        }
    }

    states: [
        State {
            name: "left"
            when: ((plasmoid.location === PlasmaCore.Types.LeftEdge && !root.reversedEnabled) ||
                   (plasmoid.location === PlasmaCore.Types.RightEdge && root.reversedEnabled))

            AnchorChanges {
                target: grid
                anchors{ verticalCenter:parent.verticalCenter; horizontalCenter:undefined;
                    top:undefined; bottom:undefined; left:parent.left; right:undefined;}
            }
            PropertyChanges{
                grid.anchors.leftMargin: root.thicknessMargin;    grid.anchors.rightMargin: 0;     grid.anchors.topMargin:0;    grid.anchors.bottomMargin:0;
                grid.anchors.horizontalCenterOffset: 0; grid.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "bottom"
            when: (plasmoid.location === PlasmaCore.Types.Floating ||
                   (plasmoid.location === PlasmaCore.Types.BottomEdge && !root.reversedEnabled) ||
                   (plasmoid.location === PlasmaCore.Types.TopEdge && root.reversedEnabled))

            AnchorChanges {
                target: grid
                anchors{ verticalCenter:undefined; horizontalCenter:parent.horizontalCenter;
                    top:undefined; bottom:parent.bottom; left:undefined; right:undefined;}
            }
            PropertyChanges{
                grid.anchors.leftMargin: 0;    grid.anchors.rightMargin: 0;     grid.anchors.topMargin:0;    grid.anchors.bottomMargin: root.thicknessMargin;
                grid.anchors.horizontalCenterOffset: 0; grid.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "top"
            when: ((plasmoid.location === PlasmaCore.Types.TopEdge && !root.reversedEnabled) ||
                   (plasmoid.location === PlasmaCore.Types.BottomEdge && root.reversedEnabled))

            AnchorChanges {
                target: grid
                anchors{ verticalCenter:undefined; horizontalCenter:parent.horizontalCenter;
                    top:parent.top; bottom:undefined; left:undefined; right:undefined;}
            }
            PropertyChanges{
                grid.anchors.leftMargin: 0;    grid.anchors.rightMargin: 0;     grid.anchors.topMargin: root.thicknessMargin;    grid.anchors.bottomMargin:0;
                grid.anchors.horizontalCenterOffset: 0; grid.anchors.verticalCenterOffset: 0;
            }
        },
        State {
            name: "right"
            when: ((plasmoid.location === PlasmaCore.Types.RightEdge && !root.reversedEnabled) ||
                   (plasmoid.location === PlasmaCore.Types.LeftEdge && root.reversedEnabled))

            AnchorChanges {
                target: grid
                anchors{ verticalCenter:parent.verticalCenter; horizontalCenter:undefined;
                    top:undefined; bottom:undefined; left:undefined; right:parent.right;}
            }
            PropertyChanges{
                grid.anchors.leftMargin: 0;    grid.anchors.rightMargin: root.thicknessMargin;     grid.anchors.topMargin:0;    grid.anchors.bottomMargin:0;
                grid.anchors.horizontalCenterOffset: 0; grid.anchors.verticalCenterOffset: 0;
            }
        }
    ]
}// number of windows indicator
