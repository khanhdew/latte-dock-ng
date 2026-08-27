/*
    SPDX-FileCopyrightText: 2021 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.latte.core 0.2 as LatteCore
import org.kde.latte.abilities.definition 0.1 as AbilityDefinition

AbilityDefinition.Containment {
    id: apis

    property int appletIndex: -1
    property Item myView: null

    readonly property int effectiveItemsAlignment: !myView ? LatteCore.types.Center
                                                           : myView.alignment === LatteCore.types.Justify
                                                             ? normalizedItemsAlignment(myView.itemsAlignment)
                                                             : myView.alignment

    function normalizedItemsAlignment(alignment) {
        if (alignment === LatteCore.types.Center) {
            return alignment;
        }

        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return alignment === LatteCore.types.Top || alignment === LatteCore.types.Bottom ? alignment : LatteCore.types.Center;
        }

        return alignment === LatteCore.types.Left || alignment === LatteCore.types.Right ? alignment : LatteCore.types.Center;
    }

    alignment: {
        if (!myView) {
            return LatteCore.types.Center;
        }

        if (myView.alignment === LatteCore.types.Justify) {
            if (appletIndex>=0 && appletIndex<100) {
                return effectiveItemsAlignment;
            } else if (appletIndex>=100 && appletIndex<200) {
                return effectiveItemsAlignment;
            } else if (appletIndex>=200) {
                return effectiveItemsAlignment;
            }

            return effectiveItemsAlignment;
        }

        return myView.alignment;
    }

    readonly property Item publicApi: Item {
        readonly property alias isFirstAppletInContainment: apis.isFirstAppletInContainment
        readonly property alias isLastAppletInContainment: apis.isLastAppletInContainment

        readonly property alias alignment: apis.alignment
    }
}
