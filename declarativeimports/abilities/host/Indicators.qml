/*
    SPDX-FileCopyrightText: 2021 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.latte.abilities.definition as AbilityDefinition

AbilityDefinition.Indicators {
    id: apis

    readonly property Item publicApi: Item {
        readonly property alias isEnabled: apis.isEnabled

        readonly property alias padding: apis.padding

        readonly property alias type: apis.type

        readonly property alias configuration: apis.configuration
        // Preserve the public indicator API name from the definition layer.
        // qmllint disable property-override
        readonly property alias resources: apis.resources
        // qmllint enable property-override

        readonly property alias indicatorComponent: apis.indicatorComponent

        readonly property alias info: apis.info
    }
}
