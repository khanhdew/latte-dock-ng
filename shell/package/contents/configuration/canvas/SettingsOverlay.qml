/*
    SPDX-FileCopyrightText: 2019 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Effects

import org.kde.latte.core as LatteCore

//import "../../code/ColorizerTools.js" as ColorizerTools

Item{
    id: settingsRoot
    required property var root
    required property var latteView
    required property var plasmoid
    required property var themeExtended
    required property var graphicsSystem
    readonly property var settingsOverlayReference: settingsRoot
    readonly property var hostRootReference: root
    readonly property var latteViewReference: latteView
    readonly property var plasmoidReference: plasmoid
    readonly property bool containsMouse: false /*headerSettings.containsMouse || ruler.containsMouse
                                          || tooltipMouseArea.containsMouse || editBackMouseArea.containsMouse*/
    readonly property int thickness: headerSettings.thickness + spacing * 2
    readonly property int spacing: 4

    property int textShadow: {
        if (textColorIsDark)  {
            return 1;
        } else {
            return 6;
        }
    }

    property string tooltip: ""

    readonly property real textColorBrightness: LatteCore.Tools.colorBrightness(textColor)
    readonly property bool textColorIsDark: textColorBrightness < 127.5

    readonly property color bestContrastedTextColor: {
        if (latteView && latteView.colorizer && latteView.colorizer.textColor !== undefined) {
            return latteView.colorizer.textColor;
        }

        if (themeExtended) {
            return latteView && latteView.colorizer && latteView.colorizer.currentBackgroundBrightness > 127.5 ?
                        themeExtended.lightTheme.textColor :
                        themeExtended.darkTheme.textColor;
        }

        return latteView && latteView.layout ? latteView.layout.textColor : "#D7E3FF";
    }

    readonly property color textColor: bestContrastedTextColor

    layer.enabled: graphicsSystem.isAccelerated
    layer.effect: MultiEffect {
        required property var settings
        shadowEnabled: true
        shadowColor: settings.root.appShadowColorSolid
        shadowBlur: Math.min(settings.textShadow / 64.0, 1.0)
        settings: settingsRoot
    }

    HeaderSettings{
        id: headerSettings
        root: settingsOverlayReference.hostRootReference
        latteView: settingsOverlayReference.latteViewReference
        plasmoid: settingsOverlayReference.plasmoidReference
        settingsRoot: settingsOverlayReference
    }
}
