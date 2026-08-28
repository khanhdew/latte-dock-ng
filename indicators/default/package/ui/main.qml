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
    extraMaskThickness: reversedEnabled && glowEnabled ? 1.7 * (factor * indicator.maxIconSize) : 0

    enabledForApplets: indicator && indicator.configuration ? indicator.configuration.enabledForApplets : true
    lengthPadding: modernDockStyle ? 0.05
                                   : (indicator && indicator.configuration ? indicator.configuration.lengthPadding : 0.08)
    backgroundCornerMargin: modernDockStyle ? 0.35
                                            : (indicator && indicator.configuration ? indicator.configuration.backgroundCornerMargin : 1.00)

    readonly property real factor: indicator.configuration.size
    readonly property int modernDockDotSize: Math.max(3, Math.round(indicator.currentIconSize * 0.055))
    readonly property int size: modernDockStyle ? modernDockDotSize : factor * indicator.currentIconSize
    readonly property int thickLocalMargin: indicator.configuration.thickMargin * indicator.currentIconSize

    readonly property int screenEdgeMargin: modernDockStyle ? indicator.screenEdgeMargin
                                                            : (plasmoid.location === PlasmaCore.Types.Floating || reversedEnabled ? 0 : indicator.screenEdgeMargin)

    property color textColorSafe: (indicator && indicator.palette && indicator.palette.textColor !== undefined)
                                 ? indicator.palette.textColor
                                 : "#ffffff"
    property real textColorBrightness: colorBrightness(textColorSafe)
    property color backgroundColorSafe: (indicator && indicator.palette && indicator.palette.backgroundColor !== undefined)
                                       ? indicator.palette.backgroundColor
                                       : (textColorBrightness > 127.5 ? "#202020" : "#e8e8e8")

    property real backgroundColorBrightness: colorBrightness(backgroundColorSafe)
    property color isActiveColor: oppositeToBackgroundColor(textColorSafe)
    property color minimizedColor: {
        if (minimizedTaskColoredDifferently) {
            return tonedDownOppositeColor(isActiveColor);
        }

        return isActiveColor;
    }

    property color notActiveColor: indicator.isMinimized ? minimizedColor : isActiveColor
    property color stateDotColor: indicator.isActive || (indicator.isGroup && indicator.hasShown) ? isActiveColor : notActiveColor

    //! Common Options
    readonly property bool reversedEnabled: indicator.configuration.reversed

    //! Configuration Options
    readonly property bool extraDotOnActive: indicator.configuration.extraDotOnActive
    readonly property bool minimizedTaskColoredDifferently: indicator.configuration.minimizedTaskColoredDifferently
    readonly property int activeStyle: indicator.configuration.activeStyle
    readonly property bool modernDockStyle: {
        var styleValue = plasmoid.configuration.dockStyle;
        var configModern = styleValue === 1 || styleValue === "1" || styleValue === "Modern";
        var apiModern = indicator && indicator.isModernDockStyle === true;

        return configModern || apiModern;
    }
    readonly property int effectiveActiveStyle: modernDockStyle ? 1 /*Dot*/ : activeStyle
    readonly property real modernDockIconEdgeGap: modernDockStyle
                                                 ? Math.max(0, indicator.tailThickness !== undefined ? indicator.tailThickness : thickLocalMargin)
                                                 : 0
    readonly property real modernDockIndicatorMargin: modernDockStyle
                                                       ? screenEdgeMargin + Math.max(0, Math.round((modernDockIconEdgeGap - size) / 2))
                                                       : screenEdgeMargin
    readonly property real thicknessMargin: modernDockStyle
                                            ? modernDockIndicatorMargin
                                            : screenEdgeMargin + thickLocalMargin + (glowEnabled ? 1 : 0)

    //!glow options
    readonly property bool glowEnabled: indicator.configuration.glowEnabled
    readonly property bool glow3D: indicator.configuration.glow3D
    readonly property int glowApplyTo: indicator.configuration.glowApplyTo
    readonly property real glowOpacity: indicator.configuration.glowOpacity
    readonly property int glowMargins: glowEnabled ? Math.max(1, Math.round(indicator.currentIconSize * 0.25)) : 0

    /*Rectangle{
        anchors.fill: parent
        border.width: 1
        border.color: "blue"
        color: "transparent"
    }*/

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

    Grid{
        id: grid
        columns: plasmoid.formFactor === PlasmaCore.Types.Vertical ? 1 : 0
        rows: plasmoid.formFactor !== PlasmaCore.Types.Vertical ? 1 : 0
        columnSpacing: 0
        rowSpacing: 0

        LatteComponents.GlowPoint{
            id:firstPoint
            width: stateWidth
            height: stateHeight
            opacity: {
                if (root.indicator.isEmptySpace) {
                    return 0;
                }

                if (root.indicator.isTask) {
                    const isPureLauncher = root.indicator.isLauncher && !root.indicator.isWindow;
                    return isPureLauncher || (root.indicator.inRemoving && !isAnimating) ? 0 : 1
                }

                if (root.indicator.isApplet) {
                    return (root.indicator.isActive || isAnimating) ? 1 : 0
                }

                return 0;
            }

            basicColor: root.stateDotColor

            size: root.size
            glow3D: glow3D
            animation: Math.max(1.65*3*LatteCore.Environment.longDuration,root.indicator.durationTime*3*LatteCore.Environment.longDuration)
            location: plasmoid.location
            glowOpacity: root.modernDockStyle ? 1 : root.glowOpacity
            contrastColor: root.indicator.shadowColor
            attentionColor: root.indicator.palette.negativeTextColor

            roundCorners: true
            showAttention: root.indicator.inAttention
            showGlow: {
                if (root.modernDockStyle) {
                    return false;
                }

                if (root.glowEnabled && (root.glowApplyTo === 2 /*All*/ || showAttention ))
                    return true;
                else if (root.glowEnabled && root.glowApplyTo === 1 /*OnActive*/ && root.indicator.hasActive)
                    return true;
                else
                    return false;
            }
            showBorder: !root.modernDockStyle && glow3D

            property int stateWidth: {
                if (!vertical && isActive && root.effectiveActiveStyle === 0 /*Line*/) {
                    return (root.indicator.isGroup ? root.width - secondPoint.width : root.width - spacer.width) - root.glowMargins;
                }

                return root.size;
            }

            property int stateHeight: {
                if (vertical && isActive && root.effectiveActiveStyle === 0 /*Line*/) {
                    return (root.indicator.isGroup ? root.height - secondPoint.height : root.height - spacer.height) - root.glowMargins;
                }

                return root.size;
            }

            property int animationTime: root.indicator.durationTime* (0.75*LatteCore.Environment.longDuration)

            property bool isActive: root.indicator.hasActive || root.indicator.isActive

            property bool vertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

            property real scaleFactor: root.indicator.scaleFactor

            readonly property bool isAnimating: inGrowAnimation || inShrinkAnimation
            property bool inGrowAnimation: false
            property bool inShrinkAnimation: false

            property bool isBindingBlocked: isAnimating

            readonly property bool isActiveStateForAnimation: root.indicator.isActive && root.effectiveActiveStyle === 0 /*Line*/

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

        Item{
            id:spacer
            width: secondPoint.visible ? 0.5*root.size : 0
            height: secondPoint.visible ? 0.5*root.size : 0
        }

        LatteComponents.GlowPoint{
            id:secondPoint
            width: visible ? root.size : 0
            height: width

            size: root.size
            glow3D: glow3D
            animation: Math.max(1.65*3*LatteCore.Environment.longDuration,root.indicator.durationTime*3*LatteCore.Environment.longDuration)
            location: plasmoid.location
            glowOpacity: root.glowOpacity
            contrastColor: root.indicator.shadowColor
            showBorder: glow3D

            basicColor: state2Color
            roundCorners: true
            showGlow: root.glowEnabled  && root.glowApplyTo === 2 /*All*/
            visible: !root.modernDockStyle
                     && (root.indicator.isGroup && ((root.extraDotOnActive && root.effectiveActiveStyle === 0) /*Line*/
                                               || root.effectiveActiveStyle === 1 /*Dot*/
                                               || !root.indicator.hasActive) ) ? true: false

            //when there is no active window
            property color state1Color: root.indicator.hasShown ? root.isActiveColor : root.minimizedColor
            //when there is active window
            property color state2Color: root.indicator.hasMinimized ? root.minimizedColor : root.isActiveColor
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
