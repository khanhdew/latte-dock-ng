/*
    SPDX-FileCopyrightText: 2026 Ruizhi Zhong <ruizhi.zhong@outlook.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma Singleton

import QtQuick 2.15

/*!
  Shared visual-proportion constants used by Latte metrics, indicators,
  and layout calculations. Centralizing these avoids inconsistent
  magic-number drift across the QML layer.
 */
QtObject {
    // --- thickness margins ---
    readonly property real kThicknessMarginModernFloor: 0.19
    readonly property real kThicknessMarginTraditionalFloor: 0.14
    readonly property real kLengthMarginModernFloor: 0.04

    // --- medium / zoom factors ---
    readonly property real kMediumZoomFactor: 0.65

    // --- length padding defaults ---
    readonly property real kDefaultLengthPadding: 0.06
    readonly property real kDefaultIndicatorLengthPadding: 0.08

    // --- spacer ---
    readonly property real kSpacerMaxSizeIconRatio: 0.55

    // --- background ---
    readonly property real kModernThicknessIconRatio: 0.18
    readonly property int   kModernThicknessMinPixels: 6
    readonly property int   kCornerRadiusMinPixels: 10
    readonly property int   kCornerRadiusMaxPixels: 30
    readonly property real kCornerRadiusThicknessRatio: 0.36

    // --- screen edge ---
    readonly property int   kScreenEdgeMarginMinPixels: 4
    readonly property real kScreenEdgeMarginIconRatio: 0.08
    readonly property int   kPortionIconSizeMin: 16

    // --- shadow & outline ---
    readonly property int   kModernBackgroundShadowMinPixels: 6
    readonly property real kShadowAlphaAddition: 0.336
    readonly property real kShadowOpacityDefault: 0.35
    readonly property real kOutlineOpacityDefault: 0.55

    // --- animation ---
    readonly property real kAnimationDurationMediumFactor: 0.8
    readonly property real kAnimationDurationLargeFactor: 2.8

    // --- colorizer ---
    readonly property real kDarkerFactor: 1.5
    readonly property real kLighterFactor: 2.2
    readonly property real kSolidBackgroundOpacityThreshold: 0.70
    readonly property real kTranslucentBackgroundOpacityThreshold: 0.35

    // --- mask ---
    readonly property int kMaskThicknessCompositing: 2
    readonly property int kMaskThicknessNoCompositing: 1

    // --- drag ---
    readonly property real kSortDragCenterDeadZone: 0.18

    // --- badge ---
    readonly property real kBadgeSizeRatio: 0.4
    readonly property int   kBadgeMinHeight: 24

    // --- glow ---
    readonly property real kGlowMarginIconRatio: 0.25
    readonly property int   kGlowMarginMinPixels: 1

    // --- indicator style fallbacks ---
    readonly property real kIndicatorLengthPadding: 0.08
    readonly property real kIndicatorCornerMargin: 0.35
    readonly property real kIndicatorGlowOpacity: 0.55
    readonly property real kIndicatorBackgroundCornerMargin: 0.05

    // --- max thickness fallback ---
    readonly property int   kMaxThicknessForViewFallback: 384

    // --- edit ruler ---
    readonly property int   kMarginBetweenContentsAndEditRuler: 10

    // --- icon sizes array ---
    readonly property var kIconSizes: [16, 22, 32, 48, 64, 96, 128, 256]
}
