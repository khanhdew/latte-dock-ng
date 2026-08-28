/*
    SPDX-FileCopyrightText: 2020 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import org.kde.latte.private.app as LatteApp
import org.kde.latte.core as LatteCore
import org.kde.latte.private.containment as LatteContainment

import "canvas" as CanvasComponent

Loader {
    id: configurationLoader

    // Capture context properties on the Loader before creating the inline
    // component. Inline component contexts do not reliably inherit dynamic
    // context properties during their initial binding evaluation.
    readonly property var configurationPlasmoid: plasmoid
    readonly property var configurationLatteView: latteView
    readonly property var configurationThemeExtended: themeExtended

    active: configurationPlasmoid && configurationPlasmoid.configuration && configurationLatteView

    sourceComponent: Item{
        id: root
        property var latteView: configurationLoader.configurationLatteView
        property var plasmoid: configurationLoader.configurationPlasmoid
        property var themeExtended: configurationLoader.configurationThemeExtended
        readonly property var canvasRootReference: root
        readonly property var latteViewReference: latteView
        readonly property var plasmoidReference: plasmoid
        readonly property var themeExtendedReference: themeExtended
        readonly property var graphicsSystemReference: graphicsSystem
        readonly property var theme: Kirigami.Theme
        readonly property var units: Kirigami.Units
        readonly property bool isVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical
        readonly property bool isHorizontal: !isVertical

        property int animationSpeed: LatteCore.WindowSystem.compositingActive ? 500 : 0
        property int panelAlignment: plasmoid.configuration.alignment

        property real offset: {
            if (root.isHorizontal) {
                return width * (plasmoid.configuration.offset/100);
            } else {
                return height * (plasmoid.configuration.offset/100)
            }
        }

        property string appChosenShadowColor: {
            if (plasmoid.configuration.shadowColorType === LatteContainment.types.ThemeColorShadow) {
                var strC = String(theme.textColor);
                return strC.indexOf("#") === 0 ? strC.substr(1) : strC;
            } else if (plasmoid.configuration.shadowColorType === LatteContainment.types.UserColorShadow) {
                return plasmoid.configuration.shadowColor;
            }

            // default shadow color
            return "080808";
        }

        property string appShadowColorSolid: "#" + appChosenShadowColor

        //// BEGIN OF Behaviors
        Behavior on offset {
            NumberAnimation {
                id: offsetAnimation
                duration: animationSpeed
                easing.type: Easing.OutCubic
            }
        }
        //// END OF Behaviors

        Item {
            id: graphicsSystem
            readonly property bool isAccelerated: (GraphicsInfo.api !== GraphicsInfo.Software)
                                                  && (GraphicsInfo.api !== GraphicsInfo.Unknown)
        }

        LatteApp.ContextMenuLayer {
            id: contextMenuLayer
            anchors.fill: parent
            view: latteView
        }

        //! Settings Overlay
        CanvasComponent.SettingsOverlay {
            id: settingsOverlay
            root: canvasRootReference
            latteView: latteViewReference
            plasmoid: plasmoidReference
            themeExtended: themeExtendedReference
            graphicsSystem: graphicsSystemReference
            anchors.fill: parent
        }
    }
}
